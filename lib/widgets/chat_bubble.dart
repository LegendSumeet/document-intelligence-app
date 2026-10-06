import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import 'askdocs_panda.dart';
import 'citation_chip.dart';

/// The user's own message: right-aligned, solid brand fill.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(5),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: SelectableText(
            message.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colors.onPrimary,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

/// An AskDocs answer presented in a card with source references and actions.
class AIChatBubble extends StatelessWidget {
  const AIChatBubble({
    super.key,
    required this.message,
    required this.onCitationTap,
  });

  final ChatMessage message;
  final ValueChanged<Citation> onCitationTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    final body = theme.textTheme.bodyLarge?.copyWith(height: 1.6);
    final markdown = _markdownWithCitationLinks(message);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: message.isError
                ? colors.error.withValues(alpha: 0.35)
                : tokens.hairline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AskDocsAvatar(size: 26),
                const SizedBox(width: 9),
                Text(
                  'AskDocs',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (message.isError)
              SelectableText(
                message.text,
                style: body?.copyWith(color: colors.error),
              )
            else ...[
              MarkdownBody(
                data: markdown,
                selectable: true,
                builders: {
                  'a': _MarkdownCitationBuilder(
                    citations: message.citations,
                    onCitationTap: onCitationTap,
                  ),
                },
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: body,
                  h1: theme.textTheme.headlineSmall,
                  h2: theme.textTheme.titleLarge,
                  h3: theme.textTheme.titleMedium,
                  h4: theme.textTheme.titleSmall,
                  listBullet: body,
                  tableHead: body?.copyWith(fontWeight: FontWeight.w700),
                  tableBody: body,
                  tableBorder: TableBorder.all(color: colors.outlineVariant),
                  tableCellsPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                ),
              ),
              if (message.isStreaming)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: _Caret(),
                ),
            ],
            if (!message.isStreaming &&
                !message.text.contains('<cite') &&
                message.citations.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'References',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final citation in message.citations)
                    CitationChip(citation: citation, onTap: onCitationTap),
                ],
              ),
            ],
            if (!message.isStreaming && !message.isError) ...[
              const SizedBox(height: 6),
              _CopyButton(text: message.text),
            ],
          ],
        ),
      ),
    );
  }

  String _markdownWithCitationLinks(ChatMessage message) {
    return message.text.replaceAllMapped(
      RegExp(r'<cite\s+doc="([^"]*)"\s+page="(\d+)"\s+lines="([^"]*)"\s*/>'),
      (match) {
        final page = int.tryParse(match.group(2)!);
        if (page == null) return '';
        final lines = match.group(3)!;
        var index = message.citations.indexWhere(
          (citation) => citation.page == page && citation.lines == lines,
        );
        if (index == -1) {
          index = message.citations.indexWhere(
            (citation) => citation.page == page,
          );
        }
        return index < 0 ? ' [Page $page]' : ' [Page $page](citation:$index)';
      },
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Copy answer',
      visualDensity: VisualDensity.compact,
      iconSize: 17,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      icon: const Icon(Icons.content_copy_rounded),
      onPressed: () {
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Answer copied')));
      },
    );
  }
}

/// The blinking block shown at the end of text that is still streaming.
class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.15, end: 1).animate(_controller),
      child: Container(
        width: 8,
        height: 16,
        margin: const EdgeInsets.only(left: 3),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _MarkdownCitationBuilder extends MarkdownElementBuilder {
  _MarkdownCitationBuilder({
    required this.citations,
    required this.onCitationTap,
  });

  final List<Citation> citations;
  final ValueChanged<Citation> onCitationTap;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final href = element.attributes['href'];
    if (href == null || !href.startsWith('citation:')) return null;
    final index = int.tryParse(href.substring('citation:'.length));
    if (index == null || index < 0 || index >= citations.length) return null;
    final citation = citations[index];

    return _InlineBadge(
      label: citation.page == null ? citation.label : 'Page ${citation.page}',
      tooltip: citation.detail,
      onTap: () => onCitationTap(citation),
    );
  }
}

/// Compact ChatGPT-style source pill shown inline after a statement.
class _InlineBadge extends StatelessWidget {
  const _InlineBadge({
    required this.label,
    required this.tooltip,
    required this.onTap,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 11,
                  color: colors.primary,
                ),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
