/// A single source document known to the backend.
class DocumentItem {
  const DocumentItem({
    required this.id,
    required this.name,
    required this.status,
    required this.pageCount,
    this.retrievalReady = false,
    this.collection,
    this.tags = const [],
    this.lastAnalyzed,
    this.sizeBytes,
  });

  factory DocumentItem.fromJson(Map<String, dynamic> json) => DocumentItem(
    id: (json['id'] ?? json['doc_id']) as String,
    name: json['name'] as String,
    status: json['status'] as String? ?? 'unknown',
    pageCount: (json['pageNum'] ?? json['page_count']) as int? ?? 0,
    retrievalReady:
        (json['retrievalReady'] ?? json['retrieval_ready']) as bool? ?? false,
    collection: json['collection'] as String?,
    tags: (json['tags'] as List? ?? const []).cast<String>(),
    lastAnalyzed: _parseDate(
      json['lastAnalyzed'] ?? json['last_analyzed'] ?? json['analyzed_at'],
    ),
    sizeBytes:
        (json['sizeBytes'] ?? json['size_bytes'] ?? json['size']) as int?,
  );

  final String id;
  final String name;
  final String status;
  final int pageCount;
  final bool retrievalReady;
  final String? collection;
  final List<String> tags;

  /// When the document was last analyzed, if the backend reports it.
  final DateTime? lastAnalyzed;

  /// Original file size in bytes, if the backend reports it.
  final int? sizeBytes;

  bool get isReady => status == 'completed' && retrievalReady;

  String get readinessLabel {
    if (isReady) return 'Ready for analysis';
    if (status == 'completed') return 'Preparing retrieval';
    return status;
  }
}

/// Parses an ISO-8601 string or epoch millis/seconds into a [DateTime].
DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  if (value is num) {
    final millis = value > 100000000000 ? value.toInt() : value.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  if (value is String) return DateTime.tryParse(value)?.toLocal();
  return null;
}

/// Result of uploading a PDF: the resolved document plus whether an existing
/// index was reused.
class DocumentUploadResult {
  const DocumentUploadResult({required this.document, required this.reused});

  factory DocumentUploadResult.fromJson(Map<String, dynamic> json) =>
      DocumentUploadResult(
        document: DocumentItem.fromJson(
          json['document'] as Map<String, dynamic>,
        ),
        reused: json['reused'] as bool? ?? false,
      );

  final DocumentItem document;
  final bool reused;
}
