import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Semantic colors that Material's [ColorScheme] does not define
/// (success / warning / brand accents), resolved per brightness.
@immutable
class AskDocsTokens extends ThemeExtension<AskDocsTokens> {
  const AskDocsTokens({
    required this.positive,
    required this.positiveSoft,
    required this.caution,
    required this.cautionSoft,
    required this.critical,
    required this.criticalSoft,
    required this.accentSoft,
    required this.hairline,
    required this.raised,
  });

  final Color positive;
  final Color positiveSoft;
  final Color caution;
  final Color cautionSoft;
  final Color critical;
  final Color criticalSoft;

  /// Faint purple wash used behind AI surfaces.
  final Color accentSoft;

  /// The subtle 1px border color.
  final Color hairline;

  /// Elevated surface sitting above the background.
  final Color raised;

  static const light = AskDocsTokens(
    positive: AppColors.green,
    positiveSoft: AppColors.greenSoft,
    caution: AppColors.amber,
    cautionSoft: AppColors.amberSoft,
    critical: AppColors.red,
    criticalSoft: AppColors.redSoft,
    accentSoft: AppColors.purple50,
    hairline: AppColors.slate200,
    raised: AppColors.paperSurface,
  );

  static const dark = AskDocsTokens(
    positive: Color(0xFF4ADE80),
    positiveSoft: Color(0xFF14311F),
    caution: Color(0xFFFBBF24),
    cautionSoft: Color(0xFF3A2C0C),
    critical: Color(0xFFF87171),
    criticalSoft: Color(0xFF3A1616),
    accentSoft: Color(0xFF221B3A),
    hairline: Color(0xFF2C2C34),
    raised: AppColors.inkRaised,
  );

  @override
  AskDocsTokens copyWith({
    Color? positive,
    Color? positiveSoft,
    Color? caution,
    Color? cautionSoft,
    Color? critical,
    Color? criticalSoft,
    Color? accentSoft,
    Color? hairline,
    Color? raised,
  }) {
    return AskDocsTokens(
      positive: positive ?? this.positive,
      positiveSoft: positiveSoft ?? this.positiveSoft,
      caution: caution ?? this.caution,
      cautionSoft: cautionSoft ?? this.cautionSoft,
      critical: critical ?? this.critical,
      criticalSoft: criticalSoft ?? this.criticalSoft,
      accentSoft: accentSoft ?? this.accentSoft,
      hairline: hairline ?? this.hairline,
      raised: raised ?? this.raised,
    );
  }

