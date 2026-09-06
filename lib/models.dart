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

class ChatSession {
  const ChatSession({
    required this.id,
    required this.documentIds,
    this.history = const [],
    this.busy = false,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
    id: json['id'] as String,
    documentIds: (json['document_ids'] as List).cast<String>(),
    history: (json['history'] as List? ?? const [])
        .map((item) => ChatTurn.fromJson(item as Map<String, dynamic>))
        .toList(),
    busy: json['busy'] as bool? ?? false,
  );

  final String id;
  final List<String> documentIds;
  final List<ChatTurn> history;
  final bool busy;
}

class ChatTurn {
  const ChatTurn({required this.role, required this.content});

  factory ChatTurn.fromJson(Map<String, dynamic> json) => ChatTurn(
    role: json['role'] as String,
    content: json['content'] as String,
  );

  final String role;
  final String content;
}

class ChatStreamEvent {
  const ChatStreamEvent({required this.type, required this.data});

  final String type;
  final Map<String, dynamic> data;
}

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.text,
    this.verified = false,
    this.citations = const [],
    this.conversational = false,
    this.selectedPages = const {},
    this.usage = const {},
  });

  final String role;
  final String text;
  final bool verified;
  final List<CitationItem> citations;
  final bool conversational;
  final Map<String, List<int>> selectedPages;
  final Map<String, dynamic> usage;
}

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

  String get label => '$document · p. $page · L$startLine–$endLine';

  String get inlineLabel {
    final withoutExtension = document.toLowerCase().endsWith('.pdf')
        ? document.substring(0, document.length - 4)
        : document;
    if (withoutExtension.length <= 28) return withoutExtension;
    return '${withoutExtension.substring(0, 25)}…';
  }
}

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

String cleanAnswer(String answer) => answer
    .replaceAll(
      RegExp(r'<cite\s+doc="[^"]+"\s+page="\d+"\s+lines="[^"]+"\s*/>'),
      '',
    )
    .replaceAll(RegExp(r'[ \t]+\n'), '\n')
    .replaceAll(RegExp(r'\n{3,}'), '\n\n')
    .trim();

String answerWithCitationLinks(String answer, List<CitationItem> citations) {
  var citationIndex = 0;
  return answer
      .replaceAllMapped(
        RegExp(r'<cite\s+doc="[^"]+"\s+page="\d+"\s+lines="[^"]+"\s*/>'),
        (_) {
          if (citationIndex >= citations.length) return '';
          final currentIndex = citationIndex;
          final citation = citations[citationIndex++];
          return ' [${citation.inlineLabel}](citation:$currentIndex)';
        },
      )
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

int? citationIndexFromHref(String? href) {
  if (href == null || !href.startsWith('citation:')) return null;
  return int.tryParse(href.substring('citation:'.length));
}

String chatProgressLabel(String? stage) => switch (stage) {
  'conversation' => 'Preparing a response...',
  'scope' => 'Checking your selected documents...',
  'retrieval' => 'Finding relevant information...',
  'evidence' => 'Reviewing the source details...',
  'generation' => 'Writing your answer...',
  'validation' => 'Checking the source references...',
  'complete' => 'Finishing your answer...',
  _ => 'Getting your answer ready...',
};

class StreamingAnswer {
  const StreamingAnswer({required this.markdown, required this.citations});

  final String markdown;
  final List<CitationItem> citations;
}

StreamingAnswer parseStreamingAnswer(
  String answer,
  List<DocumentItem> documents,
) {
  final citations = <CitationItem>[];
  final citationPattern = RegExp(
    r'<cite\s+doc="([^"]+)"\s+page="(\d+)"\s+lines="(\d+)-(\d+)"\s*/>',
  );
  var markdown = answer.replaceAllMapped(citationPattern, (match) {
    final documentName = match.group(1)!;
    DocumentItem? document;
    for (final item in documents) {
      if (item.name == documentName) {
        document = item;
        break;
      }
    }
    if (document == null) return '';
    final citation = CitationItem(
      document: documentName,
      docId: document.id,
      page: int.parse(match.group(2)!),
      startLine: int.parse(match.group(3)!),
      endLine: int.parse(match.group(4)!),
      text: 'Open the source to inspect this evidence.',
      locationVerified: false,
    );
    final index = citations.length;
    citations.add(citation);
    return ' [${citation.inlineLabel}](citation:$index)';
  });

  final incompleteTag = markdown.lastIndexOf('<cite');
  if (incompleteTag != -1) markdown = markdown.substring(0, incompleteTag);
  return StreamingAnswer(markdown: markdown, citations: citations);
}
