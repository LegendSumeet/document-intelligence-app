import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../core/widgets/citation_badge.dart';
import '../../../core/widgets/citation_evidence_sheet.dart';
import '../../../data/api/document_api.dart';
import '../../../data/models/citation_item.dart';

/// Displays a query answer or extraction result with its citations, retrieval
/// scope, and optional model-usage details.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.api,
    required this.title,
    required this.body,
    required this.citations,
    this.code = false,
    this.selectedPages = const {},
    this.usage = const {},
    this.copyable = false,
  });

  final DocumentApi api;
  final String title;
  final String body;
  final List<CitationItem> citations;
  final bool code;
  final Map<String, List<int>> selectedPages;
  final Map<String, dynamic> usage;
  final bool copyable;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  citations.isNotEmpty
                      ? Icons.fact_check_outlined
                      : Icons.info_outline,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (copyable)
                  IconButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: body));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_outlined),
                    tooltip: 'Copy result',
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (code)
              SelectableText(body)
            else
              MarkdownBody(
                data: body,
                selectable: true,
                builders: {
                  'a': CitationBadgeBuilder(
                    citations: citations,
                    onTap: (citation) =>
                        showCitationEvidence(context, api, citation),
                  ),
                },
              ),
            if (citations.isNotEmpty) ...[
              const Divider(height: 32),
              Text('Sources', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              for (final citation in citations)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => showCitationEvidence(context, api, citation),
                  leading: Icon(
                    citation.locationVerified
                        ? Icons.verified_outlined
                        : Icons.warning_amber_outlined,
                  ),
                  title: Text(citation.label),
                  subtitle: Text(
                    citation.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                ),
            ],
            if (selectedPages.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Retrieval scope',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in selectedPages.entries)
                    Chip(
                      avatar: const Icon(Icons.find_in_page_outlined, size: 16),
                      label: Text(
                        '${entry.value.length} pages from ${entry.key.substring(0, entry.key.length.clamp(0, 8))}',
                      ),
                    ),
                ],
              ),
            ],
            if (usage.isNotEmpty) ...[
              const Divider(height: 32),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.monitor_heart_outlined),
                title: const Text('Model usage'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(usage),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
