import 'package:flutter/material.dart';

/// AskDocs brand palette.
///
/// Purple is the brand accent and is used deliberately: primary actions,
/// selected/active states, AI surfaces, and progress. Everything else is a
/// neutral scale so purple always reads as meaningful.
abstract final class AppColors {
  // ---- Brand purple (sampled from the AskDocs panda background) -------------
  static const purple50 = Color(0xFFF5F3FF);
  static const purple100 = Color(0xFFEDE9FE);
  static const purple200 = Color(0xFFDDD6FE);
  static const purple300 = Color(0xFFC4B5FD);
  static const purple400 = Color(0xFFA78BFA);
  static const purple500 = Color(0xFF8B5CF6); // primary brand
  static const purple600 = Color(0xFF7C3AED);
  static const purple700 = Color(0xFF6D28D9);
  static const purple800 = Color(0xFF5B21B6);
  static const purple900 = Color(0xFF3F1D82);

  // ---- Neutrals ------------------------------------------------------------
  static const ink = Color(0xFF16161B); // near-black background (dark)
  static const inkSurface = Color(0xFF1E1E24);
  static const inkRaised = Color(0xFF26262E);

  static const paper = Color(0xFFFAFAFB); // off-white background (light)
  static const paperSurface = Color(0xFFFFFFFF);

  static const slate900 = Color(0xFF16181D); // deep charcoal text
  static const slate700 = Color(0xFF3F434C);
  static const slate500 = Color(0xFF6B7280); // gray secondary text
  static const slate400 = Color(0xFF9CA3AF);
  static const slate300 = Color(0xFFD1D5DB);
  static const slate200 = Color(0xFFE5E7EB); // subtle borders
  static const slate100 = Color(0xFFF1F2F4);

  // ---- Feedback ------------------------------------------------------------
  static const green = Color(0xFF16A34A);
  static const greenSoft = Color(0xFFDCFCE7);
  static const amber = Color(0xFFD97706);
  static const amberSoft = Color(0xFFFEF3C7);
  static const red = Color(0xFFDC2626);
  static const redSoft = Color(0xFFFEE2E2);

  // ---- Document type accents ----------------------------------------------
  static const pdfAccent = Color(0xFFE5484D);
  static const docxAccent = Color(0xFF2563EB);
  static const txtAccent = Color(0xFF64748B);
  static const imageAccent = Color(0xFF0D9488);
}
