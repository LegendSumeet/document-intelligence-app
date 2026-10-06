import 'package:flutter/material.dart';

import 'data/api/document_api.dart';
import 'screens/home/home_screen.dart';
import 'theme/app_theme.dart';

/// AskDocs — ask anything about your documents.
///
/// The app launches directly into Home. Theme follows the system setting.
class AskDocsApp extends StatelessWidget {
  const AskDocsApp({super.key, this.api});

  /// Overrides the backend client; used by tests.
  final DocumentApi? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AskDocs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: HomeScreen(api: api),
    );
  }
}
