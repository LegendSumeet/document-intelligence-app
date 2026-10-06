import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The AskDocs panda mark.
///
/// This is the single source of brand identity and is intentionally used
/// sparingly: the logo, the AI avatar in chat, and the AI insight card.
///
/// The panda is clipped to a soft rounded square so it reads as a product mark
/// rather than a floating image, and gets a hairline ring so it holds up on
/// both light and dark surfaces.
class AskDocsPanda extends StatelessWidget {
  const AskDocsPanda({
    super.key,
    this.size = 40,
    this.showRing = true,
    this.semanticLabel = 'AskDocs panda',
  });

  /// The asset is square; this sets both width and height.
  final double size;
  final bool showRing;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = size * 0.3;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: showRing
              ? Border.all(color: tokens.hairline, width: 1)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/dia-icon.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          // Never let a missing asset take the screen down.
          errorBuilder: (context, error, stack) => _Fallback(size: size),
        ),
      ),
    );
  }
}

/// Shown only if the panda asset cannot be decoded.
class _Fallback extends StatelessWidget {
  const _Fallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.primaryContainer,
      child: Icon(
        Icons.pets_rounded,
        size: size * 0.5,
        color: colors.onPrimaryContainer,
      ),
    );
  }
}

/// The AI avatar used beside every AskDocs message.
///
/// A slimmer variant of [AskDocsPanda] without the ring, sized for chat rows.
class AskDocsAvatar extends StatelessWidget {
  const AskDocsAvatar({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return AskDocsPanda(size: size, showRing: false, semanticLabel: 'AskDocs');
  }
}

/// The "AskDocs" wordmark, optionally paired with the panda.
class AskDocsLogo extends StatelessWidget {
  const AskDocsLogo({
    super.key,
    this.pandaSize = 34,
    this.showWordmark = true,
    this.textStyle,
  });

  final double pandaSize;
  final bool showWordmark;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AskDocsPanda(size: pandaSize),
        if (showWordmark) ...[
          const SizedBox(width: 10),
          Text(
            'AskDocs',
            style:
                textStyle ??
                theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
          ),
        ],
      ],
    );
  }
}
