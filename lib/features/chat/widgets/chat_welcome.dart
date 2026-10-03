import 'package:flutter/material.dart';

import '../../../data/models/document_item.dart';

/// Empty-state shown in the chat before the first message, with suggested
/// prompts derived from the current document scope.
class ChatWelcome extends StatelessWidget {
  const ChatWelcome({
    super.key,
    required this.documents,
    required this.onPrompt,
  });

  final List<DocumentItem> documents;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final prompts = [
      'Summarize the key findings and decisions.',
      'Identify obligations, deadlines, and owners.',
      if (documents.length > 1)
        'Compare the documents and highlight conflicts.',
      'What risks or missing information should I review?',
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              size: 28,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ask with evidence',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${documents.length} source${documents.length == 1 ? '' : 's'} in scope',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final prompt in prompts)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 330),
                  child: ActionChip(
                    avatar: const Icon(Icons.arrow_outward, size: 16),
                    label: Text(prompt),
                    onPressed: () => onPrompt(prompt),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
