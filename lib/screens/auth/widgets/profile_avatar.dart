import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// A defensive profile picture.
///
/// Google photo URLs are remote and can fail (offline, expired token, no
/// photo). This widget always resolves to *something*: the photo when it
/// loads, and the user's initial otherwise — never a broken image icon.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.photoUrl,
    required this.displayName,
    this.radius = 44,
  });

  final String? photoUrl;
  final String? displayName;
  final double radius;

  /// First letter of the display name, falling back to the email's first
  /// letter and finally to a neutral glyph.
  String get _initial {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name.characters.first;
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final url = photoUrl;

    return Semantics(
      image: true,
      label: '${displayName ?? 'User'} profile photo',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: colors.primaryContainer,
        foregroundImage: (url == null || url.isEmpty)
            ? null
            : NetworkImage(url),
        // Shown while the photo loads and if it fails — so the initial is
        // always the safe fallback rather than an empty circle.
        child: Text(
          _initial,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: colors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

/// A labelled, read-only piece of profile data.
class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A hairline divider matched to the app's token palette.
class ProfileDivider extends StatelessWidget {
  const ProfileDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.tokens.hairline);
  }
}
