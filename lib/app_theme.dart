import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF176B5B),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFBCECDF),
    onPrimaryContainer: Color(0xFF00201A),
    secondary: Color(0xFF4C635D),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCFE9E1),
    onSecondaryContainer: Color(0xFF09201B),
    tertiary: Color(0xFF8C4B2F),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFFDBCD),
    onTertiaryContainer: Color(0xFF351000),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: Color(0xFFFAFAF7),
    onSurface: Color(0xFF181C1A),
    onSurfaceVariant: Color(0xFF414946),
    outline: Color(0xFF717975),
    outlineVariant: Color(0xFFC1C9C5),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF2D312F),
    onInverseSurface: Color(0xFFEFF1EE),
    inversePrimary: Color(0xFFA0D0C4),
    surfaceTint: Color(0xFF176B5B),
    surfaceDim: Color(0xFFDADBD8),
    surfaceBright: Color(0xFFFAFAF7),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF4F5F2),
    surfaceContainer: Color(0xFFEEEFEA),
    surfaceContainerHigh: Color(0xFFE8E9E5),
    surfaceContainerHighest: Color(0xFFE2E3DF),
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA0D0C4),
    onPrimary: Color(0xFF00382F),
    primaryContainer: Color(0xFF005143),
    onPrimaryContainer: Color(0xFFBCECDF),
    secondary: Color(0xFFB3CCC4),
    onSecondary: Color(0xFF1F352F),
    secondaryContainer: Color(0xFF354B45),
    onSecondaryContainer: Color(0xFFCFE9E1),
    tertiary: Color(0xFFFFB69A),
    onTertiary: Color(0xFF55200B),
    tertiaryContainer: Color(0xFF71351B),
    onTertiaryContainer: Color(0xFFFFDBCD),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF101412),
    onSurface: Color(0xFFE1E3DF),
    onSurfaceVariant: Color(0xFFC1C9C5),
    outline: Color(0xFF8B938F),
    outlineVariant: Color(0xFF414946),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFE1E3DF),
    onInverseSurface: Color(0xFF2D312F),
    inversePrimary: Color(0xFF176B5B),
    surfaceTint: Color(0xFFA0D0C4),
    surfaceDim: Color(0xFF101412),
    surfaceBright: Color(0xFF363A38),
    surfaceContainerLowest: Color(0xFF0B0F0D),
    surfaceContainerLow: Color(0xFF181C1A),
    surfaceContainer: Color(0xFF1C201E),
    surfaceContainerHigh: Color(0xFF272B29),
    surfaceContainerHighest: Color(0xFF323633),
  );

  static ThemeData light() => _build(lightScheme);
  static ThemeData dark() => _build(darkScheme);

  static ThemeData _build(ColorScheme colors) {
    final fallback = ThemeData(brightness: colors.brightness).textTheme;
    final body = GoogleFonts.aBeeZeeTextTheme(fallback);
    final display = GoogleFonts.arOneSansTextTheme(fallback);
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

    final base = ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary),
    );
  }
}
