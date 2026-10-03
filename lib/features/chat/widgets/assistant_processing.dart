import 'package:flutter/material.dart';

/// An animated "thinking" indicator that cycles through progress stages while
/// the assistant prepares a response.
class AssistantProcessing extends StatefulWidget {
  const AssistantProcessing({super.key, required this.stage});

  final String stage;

  @override
  State<AssistantProcessing> createState() => _AssistantProcessingState();
}

class _AssistantProcessingState extends State<AssistantProcessing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: colors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, size: 16, color: colors.onPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, _) => Row(
                      children: List.generate(3, (index) {
                        final phase = (_animation.value * 3 - index) % 3;
                        final opacity =
                            0.3 + (1 - (phase - 1).abs()).clamp(0, 1) * 0.7;
                        return Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: colors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        widget.stage,
                        key: ValueKey(widget.stage),
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.onSurfaceVariant),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
