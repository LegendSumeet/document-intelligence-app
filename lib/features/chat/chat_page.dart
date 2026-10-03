import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../../core/services/citation_formatting.dart';
import '../../core/widgets/feedback_panels.dart';
import '../../data/api/document_api.dart';
import '../../data/models/chat_models.dart';
import '../../data/models/citation_item.dart';
import '../../data/models/document_item.dart';
import 'widgets/assistant_processing.dart';
import 'widgets/chat_welcome.dart';
import 'widgets/message_bubble.dart';

/// Streaming, citation-backed chat over the session's documents.
class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.api,
    required this.session,
    required this.documents,
  });

  final DocumentApi api;
  final ChatSession session;
  final List<DocumentItem> documents;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final List<ChatMessage> _messages;
  String _draft = '';
  String _stage = 'Ready';
  bool _sending = false;
  String _reasoningEffort = 'medium';
  String? _sendError;
  String? _failedQuestion;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
    _messages = widget.session.history
        .map((turn) => ChatMessage(role: turn.role, text: turn.content))
        .toList();
  }

  void _onInputChanged() {
    final hasInput = _controller.text.trim().isNotEmpty;
    if (hasInput != _hasInput) setState(() => _hasInput = hasInput);
  }

  List<DocumentItem> get _selectedDocuments => widget.documents
      .where((item) => widget.session.documentIds.contains(item.id))
      .toList();

  Future<void> _changeDocuments() async {
    final selected = widget.session.documentIds.toSet();
    final updated = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Choose chat documents'),
          content: SizedBox(
            width: 460,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final document in widget.documents.where(
                  (item) => item.isReady,
                ))
                  CheckboxListTile(
                    value: selected.contains(document.id),
                    title: Text(document.name),
                    subtitle: Text('${document.pageCount} pages'),
                    onChanged: (value) => setDialogState(() {
                      if (value == true) {
                        selected.add(document.id);
                      } else {
                        selected.remove(document.id);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () => Navigator.pop(context, selected),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (updated == null ||
        setEquals(updated, widget.session.documentIds.toSet())) {
      return;
    }
    try {
      final session = await widget.api.updateSessionDocuments(
        widget.session.id,
        updated.toList(),
      );
      if (!mounted) return;
      setState(() {
        widget.session.documentIds
          ..clear()
          ..addAll(session.documentIds);
        _messages.clear();
        _draft = '';
        _stage = 'Scope changed';
      });
    } catch (error) {
      if (mounted) setState(() => _stage = error.toString());
    }
  }

  Future<void> _send() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: question));
      _sending = true;
      _draft = '';
      _stage = chatProgressLabel(null);
      _sendError = null;
      _failedQuestion = null;
    });
    try {
      await for (final event in widget.api.streamMessage(
        widget.session.id,
        question,
        reasoningEffort: _reasoningEffort,
      )) {
        if (!mounted) return;
        if (event.type == 'answer_delta') {
          final delta = event.data['delta'] as String? ?? '';
          await _appendStreamDelta(delta);
          continue;
        }
        setState(() {
          if (event.type == 'status') {
            _stage = chatProgressLabel(event.data['stage'] as String?);
          } else if (event.type == 'validation') {
            _stage = chatProgressLabel('validation');
          } else if (event.type == 'complete') {
            final result = event.data['data'] as Map<String, dynamic>;
            final citations = (result['citations'] as List? ?? const [])
                .map(
                  (item) => CitationItem.fromJson(item as Map<String, dynamic>),
                )
                .toList();
            _messages.add(
              ChatMessage(
                role: 'assistant',
                text: answerWithCitationLinks(
                  result['answer'] as String,
                  citations,
                ),
                verified: result['verification_status'] == 'location_verified',
                citations: citations,
                conversational:
                    result['verification_status'] == 'unverified' &&
                    citations.isEmpty,
                selectedPages:
                    (result['selected_pages'] as Map<String, dynamic>? ??
                            const {})
                        .map(
                          (key, value) =>
                              MapEntry(key, (value as List).cast<int>()),
                        ),
                usage: result['usage'] as Map<String, dynamic>? ?? const {},
              ),
            );
            _draft = '';
          } else if (event.type == 'error') {
            _sendError = event.data['message'] as String? ?? 'Request failed';
            _failedQuestion = question;
          }
        });
        _scrollToEnd();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _sendError = error.toString();
          _failedQuestion = question;
        });
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _appendStreamDelta(String delta) async {
    if (delta.isEmpty) return;
    final units = RegExp(r'\S+\s*|\s+').allMatches(delta);
    for (final unit in units) {
      if (!mounted) return;
      setState(() => _draft += unit.group(0)!);
      _scrollToEnd();
      await Future<void>.delayed(const Duration(milliseconds: 28));
    }
  }

  void _retry() {
    final question = _failedQuestion;
    if (question == null || _sending) return;
    _controller.text = question;
    _send();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    widget.api.deleteSession(widget.session.id);
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final streamingAnswer = parseStreamingAnswer(_draft, _selectedDocuments);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome, color: colors.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Document chat',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedDocuments.length} source${_selectedDocuments.length == 1 ? '' : 's'} in context',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton.outlined(
            onPressed: _sending ? null : _changeDocuments,
            icon: const Icon(Icons.library_add_check_outlined),
            tooltip: 'Change documents',
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          if (_sendError != null)
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
                  child: ErrorPanel(
                    message: _sendError!,
                    actionLabel: 'Retry',
                    onAction: _retry,
                  ),
                ),
              ),
            ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                border: Border.symmetric(
                  horizontal: BorderSide(color: colors.outlineVariant),
                ),
              ),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
                children: [
                  if (_messages.isEmpty && _draft.isEmpty)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 760),
                        child: ChatWelcome(
                          documents: _selectedDocuments,
                          onPrompt: (prompt) {
                            _controller.text = prompt;
                            _send();
                          },
                        ),
                      ),
                    ),
                  for (final message in _messages)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: MessageBubble(message: message, api: widget.api),
                      ),
                    ),
                  if (_sending || _draft.isNotEmpty)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _draft.isEmpty
                              ? AssistantProcessing(
                                  key: const ValueKey('processing'),
                                  stage: _stage,
                                )
                              : MessageBubble(
                                  key: const ValueKey('streaming'),
                                  message: ChatMessage(
                                    role: 'assistant',
                                    text: streamingAnswer.markdown,
                                    citations: streamingAnswer.citations,
                                  ),
                                  api: widget.api,
                                  isDraft: true,
                                ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    border: Border.all(color: colors.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 6,
                        enabled: !_sending,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Ask anything about your documents',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.fromLTRB(18, 16, 18, 10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                        child: Row(
                          children: [
                            PopupMenuButton<String>(
                              enabled: !_sending,
                              initialValue: _reasoningEffort,
                              tooltip: 'Reasoning effort',
                              onSelected: (value) =>
                                  setState(() => _reasoningEffort = value),
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'low',
                                  child: Text('Low reasoning'),
                                ),
                                PopupMenuItem(
                                  value: 'medium',
                                  child: Text('Medium reasoning'),
                                ),
                                PopupMenuItem(
                                  value: 'high',
                                  child: Text('High reasoning'),
                                ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 7,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.tune, size: 17),
                                    const SizedBox(width: 7),
                                    Text(
                                      '${_reasoningEffort[0].toUpperCase()}${_reasoningEffort.substring(1)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium,
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.expand_more, size: 16),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: _hasInput && !_sending
                                    ? colors.primary
                                    : colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: _hasInput && !_sending
                                    ? _send
                                    : null,
                                tooltip: 'Send message',
                                icon: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _sending
                                      ? const SizedBox.square(
                                          key: ValueKey('sending'),
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.arrow_upward_rounded,
                                          key: const ValueKey('send'),
                                          color: _hasInput
                                              ? colors.onPrimary
                                              : colors.onSurfaceVariant,
                                        ),
                                ),
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
          ),
        ],
      ),
    );
  }
}
