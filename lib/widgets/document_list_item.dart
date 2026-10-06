import 'package:flutter/material.dart';

import '../models/document.dart';
import '../theme/app_theme.dart';
import 'document_icon.dart';

/// A single row in the "Recent documents" list.
///
/// Deliberately calm: the title leads, the file metadata is one quiet line,
/// and the analysis status is visually secondary to the document itself.
/// Tapping anywhere on the row opens the document chat; when the title has
/// been shortened or replaced, a tooltip reveals the real filename.
class DocumentListItem extends StatelessWidget {
  const DocumentListItem({
    super.key,
    required this.document,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  final Document document;
  final VoidCallback onTap;

  /// Used on the upload screen to show the chosen file.
  final bool selected;

  /// Optional widget replacing the default chevron (e.g. a "more" menu).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.tokens;

    final row = Semantics(
      button: true,
      label:
          '${document.displayName}, ${document.metaLabel}, '
          '${document.statusLabel}',
      child: Material(
        color: selected ? tokens.accentSoft : tokens.raised,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? colors.primary : tokens.hairline,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                DocumentIcon(kind: document.kind, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        document.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        document.metaLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 7),
                      _StatusLine(document: document),
                    ],
                  ),
                ),
                // Keep a clear gutter between the text and the trailing action
                // so a long filename never crowds the menu icon.
                const SizedBox(width: 14),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
              ],
            ),
          ),
        ),
      ),
    );

    // Only wrap in a tooltip when the shown title differs from the real name,
    // so users can still recover a shortened or UUID filename.
    if (document.displayName != document.fullName) {
      return Tooltip(message: document.fullName, child: row);
    }
    return row;
  }
}

/// The single, unambiguous status line shown at the bottom of a card.
///
/// Uses a small dot rather than a heavy pill so the status stays visually
/// secondary to the document name.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    final (dot, foreground) = switch (document.status) {
      AnalysisStatus.analyzed => (Icons.circle, tokens.positive),
      AnalysisStatus.analyzing => (Icons.circle, tokens.caution),
      AnalysisStatus.notAnalyzed => (
        Icons.circle_outlined,
        colors.onSurfaceVariant,
      ),
    };

    return Row(
      children: [
        Icon(dot, size: 9, color: foreground),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            document.statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
