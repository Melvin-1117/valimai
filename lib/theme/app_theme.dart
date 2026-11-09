import 'package:flutter/material.dart';

class ValimaiColors {
  ValimaiColors._();

  static const Color background = Color(0xFF101012); // Deep Black
  static const Color surface = Color(0xFF25252B); // Charcoal
  static const Color surfaceDim = Color(0xFF101012);
  static const Color surfaceBright = Color(0xFF35353D);
  static const Color surfaceContainerLowest = Color(0xFF0A0A0C);
  static const Color surfaceContainerLow = Color(0xFF1A1A1E);
  static const Color surfaceContainer = Color(0xFF25252B);
  static const Color surfaceContainerHigh = Color(0xFF303038);
  static const Color surfaceContainerHighest = Color(0xFF383842);

  static const Color primary = Color(0xFFF02D36); // Bright Red
  static const Color primaryContainer = Color(0xFFF02D36); // Bright Red Accent
  static const Color kineticRed = Color(0xFFF02D36);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);

  static const Color secondary = Color(0xFFA4A4AA); // Cool Grey
  static const Color secondaryLight = Color(0xFFC8C5CD);
  static const Color secondaryContainer = Color(0xFF3A3A42);
  static const Color onSecondary = Color(0xFF101012);
  static const Color onSecondaryContainer = Color(0xFFE2E2E8);

  static const Color tertiary = Color(0xFFFFB3B2);
  static const Color tertiaryContainer = Color(0xFFF95961);

  static const Color onSurface = Color(0xFFFFFFFF); // Primary text: White
  static const Color onSurfaceVariant = Color(0xFFE6BDB9);
  static const Color outline = Color(0xFFAD8885);
  static const Color outlineVariant = Color(0xFF5D3F3D);

  static const Color cardBorder = Color(
    0x14FFFFFF,
  ); // 1px solid rgba(255, 255, 255, 0.08)
  static const Color activeBorder = Color(
    0x59F02D36,
  ); // rgba(240, 45, 54, 0.35)
}

class ValimaiTheme {
  ValimaiTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ValimaiColors.background,
      colorScheme: const ColorScheme.dark(
        surface: ValimaiColors.surface,
        onSurface: ValimaiColors.onSurface,
        primary: ValimaiColors.primary,
        onPrimary: ValimaiColors.onPrimary,
        primaryContainer: ValimaiColors.primaryContainer,
        onPrimaryContainer: ValimaiColors.onPrimaryContainer,
        secondary: ValimaiColors.secondaryLight,
        onSecondary: ValimaiColors.onSecondary,
        secondaryContainer: ValimaiColors.secondaryContainer,
        onSecondaryContainer: ValimaiColors.onSecondaryContainer,
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
      ),
      fontFamily: 'Montserrat',
      fontFamilyFallback: const ['sans-serif'],
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 56,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.03,
          color: ValimaiColors.onSurface,
          height: 1.08,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
          color: ValimaiColors.onSurface,
          height: 1.18,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.015,
          color: ValimaiColors.onSurface,
          height: 1.25,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.01,
          color: ValimaiColors.onSurface,
          height: 1.33,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: ValimaiColors.onSurface,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: ValimaiColors.secondary,
          height: 1.42,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.01,
          color: ValimaiColors.secondary,
          height: 1.33,
        ),
        labelLarge: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.01,
          color: ValimaiColors.onSurface,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.88,
          color: ValimaiColors.secondary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ValimaiColors.cardBorder,
        thickness: 1,
      ),
    );
  }
}
