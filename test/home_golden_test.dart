import 'dart:convert';

import 'package:documentintelligence/app.dart';
import 'package:documentintelligence/data/api/document_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Renders the Home screen and writes a golden PNG so the layout can be
/// inspected visually. Run with:
///   flutter test --update-goldens test/home_golden_test.dart
void main() {
  testWidgets('home layout golden', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();
    final docs = [
      {
        'id': 'doc-1',
        'name': 'SBI Card Statement.pdf',
        'status': 'completed',
        'pageNum': 7,
        'retrievalReady': true,
        'sizeBytes': 2516582,
        'lastAnalyzed': now
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      },
      {
        'id': 'doc-2',
        'name': 'Resume.pdf',
        'status': 'completed',
        'pageNum': 2,
        'retrievalReady': true,
        'lastAnalyzed': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 'doc-3',
        'name': 'Product Classification under Regulatory Aspirations.pdf',
        'status': 'completed',
        'pageNum': 18,
        'retrievalReady': false,
      },
      {
        'id': 'doc-4',
        'name': 'cb23eabc-0726-40fd-8a54-28c440fdadd3.pdf',
        'status': 'processing',
        'pageNum': 4,
        'retrievalReady': false,
      },
    ];

    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/documents') {
        return http.Response(
          jsonEncode({'documents': docs}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      AskDocsApp(api: DocumentApi(client: client, validateConfig: false)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });

  testWidgets('home layout golden — side-by-side actions and dark mode', (
    tester,
  ) async {
    // A tablet-width viewport forces the quick actions into their side-by-side
    // branch, and dark mode catches contrast problems.
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 2.0;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    final docs = [
      {
        'id': 'doc-1',
        'name': 'SBI Card Statement.pdf',
        'status': 'completed',
        'pageNum': 7,
        'retrievalReady': true,
        'sizeBytes': 2516582,
        'lastAnalyzed': DateTime.now()
            .subtract(const Duration(hours: 2))
            .toIso8601String(),
      },
      {
        'id': 'doc-2',
        'name': 'cb23eabc-0726-40fd-8a54-28c440fdadd3.pdf',
        'status': 'processing',
        'pageNum': 4,
        'retrievalReady': false,
      },
    ];

    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path == '/documents') {
        return http.Response(
          jsonEncode({'documents': docs}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      AskDocsApp(api: DocumentApi(client: client, validateConfig: false)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_wide_dark.png'),
    );
  });
}
