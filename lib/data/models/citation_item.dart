/// A traceable reference from an answer back to an exact location in a source
/// document.
class CitationItem {
  const CitationItem({
    required this.document,
    required this.docId,
    required this.page,
    required this.startLine,
    required this.endLine,
    required this.text,
    this.boundingBoxes = const [],
    this.locationVerified = true,
  });

  factory CitationItem.fromJson(Map<String, dynamic> json) => CitationItem(
    document: json['document'] as String,
    docId: json['doc_id'] as String,
    page: json['page'] as int,
    startLine: json['start_line'] as int,
    endLine: json['end_line'] as int,
    text: json['text'] as String,
    boundingBoxes: (json['bounding_boxes'] as List? ?? const [])
        .map(
          (box) =>
              (box as List).map((value) => (value as num).toDouble()).toList(),
        )
        .toList(),
    locationVerified: json['location_verified'] as bool? ?? true,
  );

  final String document;
  final String docId;
  final int page;
  final int startLine;
  final int endLine;
  final String text;
  final List<List<double>> boundingBoxes;
  final bool locationVerified;

  String get label => 'Page $page · Lines $startLine–$endLine';

  String get inlineLabel {
    final withoutExtension = document.toLowerCase().endsWith('.pdf')
        ? document.substring(0, document.length - 4)
        : document;
    if (withoutExtension.length <= 28) return withoutExtension;
    return '${withoutExtension.substring(0, 25)}…';
  }
}
