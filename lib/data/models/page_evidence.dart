/// A single line of evidence extracted from a document page.
class LineEvidenceItem {
  const LineEvidenceItem({
    required this.line,
    required this.text,
    required this.boundingBox,
  });

  factory LineEvidenceItem.fromJson(Map<String, dynamic> json) =>
      LineEvidenceItem(
        line: json['line'] as int,
        text: json['text'] as String,
        boundingBox: (json['bbox'] as List)
            .map((value) => (value as num).toDouble())
            .toList(),
      );

  final int line;
  final String text;
  final List<double> boundingBox;
}

/// The full set of line evidence for one page of a document.
class PageEvidenceResult {
  const PageEvidenceResult({
    required this.document,
    required this.documentId,
    required this.page,
    required this.lines,
  });

  factory PageEvidenceResult.fromJson(Map<String, dynamic> json) =>
      PageEvidenceResult(
        document: json['document'] as String,
        documentId: json['doc_id'] as String,
        page: json['page'] as int,
        lines: (json['lines'] as List)
            .map(
              (item) => LineEvidenceItem.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );

  final String document;
  final String documentId;
  final int page;
  final List<LineEvidenceItem> lines;
}

/// The concatenated text evidence for a range of pages.
class NumberedPagesResult {
  const NumberedPagesResult({required this.pages, required this.evidence});

  factory NumberedPagesResult.fromJson(Map<String, dynamic> json) =>
      NumberedPagesResult(
        pages: (json['pages'] as List).cast<int>(),
        evidence: json['evidence'] as String,
      );

  final List<int> pages;
  final String evidence;
}
