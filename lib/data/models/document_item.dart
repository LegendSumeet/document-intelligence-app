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
  );

  final String id;
  final String name;
  final String status;
  final int pageCount;
  final bool retrievalReady;
  final String? collection;
  final List<String> tags;

  bool get isReady => status == 'completed' && retrievalReady;

  String get readinessLabel {
    if (isReady) return 'Ready for analysis';
    if (status == 'completed') return 'Preparing retrieval';
    return status;
  }
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
