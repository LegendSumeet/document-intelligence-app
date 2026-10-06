import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:documentintelligence/screens/auth/google_sign_in_screen.dart';
import 'package:documentintelligence/screens/home/home_screen.dart';
import 'data/api/document_api.dart';
import 'theme/app_theme.dart';

/// AskDocs — ask anything about your documents.
///
/// The app checks authentication state and navigates to the appropriate screen.
class AskDocsApp extends StatelessWidget {
  const AskDocsApp({super.key, this.api});

  /// Overrides the backend client; used by tests.
  final DocumentApi? api;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MaterialApp(
            title: 'AskDocs',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            home: const HomeScreen(),
          );
        } else {
          return MaterialApp(
            title: 'AskDocs',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            home: const GoogleSignInScreen(),
          );
        }
      });
  }
}
