import 'package:flutter/material.dart';

class AppTheme {
  static const _seedColor = Color(0xFF5B5BD6);

  static ThemeData lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      dividerColor: const Color(0xFFD8DCE8),
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withOpacity(0.18),
        selectionHandleColor: colorScheme.primary,
      ),
      extensions: [
        AppThemeColors(
          overlayScrim: Colors.black.withOpacity(0.08),
          infoPanelBackground: Colors.white.withOpacity(0.92),
          secondaryInfoBackground: const Color(0xFFF1F4FB),
          accent: colorScheme.primary,
          accentSoft: colorScheme.primary.withOpacity(0.12),
          accentForeground: colorScheme.primary,
          warningText: const Color(0xFFB45309),
          errorBackground: const Color(0xFFFDECEC),
          errorBorder: const Color(0xFFF4B8B8),
          errorForeground: const Color(0xFFB42318),
          tagLottie: const Color(0xFFD7E8FF),
          tagSvga: const Color(0xFFE9DDFF),
          tagForeground: const Color(0xFF1F2937),
          dragHandleBackground: const Color(0xFFE4E7F0),
          dragHandleForeground: const Color(0xFF667085),
        ),
      ],
    );
  }

  static ThemeData darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF171A22),
      dividerColor: const Color(0xFF313645),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF1E2230),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withOpacity(0.28),
        selectionHandleColor: colorScheme.primary,
      ),
      extensions: [
        AppThemeColors(
          overlayScrim: Colors.black.withOpacity(0.7),
          infoPanelBackground: Colors.black.withOpacity(0.45),
          secondaryInfoBackground: const Color(0xFF262B3A),
          accent: const Color(0xFFB6A8FF),
          accentSoft: const Color(0xFFB6A8FF).withOpacity(0.14),
          accentForeground: const Color(0xFFB6A8FF),
          warningText: const Color(0xFFFDBA74),
          errorBackground: const Color(0xFF5A1D24).withOpacity(0.55),
          errorBorder: const Color(0xFFEF6F7E),
          errorForeground: const Color(0xFFFFB4AB),
          tagLottie: const Color(0xFF153E75),
          tagSvga: const Color(0xFF4A236B),
          tagForeground: Colors.white,
          dragHandleBackground: const Color(0xFF3A4152),
          dragHandleForeground: const Color(0xFFA0AEC0),
        ),
      ],
    );
  }
}

class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color overlayScrim;
  final Color infoPanelBackground;
  final Color secondaryInfoBackground;
  final Color accent;
  final Color accentSoft;
  final Color accentForeground;
  final Color warningText;
  final Color errorBackground;
  final Color errorBorder;
  final Color errorForeground;
  final Color tagLottie;
  final Color tagSvga;
  final Color tagForeground;
  final Color dragHandleBackground;
  final Color dragHandleForeground;

  const AppThemeColors({
    required this.overlayScrim,
    required this.infoPanelBackground,
    required this.secondaryInfoBackground,
    required this.accent,
    required this.accentSoft,
    required this.accentForeground,
    required this.warningText,
    required this.errorBackground,
    required this.errorBorder,
    required this.errorForeground,
    required this.tagLottie,
    required this.tagSvga,
    required this.tagForeground,
    required this.dragHandleBackground,
    required this.dragHandleForeground,
  });

  @override
  AppThemeColors copyWith({
    Color? overlayScrim,
    Color? infoPanelBackground,
    Color? secondaryInfoBackground,
    Color? accent,
    Color? accentSoft,
    Color? accentForeground,
    Color? warningText,
    Color? errorBackground,
    Color? errorBorder,
    Color? errorForeground,
    Color? tagLottie,
    Color? tagSvga,
    Color? tagForeground,
    Color? dragHandleBackground,
    Color? dragHandleForeground,
  }) {
    return AppThemeColors(
      overlayScrim: overlayScrim ?? this.overlayScrim,
      infoPanelBackground: infoPanelBackground ?? this.infoPanelBackground,
      secondaryInfoBackground:
          secondaryInfoBackground ?? this.secondaryInfoBackground,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      accentForeground: accentForeground ?? this.accentForeground,
      warningText: warningText ?? this.warningText,
      errorBackground: errorBackground ?? this.errorBackground,
      errorBorder: errorBorder ?? this.errorBorder,
      errorForeground: errorForeground ?? this.errorForeground,
      tagLottie: tagLottie ?? this.tagLottie,
      tagSvga: tagSvga ?? this.tagSvga,
      tagForeground: tagForeground ?? this.tagForeground,
      dragHandleBackground:
          dragHandleBackground ?? this.dragHandleBackground,
      dragHandleForeground:
          dragHandleForeground ?? this.dragHandleForeground,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      overlayScrim: Color.lerp(overlayScrim, other.overlayScrim, t)!,
      infoPanelBackground:
          Color.lerp(infoPanelBackground, other.infoPanelBackground, t)!,
      secondaryInfoBackground: Color.lerp(
        secondaryInfoBackground,
        other.secondaryInfoBackground,
        t,
      )!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentForeground:
          Color.lerp(accentForeground, other.accentForeground, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      errorBackground:
          Color.lerp(errorBackground, other.errorBackground, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      errorForeground:
          Color.lerp(errorForeground, other.errorForeground, t)!,
      tagLottie: Color.lerp(tagLottie, other.tagLottie, t)!,
      tagSvga: Color.lerp(tagSvga, other.tagSvga, t)!,
      tagForeground: Color.lerp(tagForeground, other.tagForeground, t)!,
      dragHandleBackground:
          Color.lerp(dragHandleBackground, other.dragHandleBackground, t)!,
      dragHandleForeground:
          Color.lerp(dragHandleForeground, other.dragHandleForeground, t)!,
    );
  }
}

extension AppThemeBuildContextX on BuildContext {
  AppThemeColors get appThemeColors =>
      Theme.of(this).extension<AppThemeColors>()!;
}
