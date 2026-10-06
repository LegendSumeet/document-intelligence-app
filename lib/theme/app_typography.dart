import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AskDocs type scale.
///
/// One font family (Inter) with a deliberately small, consistent set of sizes.
/// Letter-spacing tightens as size grows, which is what makes large headings
/// feel intentional rather than merely big.
abstract final class AppTypography {
  static TextTheme textTheme(Color bodyColor, Color mutedColor) {
    final base = GoogleFonts.interTextTheme();

    return base
        .copyWith(
          // Display / large heading
          displaySmall: base.displaySmall?.copyWith(
            fontSize: 34,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.0,
          ),
          // Main heading
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize: 26,
            height: 1.2,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 21,
            height: 1.25,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          // Section heading
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 18,
            height: 1.3,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 15.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 14,
            height: 1.35,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          // Body
          bodyLarge: base.bodyLarge?.copyWith(
            fontSize: 15.5,
            height: 1.55,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.5,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.05,
          ),
          // Caption
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 12.5,
            height: 1.45,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
          // Label
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 14.5,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 12.5,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontSize: 11.5,
            height: 1.2,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        )
        .apply(bodyColor: bodyColor, displayColor: bodyColor)
        // Muted roles are applied where the design wants secondary text.
        .copyWith(
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 12.5,
            height: 1.45,
            color: mutedColor,
            letterSpacing: 0,
          ),
        );
  }
}