  @override
  AskDocsTokens lerp(ThemeExtension<AskDocsTokens>? other, double t) {
    if (other is! AskDocsTokens) return this;
    return AskDocsTokens(
      positive: Color.lerp(positive, other.positive, t)!,
      positiveSoft: Color.lerp(positiveSoft, other.positiveSoft, t)!,
      caution: Color.lerp(caution, other.caution, t)!,
      cautionSoft: Color.lerp(cautionSoft, other.cautionSoft, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      criticalSoft: Color.lerp(criticalSoft, other.criticalSoft, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
    );
  }
}

/// Ergonomic access to [AskDocsTokens] from a [BuildContext].
extension AskDocsTokensX on BuildContext {
  AskDocsTokens get tokens =>
      Theme.of(this).extension<AskDocsTokens>() ?? AskDocsTokens.light;
}

/// Builds the AskDocs light and dark themes.
abstract final class AppTheme {
  static const lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.purple600,
    onPrimary: Colors.white,
    primaryContainer: AppColors.purple100,
    onPrimaryContainer: AppColors.purple900,
    secondary: AppColors.purple500,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.purple50,
    onSecondaryContainer: AppColors.purple800,
    tertiary: AppColors.slate700,
    onTertiary: Colors.white,
    tertiaryContainer: AppColors.slate100,
    onTertiaryContainer: AppColors.slate900,
    error: AppColors.red,
    onError: Colors.white,
    errorContainer: AppColors.redSoft,
    onErrorContainer: Color(0xFF7F1D1D),
    surface: AppColors.paper,
    onSurface: AppColors.slate900,
    onSurfaceVariant: AppColors.slate500,
    outline: AppColors.slate400,
    outlineVariant: AppColors.slate200,
    shadow: Color(0x1A000000),
    scrim: Color(0x66000000),
    inverseSurface: AppColors.slate900,
    onInverseSurface: AppColors.paper,
    inversePrimary: AppColors.purple300,
    surfaceTint: AppColors.purple600,
    surfaceContainerLowest: AppColors.paperSurface,
    surfaceContainerLow: AppColors.paperSurface,
    surfaceContainer: AppColors.slate100,
    surfaceContainerHigh: AppColors.slate100,
    surfaceContainerHighest: AppColors.slate100,
  );

  static const darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.purple400,
    onPrimary: Color(0xFF1B0F3B),
    primaryContainer: Color(0xFF37236B),
    onPrimaryContainer: AppColors.purple100,
    secondary: AppColors.purple300,
    onSecondary: Color(0xFF1B0F3B),
    secondaryContainer: Color(0xFF2A1E4D),
    onSecondaryContainer: AppColors.purple100,
    tertiary: AppColors.slate300,
    onTertiary: AppColors.ink,
    tertiaryContainer: AppColors.inkRaised,
    onTertiaryContainer: AppColors.paper,
    error: Color(0xFFF87171),
    onError: Color(0xFF2A0A0A),
    errorContainer: Color(0xFF3A1616),
    onErrorContainer: Color(0xFFFECACA),
    surface: AppColors.ink,
    onSurface: Color(0xFFF4F4F6),
    onSurfaceVariant: AppColors.slate400,
    outline: Color(0xFF4B4B55),
    outlineVariant: Color(0xFF2C2C34),
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
    inverseSurface: Color(0xFFF4F4F6),
    onInverseSurface: AppColors.ink,
    inversePrimary: AppColors.purple600,
    surfaceTint: AppColors.purple400,
    surfaceContainerLowest: AppColors.ink,
    surfaceContainerLow: AppColors.inkSurface,
    surfaceContainer: AppColors.inkSurface,
    surfaceContainerHigh: AppColors.inkRaised,
    surfaceContainerHighest: AppColors.inkRaised,
  );

  static ThemeData light() => _build(lightScheme, AskDocsTokens.light);
  static ThemeData dark() => _build(darkScheme, AskDocsTokens.dark);

  static ThemeData _build(ColorScheme colors, AskDocsTokens tokens) {
    final textTheme = AppTypography.textTheme(
      colors.onSurface,
      colors.onSurfaceVariant,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: colors.brightness,
      colorScheme: colors,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
      splashFactory: InkSparkle.splashFactory,
    );

    final hairline = BorderSide(color: tokens.hairline);

    return base.copyWith(
      extensions: [tokens],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 60,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colors.onSurface),
      ),
      cardTheme: CardThemeData(
        color: tokens.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: hairline,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        isDense: true,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onSurfaceVariant,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: hairline,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: hairline,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          textStyle: textTheme.labelLarge,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          foregroundColor: colors.onSurface,
          textStyle: textTheme.labelLarge,
          side: hairline,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: colors.surfaceContainer,
        side: hairline,
        labelStyle: textTheme.labelMedium?.copyWith(color: colors.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      dividerTheme: DividerThemeData(
        color: tokens.hairline,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 350),
        textStyle: textTheme.labelMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        decoration: BoxDecoration(
          color: colors.inverseSurface,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.raised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: tokens.raised,
        showDragHandle: true,
        dragHandleColor: colors.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        linearTrackColor: colors.surfaceContainerHigh,
        linearMinHeight: 4,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thickness: const WidgetStatePropertyAll(5),
        radius: const Radius.circular(3),
        thumbColor: WidgetStatePropertyAll(
          colors.outline.withValues(alpha: 0.45),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
