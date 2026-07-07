import 'package:flutter/material.dart';

/// Zone color palette.
///
/// Warm off-white/grey base with a single terracotta accent for primary
/// actions. Blue is reserved only for the "you are here" location dot.
/// Change values here to retheme the whole app — nothing else hardcodes
/// these hues.
class ZoneColors {
  static const primary = Color(0xFFD38A66); // Terracotta — primary actions
  static const primaryDark = Color(0xFFB06B49);
  static const accent = primary;

  static const locationDot = Color(0xFF5E8FD0); // Blue — location dot only

  static const background = Color(0xFFF4F2EC); // Paper
  static const mapBackground = Color(0xFFEDEBE4);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE3E0D8);

  static const textPrimary = Color(0xFF3B3435);
  static const textMuted = Color(0xFF7C7472);

  // Signal categories: icon/accent color + matching pale background tint
  // used behind the icon on cards and chips.
  static const sell = Color(0xFFC9A063);
  static const sellTint = Color(0xFFF4E8D4);

  static const housing = Color(0xFF6FA39A);
  static const housingTint = Color(0xFFD9E8E5);

  static const event = Color(0xFFD68577);
  static const eventTint = Color(0xFFF4DCD6);

  static const community = Color(0xFF9A8CC2);
  static const communityTint = Color(0xFFE4DFF0);

  static const help = Color(0xFF7CAB6C);
  static const helpTint = Color(0xFFDBE9D4);
}

class ZoneTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ZoneColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ZoneColors.primary,
        primary: ZoneColors.primary,
        secondary: ZoneColors.accent,
        surface: ZoneColors.surface,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: ZoneColors.surface,
        foregroundColor: ZoneColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ZoneColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ZoneColors.primary,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: ZoneColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ZoneColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ZoneColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ZoneColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ZoneColors.primary, width: 2),
        ),
      ),
      cardTheme: CardTheme(
        color: ZoneColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: ZoneColors.border),
        ),
      ),
    );
  }
}
