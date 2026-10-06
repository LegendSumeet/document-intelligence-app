import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds the light and dark [ThemeData] for the application from a shared
/// Material 3 [ColorScheme].
class AppTheme {
  AppTheme._();

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF6366F1),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE0E7FF),
    onPrimaryContainer: Color(0xFF1E1B4B),
    secondary: Color(0xFF0891B2),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCFFAFE),
    onSecondaryContainer: Color(0xFF164E63),
    tertiary: Color(0xFFA855F7),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFF3E8FF),
    onTertiaryContainer: Color(0xFF581C87),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFBFBFA),
    onSurface: Color(0xFF111827),
    onSurfaceVariant: Color(0xFF4B5563),
    outline: Color(0xFF6B7280),
    outlineVariant: Color(0xFFE9E9E7),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF24262D),
    onInverseSurface: Color(0xFFF3F4F6),
    inversePrimary: Color(0xFF818CF8),
    surfaceTint: Color(0xFF6366F1),
    surfaceDim: Color(0xFFE7E7E5),
    surfaceBright: Color(0xFFFBFBFA),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF4F4F3),
    surfaceContainer: Color(0xFFEFEFED),
    surfaceContainerHigh: Color(0xFFEAEAE8),
    surfaceContainerHighest: Color(0xFFE3E4E2),
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF818CF8),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFF3730A3),
    onPrimaryContainer: Color(0xFFE0E7FF),
    secondary: Color(0xFF22D3EE),
    onSecondary: Color(0xFF003640),
    secondaryContainer: Color(0xFF155E75),
    onSecondaryContainer: Color(0xFFCFFAFE),
    tertiary: Color(0xFFC084FC),
    onTertiary: Color(0xFF2C0051),
    tertiaryContainer: Color(0xFF6B21A8),
    onTertiaryContainer: Color(0xFFF3E8FF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF121316),
    onSurface: Color(0xFFF3F4F6),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFF6B7280),
    outlineVariant: Color(0xFF282A30),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF3F4F6),
    onInverseSurface: Color(0xFF24262D),
    inversePrimary: Color(0xFF4F46E5),
    surfaceTint: Color(0xFF6366F1),
    surfaceDim: Color(0xFF121316),
    surfaceBright: Color(0xFF38393C),
    surfaceContainerLowest: Color(0xFF0D0E11),
    surfaceContainerLow: Color(0xFF1C1D22),
    surfaceContainer: Color(0xFF1F2025),
    surfaceContainerHigh: Color(0xFF24262D),
    surfaceContainerHighest: Color(0xFF34363C),
  );

  static ThemeData light() => _build(lightScheme);
  static ThemeData dark() => _build(darkScheme);

  static ThemeData _build(ColorScheme colors) {
    final fallback = ThemeData(brightness: colors.brightness).textTheme;
    final body = GoogleFonts.interTextTheme(fallback);
    final display = GoogleFonts.interTextTheme(fallback);
    final textTheme = display
        .copyWith(
          bodyLarge: body.bodyLarge,
          bodyMedium: body.bodyMedium,
          bodySmall: body.bodySmall,
          labelLarge: body.labelLarge,
          labelMedium: body.labelMedium,
          labelSmall: body.labelSmall,
        )
        .apply(bodyColor: colors.onSurface, displayColor: colors.onSurface);
    final monoLabels = textTheme.copyWith(
      labelLarge: GoogleFonts.jetBrainsMono(textStyle: textTheme.labelLarge),
      labelMedium: GoogleFonts.jetBrainsMono(textStyle: textTheme.labelMedium),
      labelSmall: GoogleFonts.jetBrainsMono(textStyle: textTheme.labelSmall),
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      textTheme: monoLabels,
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface.withValues(alpha: 0.96),
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        shape: Border(bottom: BorderSide(color: colors.outlineVariant)),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: const StadiumBorder(),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.surfaceContainerHigh,
        side: BorderSide(color: colors.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
    );
  }
}
