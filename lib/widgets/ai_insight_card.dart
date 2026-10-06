import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'askdocs_panda.dart';

/// A small, premium AI insight surfaced on the home screen.
///
/// Kept deliberately low-profile: a panda mark, one sentence of insight, and a
/// single action. It is not a hero banner.
class AIInsightCard extends StatelessWidget {
  const AIInsightCard({super.key, required this.insight, required this.onAsk});

  final String insight;
  final VoidCallback onAsk;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.accentSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AskDocsAvatar(size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AskDocs found something interesting',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAsk,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                backgroundColor: colors.primary.withValues(alpha: 0.10),
                foregroundColor: colors.primary,
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 17),
              label: const Text('Ask AskDocs'),
            ),
          ),
        ],
      ),
    );
  }
}
