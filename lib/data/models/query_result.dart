import 'citation_item.dart';

/// A grounded answer returned by the query endpoint.
class QueryResult {
  const QueryResult({
    required this.answer,
    required this.citations,
    required this.verificationStatus,
    required this.selectedPages,
    this.usage = const {},
  });

  factory QueryResult.fromJson(Map<String, dynamic> json) => QueryResult(
    answer: json['answer'] as String,
    citations: (json['citations'] as List? ?? const [])
        .map((item) => CitationItem.fromJson(item as Map<String, dynamic>))
        .toList(),
    verificationStatus: json['verification_status'] as String,
    selectedPages: (json['selected_pages'] as Map<String, dynamic>).map(
      (documentId, pages) => MapEntry(documentId, (pages as List).cast<int>()),
    ),
    usage: (json['usage'] as Map<String, dynamic>?) ?? const {},
  );

  final String answer;
  final List<CitationItem> citations;
  final String verificationStatus;
  final Map<String, List<int>> selectedPages;
  final Map<String, dynamic> usage;

  bool get isLocationVerified => verificationStatus == 'location_verified';
}

/// A structured extraction returned by the extraction endpoint.
class ExtractionResult {
  const ExtractionResult({
    required this.schemaName,
    required this.data,
    required this.citations,
  });

  factory ExtractionResult.fromJson(Map<String, dynamic> json) =>
      ExtractionResult(
        schemaName: json['schema_name'] as String,
        data: json['data'] as Map<String, dynamic>,
        citations: (json['citations'] as List? ?? const [])
            .map((item) => CitationItem.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final String schemaName;
  final Map<String, dynamic> data;
  final List<CitationItem> citations;
}
