import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import '../../core/services/citation_formatting.dart';
import '../../data/models/citation_item.dart';

/// Renders a `[label](citation:<n>)` markdown link as an interactive badge that
/// opens the corresponding [CitationItem] evidence.
class CitationBadgeBuilder extends MarkdownElementBuilder {
  CitationBadgeBuilder({required this.citations, required this.onTap});

  final List<CitationItem> citations;
  final ValueChanged<CitationItem> onTap;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final index = citationIndexFromHref(element.attributes['href']);
    if (index == null || index >= citations.length) return null;
    final citation = citations[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: () => onTap(citation),
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  citation.inlineLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
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
