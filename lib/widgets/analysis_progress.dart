import 'package:flutter/material.dart';

import '../data/analysis_stages.dart';
import '../theme/app_theme.dart';

/// The staged analysis progress shown after "Analyze with AskDocs".
///
/// Each stage animates from pending → active → done. The check marks pop in
/// rather than appearing instantly, which is what makes the sequence feel like
/// real work rather than a fake timer.
class AnalysisProgress extends StatelessWidget {
  const AnalysisProgress({
    super.key,
    required this.stages,
    required this.activeIndex,
    required this.progress,
    required this.isComplete,
  });

  final List<AnalysisStage> stages;

  /// Index of the stage currently being worked on; equals `stages.length` when
  /// finished.
  final int activeIndex;

  /// 0..1 overall completion, driving the top progress bar.
  final double progress;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.raised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: isComplete
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('done'),
                        size: 20,
                        color: tokens.positive,
                      )
                    : SizedBox.square(
                        key: const ValueKey('busy'),
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: colors.primary,
                          value: progress == 0 ? null : progress,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isComplete ? 'Analysis complete' : 'Analyzing document',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0, 1)),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: colors.surfaceContainerHigh,
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < stages.length; i++)
            _StageRow(
              label: stages[i].label,
              state: i < activeIndex
                  ? _StageState.done
                  : i == activeIndex
                  ? _StageState.active
                  : _StageState.pending,
            ),
        ],
      ),
    );
  }
}

enum _StageState { done, active, pending }

class _StageRow extends StatelessWidget {
  const _StageRow({required this.label, required this.state});

  final String label;
  final _StageState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    final (Widget leading, Color textColor) = switch (state) {
      _StageState.done => (
        Icon(Icons.check_rounded, size: 15, color: tokens.positive),
        colors.onSurfaceVariant,
      ),
      _StageState.active => (
        SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary,
          ),
        ),
        colors.onSurface,
      ),
      _StageState.pending => (
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.outlineVariant, width: 1.5),
          ),
        ),
        colors.onSurfaceVariant.withValues(alpha: 0.7),
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 20, child: Center(child: leading)),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style:
                  theme.textTheme.bodyMedium?.copyWith(color: textColor) ??
                  TextStyle(color: textColor),
              child: Text(label),
            ),
          ),
        ],
      ),
    );
  }
}
