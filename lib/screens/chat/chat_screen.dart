import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../../core/services/citation_formatting.dart';
import '../../data/api/document_api.dart';
import '../../data/chat_prompts.dart';
import '../../data/models/chat_models.dart' show ChatSession;
import '../../data/models/query_result.dart';
import '../../models/chat_message.dart';
import '../../models/document.dart';
import '../../theme/app_theme.dart';
import '../../widgets/askdocs_panda.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/chat_input.dart';
import '../../widgets/suggestion_chip.dart';
import '../../widgets/thinking_bubble.dart';

/// Screen 2 — Document chat.
///
/// Scoped to a single [document]. Answers come from the backend through a
/// chat session created for that document.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.api,
    required this.document,
    this.availableDocuments = const [],
    this.initialQuestion,
    this.selectedDocuments = const [],
  });

  final DocumentApi api;
  final Document document;
  final List<Document> availableDocuments;
  final String? initialQuestion;
  final List<Document> selectedDocuments;

  static Route<void> route(
    DocumentApi api,
    Document document, {
    List<Document> availableDocuments = const [],
    String? initialQuestion,
    List<Document> selectedDocuments = const [],
  }) =>
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(
          api: api,
          document: document,
          availableDocuments: availableDocuments,
          initialQuestion: initialQuestion,
          selectedDocuments: selectedDocuments,
        ),
      );

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <ChatMessage>[];

  Future<ChatSession>? _session;
  late List<Document> _selectedDocuments;
  bool _canSend = false;
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    _selectedDocuments = widget.selectedDocuments.isEmpty
        ? [widget.document]
        : List<Document>.of(widget.selectedDocuments);
    _input.addListener(_onInputChanged);
    final initialQuestion = widget.initialQuestion;
    if (initialQuestion != null && initialQuestion.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send(initialQuestion);
      });
    }
  }

  @override
  void dispose() {
    _input.removeListener(_onInputChanged);
    _input.dispose();
    _scroll.dispose();
    _session
        ?.then(
          (session) => widget.api.deleteSession(session.id),
          onError: (_) {},
        )
        .catchError((_) {});
    super.dispose();
  }

  void _onInputChanged() {
    final canSend = _input.text.trim().isNotEmpty;
    if (canSend != _canSend) setState(() => _canSend = canSend);
  }

  Future<void> _send(String question) async {
    final text = question.trim();
    if (text.isEmpty || _thinking) return;

    _input.clear();
    final thinking = ChatMessage.thinking();
    setState(() {
      _messages.add(ChatMessage.user(text));
      _messages.add(thinking);
      _thinking = true;
    });
    _scrollToEnd();

    final answerId = 'a-${DateTime.now().microsecondsSinceEpoch}';
    var target = '';
    var shown = 0;
    var finished = false;
    List<Citation> citations = const [];
    String? failure;
    Timer? ticker;
    final typed = Completer<void>();

    void render({bool streaming = true}) {
      if (!mounted) return;
      final message = ChatMessage(
        id: answerId,
        author: ChatAuthor.askDocs,
        text: _hidePartialCite(
          target.substring(0, shown.clamp(0, target.length)),
        ),
        citations: citations,
        isStreaming: streaming,
      );
      setState(() {
        final at = _messages.indexWhere((m) => m.id == answerId);
        if (at >= 0) {
          _messages[at] = message;
        } else {
          _messages
            ..removeWhere((m) => m.isThinking)
            ..add(message);
        }
      });
      _followIfNearEnd();
    }

    // Reveals text at a steady pace, speeding up when the backlog grows so
    // the typing never lags far behind the network.
    ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) {
        ticker?.cancel();
        if (!typed.isCompleted) typed.complete();
        return;
      }
      final backlog = target.length - shown;
      if (backlog > 0) {
        shown =
            (shown +
                    (backlog > 240
                        ? backlog ~/ 12
                        : backlog > 60
                        ? 4
                        : 2))
                .clamp(0, target.length);
        render();
      } else if (finished) {
        ticker?.cancel();
        if (!typed.isCompleted) typed.complete();
      }
    });

    try {
      // A failed session creation is retried on the next question.
      final session = await (_session ??= widget.api.createSession(
        _selectedDocuments.map((document) => document.id).toList(),
      ));
      await for (final event in widget.api.streamMessage(session.id, text)) {
        if (!mounted) return;
        switch (event.type) {
          case 'status':
            final label = chatProgressLabel(event.data['stage']?.toString());
            if (target.isEmpty && label.isNotEmpty) {
              setState(() {
                final at = _messages.indexWhere((m) => m.isThinking);
                if (at >= 0) {
                  _messages[at] = ChatMessage(
                    id: thinking.id,
                    author: ChatAuthor.askDocs,
                    text: label,
                    isThinking: true,
                  );
                }
              });
            }
          case 'answer_delta':
            _raw += event.data['delta']?.toString() ?? '';
            target = _tidy(_raw);
          case 'complete':
            final data = event.data['data'];
            if (data is Map<String, dynamic>) {
              final result = QueryResult.fromJson(data);
              _raw = result.answer;
              target = _tidy(result.answer);
              citations = _citationsFor(result);
            }
          case 'error':
            throw Exception(event.data['message'] ?? 'Request failed');
        }
      }
    } catch (error) {
      _session = null;
      failure = error.toString().replaceFirst('Exception: ', '');
    }
    _raw = '';
    finished = true;
    if (failure != null && target.isEmpty) {
      ticker.cancel();
      if (!mounted) return;
      setState(() {
        _messages
          ..removeWhere((m) => m.isThinking)
          ..add(
            ChatMessage(
              id: answerId,
              author: ChatAuthor.askDocs,
              text: 'I could not get an answer: $failure',
              isError: true,
            ),
          );
        _thinking = false;
      });
      _scrollToEnd();
      return;
    }
    if (target.isEmpty) {
      ticker.cancel();
      typed.complete();
    }
    await typed.future;
    if (!mounted) return;
    shown = target.length;
    if (target.isEmpty) {
      setState(() {
        _messages.removeWhere((m) => m.isThinking);
        _thinking = false;
      });
      return;
    }
    render(streaming: false);
    setState(() => _thinking = false);
    _scrollToEnd();
  }

  String _raw = '';

  String _tidy(String raw) =>
      raw.replaceAll(RegExp(r'[ \t]+\n'), '\n').trimLeft();

  /// Hides a `<cite …` tag that has only partly been revealed.
  String _hidePartialCite(String text) =>
      text.replaceAll(RegExp(r'<(?:c(?:i(?:t(?:e[^>]*)?)?)?)?$'), '');

  void _followIfNearEnd() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.maxScrollExtent - position.pixels < 160) {
      _scroll.jumpTo(position.maxScrollExtent);
    }
  }

  List<Citation> _citationsFor(QueryResult result) => [
    for (final item in result.citations)
      Citation(
        label: 'Page ${item.page} · Lines ${item.startLine}–${item.endLine}',
        detail: item.text,
        page: item.page,
        lines: '${item.startLine}-${item.endLine}',
        documentId: item.docId,
      ),
  ];

  Future<void> _chooseDocuments() async {
    if (_thinking) return;

    final selected = _selectedDocuments.map((document) => document.id).toSet();
    final available = {
      for (final document in widget.availableDocuments)
        if (document.isAnalyzed || selected.contains(document.id))
          document.id: document,
      widget.document.id: widget.document,
    }.values.toList();

    final updated = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose documents',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                if (available.length == 1)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No other analyzed documents are available.'),
                  )
                else
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (final document in available)
                          CheckboxListTile(
                            value: selected.contains(document.id),
                            title: Text(document.displayName),
                            subtitle: Text(document.metaLabel),
                            onChanged: (value) => setSheetState(() {
                              if (value == true) {
                                selected.add(document.id);
                              } else if (selected.length > 1) {
                                selected.remove(document.id);
                              }
                            }),
                          ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: selected.isEmpty
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pop(Set<String>.of(selected)),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (updated == null ||
        setEquals(updated, _selectedDocuments.map((doc) => doc.id).toSet())) {
      return;
    }

    try {
      if (_session != null) {
        final session = await _session!;
        final result = await widget.api.updateSessionDocuments(
          session.id,
          updated.toList(),
        );
        session.documentIds
          ..clear()
          ..addAll(result.documentIds);
      }
      if (!mounted) return;
      setState(() {
        _selectedDocuments = [
          for (final document in available)
            if (updated.contains(document.id)) document,
        ];
        _messages.clear();
        _raw = '';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update chat documents: $error')),
        );
      }
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _showSource(Citation citation) {
    final document = widget.availableDocuments
        .where((item) => item.id == citation.documentId)
        .firstOrNull;
    showModalBottomSheet<void>(
      context: context,
      builder: (context) =>
          _SourceSheet(
            citation: citation,
            document: document ?? widget.document,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bottom padding tracks the keyboard so the composer is never covered.
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ask your document',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Answers with source references',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: const [SizedBox(width: 16)],
      ),
      body: Column(
        children: [
          _DocumentContextChip(
            documents: _selectedDocuments,
            onTap: _chooseDocuments,
            enabled: !_thinking,
          ),
          Expanded(
            child: _messages.isEmpty
                ? _EmptyState(document: widget.document, onPrompt: _send)
                : _MessageList(
                    messages: _messages,
                    controller: _scroll,
                    onCitationTap: _showSource,
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, viewInsets > 0 ? 8 : 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ChatInput(
                  controller: _input,
                  canSend: _canSend,
                  onSend: () => _send(_input.text),
                  enabled: !_thinking,
                  onAttach: _chooseDocuments,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The chip that tells the user which document is in scope.
class _DocumentContextChip extends StatelessWidget {
  const _DocumentContextChip({
    required this.documents,
    required this.onTap,
    required this.enabled,
  });

  final List<Document> documents;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.hairline)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Align(
            alignment: Alignment.centerLeft,
            child: ActionChip(
              onPressed: enabled ? onTap : null,
              avatar: Icon(
                Icons.description_rounded,
                size: 16,
                color: colors.primary,
              ),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: Text(
                      documents.length == 1
                          ? documents.single.displayName
                          : '${documents.length} documents selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.add_rounded, size: 16, color: colors.primary),
                ],
              ),
              side: BorderSide(color: colors.primary.withValues(alpha: 0.18)),
              backgroundColor: tokens.accentSoft,
              tooltip: 'Choose documents',
            ),
          ),
        ),
      ),
    );
  }
}

/// The scrollable transcript, with a "thinking" indicator at the tail.
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.controller,
    required this.onCitationTap,
  });

  final List<ChatMessage> messages;
  final ScrollController controller;
  final ValueChanged<Citation> onCitationTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final row = message.isThinking
            ? ThinkingBubble(
                label: message.text.isEmpty
                    ? 'AskDocs is thinking'
                    : message.text,
              )
            : message.isUser
            ? ChatBubble(message: message)
            : AIChatBubble(message: message, onCitationTap: onCitationTap);

        // Stagger each new message in rather than letting it pop.
        return TweenAnimationBuilder<double>(
          key: ValueKey(message.id),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 8),
              child: child,
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: row,
            ),
          ),
        );
      },
    );
  }
}

/// The welcome state: a small panda, a short invitation, and the prompts.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.document, required this.onPrompt});

  final Document document;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              const AskDocsPanda(size: 56),
              const SizedBox(height: 20),
              Text(
                kChatWelcomeTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                kChatWelcomeBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SUGGESTED',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final question in kSuggestedQuestions)
                    SuggestionChip(
                      label: question,
                      onTap: () => onPrompt(question),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The source details sheet opened by tapping a citation.
class _SourceSheet extends StatelessWidget {
  const _SourceSheet({required this.citation, required this.document});

  final Citation citation;
  final Document document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Source details', style: theme.textTheme.titleLarge),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tokens.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Location', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(
              citation.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text('Evidence from the document', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  citation.detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
