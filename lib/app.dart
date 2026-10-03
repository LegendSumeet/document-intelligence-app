import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/library/document_selection_page.dart';

/// Root widget: wires up theming and the initial route.
class DocumentIntelligenceApp extends StatelessWidget {
  const DocumentIntelligenceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Intelligence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const DocumentSelectionPage(),
    );
  }
}
