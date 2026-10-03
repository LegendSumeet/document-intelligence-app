import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../core/widgets/citation_badge.dart';
import '../../../core/widgets/citation_evidence_sheet.dart';
import '../../../data/api/document_api.dart';
import '../../../data/models/chat_models.dart';

/// A single chat transcript bubble (user or assistant), optionally rendering a
/// streaming draft with its response metadata.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.api,
    this.isDraft = false,
  });

  final ChatMessage message;
  final DocumentApi api;
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final user = message.role == 'user';
    if (user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 620),
          margin: const EdgeInsets.only(bottom: 22, left: 54),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: SelectableText(
            message.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message.text,
                    selectable: true,
                    builders: {
                      'a': CitationBadgeBuilder(
                        citations: message.citations,
                        onTap: (citation) =>
                            showCitationEvidence(context, api, citation),
                      ),
                    },
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                        .copyWith(
                          p: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(height: 1.55),
                          h3: Theme.of(context).textTheme.titleLarge,
                          listBullet: Theme.of(context).textTheme.bodyLarge,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ResponseMeta(message: message, isDraft: isDraft),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small footer describing the provenance/status of an assistant message.
class ResponseMeta extends StatelessWidget {
  const ResponseMeta({super.key, required this.message, required this.isDraft});

  final ChatMessage message;
  final bool isDraft;

  @override
  Widget build(BuildContext context) {
    final icon = isDraft
        ? Icons.pending_outlined
        : message.verified
        ? Icons.verified_outlined
        : Icons.forum_outlined;
    final label = isDraft
        ? 'Streaming response'
        : message.verified
        ? 'Citation locations verified · ${message.citations.length} source(s)'
        : 'Conversational response';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
