import 'package:documentintelligence/core/services/citation_formatting.dart';
import 'package:documentintelligence/data/models/citation_item.dart';
import 'package:documentintelligence/data/models/document_item.dart';
import 'package:documentintelligence/data/models/page_evidence.dart';
import 'package:documentintelligence/data/models/query_result.dart';
import 'package:documentintelligence/models/document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats human relative times for the status line', () {
    final now = DateTime(2026, 10, 4, 18, 0);

    expect(
      relativeTime(now.subtract(const Duration(seconds: 20)), now: now),
      'just now',
    );
    expect(
      relativeTime(now.subtract(const Duration(minutes: 5)), now: now),
      '5m ago',
    );
    expect(
      relativeTime(now.subtract(const Duration(hours: 2)), now: now),
      '2h ago',
    );
    expect(
      relativeTime(now.subtract(const Duration(days: 1)), now: now),
      'yesterday',
    );
    expect(
      relativeTime(now.subtract(const Duration(days: 3)), now: now),
      '3 days ago',
    );
    expect(
      relativeTime(now.subtract(const Duration(days: 9)), now: now),
      'a week ago',
    );
  });

  test('analyzed documents read as a single unambiguous status', () {
    final analyzed = Document.fromItem(
      DocumentItem.fromJson({
        'id': 'doc-1',
        'name': 'SBI Card Statement.pdf',
        'status': 'completed',
        'pageNum': 7,
        'retrievalReady': true,
        'lastAnalyzed': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      }),
    );

    expect(analyzed.status, AnalysisStatus.analyzed);
    expect(analyzed.statusLabel, 'Analyzed 2h ago');
  });

  test('collapses UUID filenames to a generic title', () {
    final uuid = Document.fromItem(
      DocumentItem.fromJson({
        'id': 'doc-1',
        'name': 'cb23eabc-0726-40fd-8a54-28c440fdadd3.pdf',
        'status': 'completed',
        'pageNum': 4,
        'retrievalReady': true,
      }),
    );

    expect(uuid.hasGenericName, isTrue);
    expect(uuid.displayName, 'Document');
    expect(uuid.fullName, 'cb23eabc-0726-40fd-8a54-28c440fdadd3.pdf');
  });

  test('builds metadata with file size when provided', () {
    final doc = Document.fromItem(
      DocumentItem.fromJson({
        'id': 'doc-1',
        'name': 'report.pdf',
        'status': 'completed',
        'pageNum': 7,
        'retrievalReady': true,
        'sizeBytes': 2516582,
      }),
    );

    expect(doc.metaLabel, 'PDF · 7 pages · 2.4 MB');
  });
  test('requires completed status and retrieval readiness', () {
    final ready = DocumentItem.fromJson({
      'doc_id': 'doc-ready',
      'name': 'ready.pdf',
      'status': 'completed',
      'page_count': 4,
      'retrievalReady': true,
      'collection': 'default',
      'tags': ['finance'],
    });
    final preparing = DocumentItem.fromJson({
      'doc_id': 'doc-preparing',
      'name': 'preparing.pdf',
      'status': 'completed',
      'page_count': 4,
      'retrievalReady': false,
    });

    expect(ready.isReady, isTrue);
    expect(ready.collection, 'default');
    expect(ready.tags, ['finance']);
    expect(preparing.isReady, isFalse);
    expect(preparing.readinessLabel, 'Preparing retrieval');
  });

  test('parses upload reuse result', () {
    final result = DocumentUploadResult.fromJson({
      'reused': true,
      'document': {
        'doc_id': 'doc-1',
        'name': 'report.pdf',
        'status': 'completed',
        'page_count': 3,
      },
    });

    expect(result.reused, isTrue);
    expect(result.document.name, 'report.pdf');
  });

  test('removes citation markup from rendered answers', () {
    const answer = '''Clause 4.2 requires management oversight.
<cite doc="test2.pdf" page="9" lines="4-8"/>''';

    expect(cleanAnswer(answer), 'Clause 4.2 requires management oversight.');
  });

  test('builds readable citation label', () {
    const citation = CitationItem(
      document: 'test2.pdf',
      docId: 'doc-1',
      page: 9,
      startLine: 4,
      endLine: 8,
      text: 'Evidence',
    );

    expect(citation.label, 'Page 9 · Lines 4–8');
  });

  test('replaces citation tags with inline source labels', () {
    const answer = '''A supported statement.
<cite doc="test2.pdf" page="9" lines="4-8"/>
Another supported statement. <cite doc="test2.pdf" page="10" lines="2-3"/>''';
    const citations = [
      CitationItem(
        document: 'test2.pdf',
        docId: 'doc-1',
        page: 9,
        startLine: 4,
        endLine: 8,
        text: 'First evidence',
      ),
      CitationItem(
        document: 'test2.pdf',
        docId: 'doc-1',
        page: 10,
        startLine: 2,
        endLine: 3,
        text: 'Second evidence',
      ),
    ];

    expect(
      answerWithCitationLinks(answer, citations),
      'A supported statement.\n [test2](citation:0)\n'
      'Another supported statement.  [test2](citation:1)',
    );
    expect(citationIndexFromHref('citation:1'), 1);
    expect(citationIndexFromHref('https://example.com'), isNull);
  });

  test('shortens long inline source labels', () {
    const citation = CitationItem(
      document: 'EU_IVDR-2017-746-Regulation-Table-of-Contents.pdf',
      docId: 'doc-1',
      page: 70,
      startLine: 1,
      endLine: 2,
      text: 'Evidence',
    );

    expect(citation.inlineLabel.length, lessThanOrEqualTo(28));
    expect(citation.inlineLabel, endsWith('…'));
  });

  test('parses query results with selected pages and bounding boxes', () {
    final result = QueryResult.fromJson({
      'answer': 'Supported answer.',
      'verification_status': 'location_verified',
      'selected_pages': {
        'doc-1': [1, 3],
      },
      'citations': [
        {
          'document': 'report.pdf',
          'doc_id': 'doc-1',
          'page': 1,
          'start_line': 2,
          'end_line': 4,
          'text': 'Evidence',
          'bounding_boxes': [
            [0, 1.5, 10, 20],
          ],
          'location_verified': true,
        },
      ],
      'usage': {'total_tokens': 42},
    });

    expect(result.isLocationVerified, isTrue);
    expect(result.selectedPages['doc-1'], [1, 3]);
    expect(result.citations.single.boundingBoxes.single, [
      0.0,
      1.5,
      10.0,
      20.0,
    ]);
  });

  test('parses structured page evidence', () {
    final evidence = PageEvidenceResult.fromJson({
      'document': 'report.pdf',
      'doc_id': 'doc-1',
      'page': 2,
      'lines': [
        {
          'line': 7,
          'text': 'Exact source text',
          'bbox': [24, 130.2, 558.4, 144.9],
        },
      ],
    });

    expect(evidence.page, 2);
    expect(evidence.lines.single.line, 7);
    expect(evidence.lines.single.boundingBox.length, 4);
  });

  test('renders streaming markdown citations and hides partial tags', () {
    const documents = [
      DocumentItem(
        id: 'doc-1',
        name: 'report.pdf',
        status: 'completed',
        pageCount: 3,
        retrievalReady: true,
      ),
    ];
    final parsed = parseStreamingAnswer(
      '## Finding\nRevenue grew. '
      '<cite doc="report.pdf" page="2" lines="4-6"/>\n'
      'More text <cite doc="report.pdf"',
      documents,
    );

    expect(parsed.markdown, contains('## Finding'));
    expect(parsed.markdown, contains('[report](citation:0)'));
    expect(parsed.markdown, isNot(contains('<cite')));
    expect(parsed.citations.single.docId, 'doc-1');
    expect(parsed.citations.single.page, 2);
  });

  test('maps technical processing stages to user-friendly messages', () {
    expect(chatProgressLabel('retrieval'), 'Finding relevant information...');
    expect(chatProgressLabel('evidence'), 'Reviewing the source details...');
    expect(chatProgressLabel('generation'), 'Writing your answer...');
    expect(
      chatProgressLabel('validation'),
      'Checking the source references...',
    );
    expect(chatProgressLabel('unknown'), 'Getting your answer ready...');
  });
}
