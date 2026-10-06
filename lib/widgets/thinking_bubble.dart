import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'askdocs_panda.dart';

/// The "AskDocs is thinking…" placeholder shown while an answer is pending.
///
/// Three dots animate in sequence next to a pulsing panda — a deliberate
/// alternative to a spinner.
class ThinkingBubble extends StatefulWidget {
  const ThinkingBubble({super.key, this.label = 'AskDocs is thinking'});

  final String label;

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AskDocsAvatar(size: 30),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: tokens.raised,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: tokens.hairline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  for (var i = 0; i < 3; i++)
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        // Stagger each dot by a third of the cycle.
                        final phase = (_controller.value * 3 - i) % 3;
                        final opacity = (0.25 + (1 - (phase - 1).abs()) * 0.75)
                            .clamp(0.0, 1.0);
                        return Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
