import 'dart:convert';

import 'package:documentintelligence/app.dart';
import 'package:documentintelligence/data/api/document_api.dart';
import 'package:documentintelligence/screens/chat/chat_screen.dart';
import 'package:documentintelligence/screens/home/home_screen.dart';
import 'package:documentintelligence/screens/upload/upload_screen.dart';
import 'package:documentintelligence/widgets/document_list_item.dart';
import 'package:documentintelligence/widgets/sidebar_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

DocumentApi _fakeApi({
  List<Map<String, dynamic>>? documents,
  void Function(List<dynamic> documentIds)? onSessionCreated,
  void Function(String message)? onMessageSent,
}) {
  final docs =
      documents ??
      [
        {
          'id': 'doc-1',
          'name': 'Annual Report.pdf',
          'status': 'completed',
          'pageNum': 12,
          'retrievalReady': true,
          'lastAnalyzed': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
        },
      ];
  final client = MockClient((request) async {
    Map<String, dynamic> body;
    switch ((request.method, request.url.path)) {
      case ('GET', '/documents'):
        body = {'documents': docs};
      case ('POST', '/chat/sessions'):
        final documentIds =
            (jsonDecode(request.body) as Map<String, dynamic>)['document_ids']
                as List<dynamic>;
        onSessionCreated?.call(documentIds);
        body = {'id': 's1', 'document_ids': documentIds};
      case ('PUT', '/chat/sessions/s1/documents'):
        final documentIds =
            (jsonDecode(request.body) as Map<String, dynamic>)['document_ids']
                as List<dynamic>;
        body = {'id': 's1', 'document_ids': documentIds};
      case ('POST', '/chat/sessions/s1/messages/stream'):
        final requestBody = jsonDecode(request.body) as Map<String, dynamic>;
        onMessageSent?.call(requestBody['message'] as String);
        final complete = {
          'data': {
            'answer': 'Revenue grew **12%**.<cite doc="Annual Report.pdf" page="4" lines="1-3"/>',
            'citations': [
              {
                'document': 'Annual Report.pdf',
                'doc_id': 'doc-1',
                'page': 4,
                'start_line': 1,
                'end_line': 3,
                'text': 'Revenue increased by 12% year over year.',
              },
            ],
            'verification_status': 'location_verified',
            'selected_pages': {
              'doc-1': [4],
            },
          },
        };
        final sse =
            'event: status\ndata: {"stage":"retrieving"}\n\n'
            'event: answer_delta\ndata: {"delta":"Revenue grew **12%**."}\n\n'
            'event: answer_delta\ndata: {"delta":"<cite doc=\\"Annual Report.pdf\\" pa"}\n\n'
            'event: complete\ndata: ${jsonEncode(complete)}\n\n';
        return http.Response(
          sse,
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      default:
        return http.Response('{"detail":"not found"}', 404);
    }
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
  return DocumentApi(client: client, validateConfig: false);
}

/// Gives the test a phone-height viewport so document lists have room to lay out.
Future<void> _pumpHome(
  WidgetTester tester, {
  List<Map<String, dynamic>>? documents,
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AskDocsApp(api: _fakeApi(documents: documents)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('chat home shows the ready prompt and composer', (tester) async {
    await _pumpHome(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Ready when you are.'), findsOneWidget);
    expect(find.text('Summarize a document'), findsOneWidget);
    expect(find.byTooltip('Attach a file'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-section-Chat')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('home-section-Documents')),
      findsOneWidget,
    );
  });

  testWidgets('Documents tab shows the document search field', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home-section-Documents')));
    await tester.pumpAndSettle();
    expect(
      find.text('Search documents, topics, or content...'),
      findsOneWidget,
    );
  });

  testWidgets('Documents tab shows all documents from the API', (tester) async {
    final many = List.generate(
      6,
      (i) => {
        'id': 'doc-$i',
        'name': 'Report $i.pdf',
        'status': 'completed',
        'pageNum': 3,
        'retrievalReady': true,
      },
    );
    await _pumpHome(tester, documents: many);
    await tester.tap(find.byKey(const ValueKey('home-section-Documents')));
    await tester.pumpAndSettle();

    expect(find.byType(DocumentListItem), findsNWidgets(6));
    expect(find.text('Report 5.pdf'), findsOneWidget);
  });

  testWidgets('home Documents tab shows the full document list', (
    tester,
  ) async {
    final documents = List.generate(
      5,
      (i) => {
        'id': 'doc-$i',
        'name': 'Report $i.pdf',
        'status': 'completed',
        'pageNum': 3,
        'retrievalReady': true,
      },
    );
    await _pumpHome(tester, documents: documents);

    await tester.tap(find.byKey(const ValueKey('home-section-Documents')));
    await tester.pumpAndSettle();

    expect(find.text('Your documents'), findsOneWidget);
    expect(find.text('Documents'), findsWidgets);
    expect(find.text('Report 4.pdf'), findsOneWidget);
  });

  testWidgets('home search filters the document list', (tester) async {
    final docs = [
      {
        'id': 'doc-1',
        'name': 'Annual Report.pdf',
        'status': 'completed',
        'pageNum': 12,
        'retrievalReady': true,
      },
      {
        'id': 'doc-2',
        'name': 'Resume.pdf',
        'status': 'completed',
        'pageNum': 2,
        'retrievalReady': true,
      },
    ];
    await _pumpHome(tester, documents: docs);

    await tester.tap(find.byKey(const ValueKey('home-section-Documents')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'resume');
    await tester.pumpAndSettle();

    expect(find.text('Resume.pdf'), findsOneWidget);
    expect(find.text('Annual Report.pdf'), findsNothing);
  });

  testWidgets('an analyzed document shows a single non-contradictory status', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home-section-Documents')));
    await tester.pumpAndSettle();
    expect(find.text('Analyzed 2h ago'), findsOneWidget);
    expect(find.text('Ready for analysis'), findsNothing);
  });

  testWidgets('home shows an empty state when the API has no documents', (
    tester,
  ) async {
    await tester.pumpWidget(AskDocsApp(api: _fakeApi(documents: [])));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-section-Documents')));
    await tester.pumpAndSettle();
    expect(find.textContaining('No documents yet'), findsOneWidget);
  });

  testWidgets('home sidebar opens navigation actions', (tester) async {
    await tester.pumpWidget(AskDocsApp(api: _fakeApi()));
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.byType(SidebarIcon), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsNothing);
    expect(find.byTooltip('Upload a document'), findsOneWidget);

    await tester.tap(find.byTooltip('Open sidebar'));
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsOneWidget);
    expect(find.text('New chat'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Documents'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'New chat'));
    await tester.pumpAndSettle();
    expect(find.text('Choose documents for chat'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(CheckboxListTile, 'Annual Report.pdf'),
    );
    await tester.tap(find.text('Use selected documents'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
  });

  testWidgets('top bar upload option opens document upload', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byTooltip('Upload a document'));
    await tester.pumpAndSettle();

    expect(find.byType(UploadScreen), findsOneWidget);
    expect(find.text('Add a document'), findsOneWidget);
  });

  testWidgets('chat home requires document selection before sending', (
    tester,
  ) async {
    List<dynamic>? createdWithDocumentIds;
    String? sentMessage;
    final documents = [
      {
        'id': 'doc-1',
        'name': 'Annual Report.pdf',
        'status': 'completed',
        'pageNum': 12,
        'retrievalReady': true,
      },
      {
        'id': 'doc-2',
        'name': 'Resume.pdf',
        'status': 'completed',
        'pageNum': 2,
        'retrievalReady': true,
      },
    ];
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      AskDocsApp(
        api: _fakeApi(
          documents: documents,
          onSessionCreated: (documentIds) =>
              createdWithDocumentIds = documentIds,
          onMessageSent: (message) => sentMessage = message,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Drawer), findsNothing);
    expect(find.byTooltip('Open sidebar'), findsOneWidget);
    expect(find.byTooltip('Documents'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('home-choose-documents')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckboxListTile, 'Annual Report.pdf'),
    );
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Resume.pdf'));
    await tester.tap(find.text('Use selected documents'));
    await tester.pumpAndSettle();

    expect(find.text('2 documents selected'), findsOneWidget);
    expect(find.text('Annual Report.pdf, Resume.pdf'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Compare these files');
    await tester.tap(find.bySemanticsLabel('Send message'));
    await tester.pumpAndSettle();

    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Compare these files'), findsOneWidget);
    expect(createdWithDocumentIds, ['doc-1', 'doc-2']);
    expect(sentMessage, 'Compare these files');
  });

  testWidgets('chat answers come from the API with citations', (tester) async {
    await tester.pumpWidget(AskDocsApp(api: _fakeApi()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-section-Documents')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annual Report.pdf'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);

    await tester.tap(find.text('What are the key points?'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Revenue grew 12%.'), findsOneWidget);
    expect(find.textContaining('<cite'), findsNothing);
    expect(find.text('Page 4'), findsOneWidget);

    await tester.tap(find.text('Page 4'));
    await tester.pumpAndSettle();
    expect(find.text('Source details'), findsOneWidget);
    expect(find.text('Page 4 · Lines 1–3'), findsOneWidget);
    expect(
      find.text('Revenue increased by 12% year over year.'),
      findsOneWidget,
    );
  });

  testWidgets('chat can add another available document to its context', (
    tester,
  ) async {
    final documents = [
      {
        'id': 'doc-1',
        'name': 'Annual Report.pdf',
        'status': 'completed',
        'pageNum': 12,
        'retrievalReady': true,
      },
      {
        'id': 'doc-2',
        'name': 'Resume.pdf',
        'status': 'completed',
        'pageNum': 2,
        'retrievalReady': true,
      },
    ];
    await _pumpHome(tester, documents: documents);
    await tester.tap(find.byKey(const ValueKey('home-section-Documents')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annual Report.pdf').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('What are the key points?'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose documents'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Resume.pdf'));
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('2 documents selected'), findsOneWidget);
    expect(find.text('Could not update chat documents'), findsNothing);
  });
}
