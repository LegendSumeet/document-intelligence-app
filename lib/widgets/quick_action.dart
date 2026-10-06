import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A compact secondary action shown in a row under the primary CTA.
class QuickAction extends StatelessWidget {
  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Optional second line, e.g. "Ask anything".
  final String? subtitle;

  /// Tints the card with the purple AI wash — used for the AskDocs action.
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    // A plain (non-emphasized) action is deliberately quieter than the AI
    // action: neutral icon tile, muted icon, and no purple accent.
    final iconForeground = emphasized
        ? colors.primary
        : colors.onSurfaceVariant;
    final iconBackground = emphasized
        ? colors.primary.withValues(alpha: 0.14)
        : colors.surfaceContainer;

    return Semantics(
      button: true,
      label: subtitle == null ? label : '$label, $subtitle',
      child: Material(
        color: emphasized ? tokens.accentSoft : tokens.raised,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: emphasized
                    ? colors.primary.withValues(alpha: 0.35)
                    : tokens.hairline,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconForeground),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: emphasized
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 17,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
