import 'package:flutter/material.dart';

import '../models/chat_message.dart';

/// A tappable source reference, e.g. `[Page 4]`.
///
/// Rendered as a real interactive control with a comfortable tap target rather
/// than inline dead text.
class CitationChip extends StatelessWidget {
  const CitationChip({super.key, required this.citation, required this.onTap});

  final Citation citation;
  final ValueChanged<Citation> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      button: true,
      label: 'Source reference ${citation.label}',
      child: Material(
        color: colors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(9),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onTap(citation),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 13,
                  color: colors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  citation.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
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
