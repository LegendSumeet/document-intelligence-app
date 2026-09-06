import 'package:documentintelligence/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

    expect(citation.label, 'test2.pdf · p. 9 · L4–8');
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
