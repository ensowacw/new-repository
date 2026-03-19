import 'package:flutter/material.dart';

class AppTheme {
  // ── Colors（Apple Human Interface Guidelines ベース）────
  static const Color bg = Colors.white;
  static const Color bgSecondary = Color(0xFFF2F2F7); // iOS systemGroupedBackground
  static const Color surface = Colors.white;
  static const Color onSurface = Color(0xFF1C1C1E); // iOS label
  static const Color secondary = Color(0xFF3C3C43);  // iOS secondaryLabel (60% opacity)
  static const Color subtle = Color(0xFF8E8E93);      // iOS tertiaryLabel
  static const Color divider = Color(0xFFE5E5EA);     // iOS separator
  static const Color accent = Color(0xFF1C1C1E);      // Black — Apple style
  static const Color accentGreen = Color(0xFF34C759); // iOS green
  static const Color danger = Color(0xFFB5302A);      // deep muted red — not flashy
  static const Color dangerLight = Color(0xFFF7EFEF);
  static const Color accentLight = Color(0xFFF2F2F7);

  // ── TextStyles ────────────────────────────────────────
  // 数字メイン表示（超大）
  static const TextStyle heroNumber = TextStyle(
    fontSize: 58,
    fontWeight: FontWeight.w200,
    letterSpacing: -1.5,
    color: onSurface,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // 時間表示
  static const TextStyle timerDisplay = TextStyle(
    fontSize: 38,
    fontWeight: FontWeight.w300,
    letterSpacing: 2,
    color: subtle,
    height: 1.0,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // セクションラベル
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
    color: subtle,
    height: 1.0,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: onSurface,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: onSurface,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: subtle,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: subtle,
    letterSpacing: 0.2,
  );

  // ── ThemeData ─────────────────────────────────────────
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: '.SF Pro Display',
        scaffoldBackgroundColor: bg,
        colorScheme: const ColorScheme.light(
          primary: onSurface,
          surface: surface,
          onSurface: onSurface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg,
          foregroundColor: onSurface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: onSurface,
            letterSpacing: -0.4,
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: divider,
          thickness: 0.5,
          space: 0,
        ),
        cardTheme: CardThemeData(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: divider, width: 0.5),
          ),
        ),
      );
}
