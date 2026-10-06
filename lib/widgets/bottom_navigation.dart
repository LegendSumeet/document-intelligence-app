import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The three destinations in the AskDocs bottom bar.
enum HomeTab { home, documents, ask }

/// Visual-only bottom navigation.
///
/// `documents` is intentionally inert for now — it must not navigate to an
/// unimplemented screen.
class AskDocsBottomNav extends StatelessWidget {
  const AskDocsBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final HomeTab current;
  final ValueChanged<HomeTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      decoration: BoxDecoration(
        color: tokens.raised,
        border: Border(top: BorderSide(color: tokens.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                outlinedIcon: Icons.home_outlined,
                label: 'Home',
                selected: current == HomeTab.home,
                onTap: () => onSelected(HomeTab.home),
              ),
              _NavItem(
                icon: Icons.folder_rounded,
                outlinedIcon: Icons.folder_outlined,
                label: 'Documents',
                selected: current == HomeTab.documents,
                // No destination yet: present, but not navigable.
                onTap: null,
              ),
              _NavItem(
                icon: Icons.auto_awesome_rounded,
                outlinedIcon: Icons.auto_awesome_outlined,
                label: 'Ask',
                selected: current == HomeTab.ask,
                onTap: () => onSelected(HomeTab.ask),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enabled = onTap != null;

    final foreground = !enabled
        ? colors.onSurfaceVariant.withValues(alpha: 0.38)
        : selected
        ? colors.primary
        : colors.onSurfaceVariant;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    selected ? icon : outlinedIcon,
                    size: 22,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
