import 'package:flutter/material.dart';

import '../../data/api/document_api.dart';
import '../../data/models/citation_item.dart';
import '../../data/models/page_evidence.dart';
import '../../features/source_viewer/source_pdf_page.dart';
import 'feedback_panels.dart';

/// Shows a bottom sheet with the cited text and the surrounding page evidence,
/// highlighting the cited line range.
Future<void> showCitationEvidence(
  BuildContext context,
  DocumentApi api,
  CitationItem citation,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    citation.locationVerified
                        ? Icons.verified_outlined
                        : Icons.warning_amber_outlined,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      citation.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SourcePdfPage(
                            api: api,
                            documentId: citation.docId,
                            documentName: citation.document,
                            citation: citation,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Open PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SelectableText(citation.text),
              const Divider(height: 28),
              Text(
                'Page evidence',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<PageEvidenceResult>(
                  future: api.getPageEvidence(citation.docId, citation.page),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return ErrorPanel(message: snapshot.error.toString());
                    }
                    return ListView(
                      children: [
                        for (final line in snapshot.data?.lines ?? const [])
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            color:
                                line.line >= citation.startLine &&
                                    line.line <= citation.endLine
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            child: SelectableText(
                              '${line.line.toString().padLeft(3)}  ${line.text}',
                              style: const TextStyle(height: 1.35),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
