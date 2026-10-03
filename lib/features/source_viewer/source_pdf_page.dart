import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../data/api/document_api.dart';
import '../../data/models/citation_item.dart';

/// Displays the raw source PDF, optionally highlighting a citation's bounding
/// boxes on the referenced page.
class SourcePdfPage extends StatefulWidget {
  const SourcePdfPage({
    super.key,
    required this.api,
    required this.documentId,
    required this.documentName,
    this.citation,
  });

  final DocumentApi api;
  final String documentId;
  final String documentName;
  final CitationItem? citation;

  @override
  State<SourcePdfPage> createState() => _SourcePdfPageState();
}

class _SourcePdfPageState extends State<SourcePdfPage> {
  late final Future<Uint8List> _pdfBytes;

  @override
  void initState() {
    super.initState();
    _pdfBytes = widget.api.getDocumentFile(widget.documentId);
  }

  @override
  Widget build(BuildContext context) {
    final citation = widget.citation;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.documentName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (citation != null)
              Text(
                'Page ${citation.page} · lines ${citation.startLine}-${citation.endLine}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
          ],
        ),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfBytes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return PdfViewer.data(
            snapshot.requireData,
            sourceName: '${widget.documentId}-${widget.documentName}',
            initialPageNumber: citation?.page ?? 1,
            params: PdfViewerParams(
              margin: 12,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              pageOverlaysBuilder: citation == null
                  ? null
                  : (context, pageRect, page) {
                      if (page.pageNumber != citation.page) return const [];
                      final scaleX = pageRect.width / page.width;
                      final scaleY = pageRect.height / page.height;
                      return [
                        for (final box in citation.boundingBoxes)
                          if (box.length >= 4)
                            Positioned(
                              left: box[0] * scaleX,
                              top: box[1] * scaleY,
                              width: (box[2] - box[0]) * scaleX,
                              height: (box[3] - box[1]) * scaleY,
                              child: IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiaryContainer
                                        .withValues(alpha: 0.45),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                      ];
                    },
            ),
          );
        },
      ),
    );
  }
}
