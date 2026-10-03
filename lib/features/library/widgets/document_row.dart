import 'package:flutter/material.dart';

import '../../../data/models/document_item.dart';

/// A selectable row summarising a single [DocumentItem] in the library.
class DocumentRow extends StatelessWidget {
  const DocumentRow({
    super.key,
    required this.document,
    required this.selected,
    required this.onSelected,
    required this.onInspect,
  });

  final DocumentItem document;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onInspect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colors.primaryContainer.withValues(alpha: 0.48)
          : colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onSelected == null ? null : () => onSelected!(!selected),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: onSelected == null
                    ? null
                    : (value) => onSelected!(value ?? false),
              ),
              const SizedBox(width: 6),
              Container(
                width: 42,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.picture_as_pdf_outlined,
                  color: colors.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${document.pageCount} pages  ·  ${document.readinessLabel}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                    if (document.collection != null || document.tags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [
                            if (document.collection != null)
                              document.collection!,
                            ...document.tags,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
              if (onInspect != null)
                IconButton(
                  onPressed: onInspect,
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Inspect document',
                )
              else
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
