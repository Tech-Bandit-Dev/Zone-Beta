import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Brand + category colors. These are the same in light and dark mode.
///
/// Indigo primary on slate neutrals — a familiar, modern product palette.
/// Category hues are mid-saturation so they read on both white and
/// near-black surfaces; pale tints are derived (see [ZoneColors.tintOf]) so
/// they adapt to the current brightness instead of being hardcoded.
class ZoneColors {
  static const primary = Color(0xFF4F46E5); // Indigo 600
  static const primaryLight = Color(0xFF818CF8); // Indigo 400 (dark mode)
  static const primaryDeep = Color(0xFF3730A3); // Indigo 800 (gradients)

  static const locationDot = Color(0xFF0EA5E9); // Sky — "you are here" only

  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const star = Color(0xFFF59E0B);

  // Signal categories.
  static const sell = Color(0xFFF59E0B); // Amber
  static const housing = Color(0xFF14B8A6); // Teal
  static const event = Color(0xFFF43F5E); // Rose
  static const community = Color(0xFF8B5CF6); // Violet
  static const help = Color(0xFF10B981); // Emerald

  /// Soft background behind a category icon. Alpha-based so it sits
  /// correctly on both light and dark surfaces.
  static Color tintOf(Color c) => c.withValues(alpha: 0.14);
}

/// Neutral, brightness-dependent colors. Read via `context.zc`.
@immutable
class ZonePalette extends ThemeExtension<ZonePalette> {
  const ZonePalette({
    required this.primary,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.mapBackground,
    required this.mapBlock,
    required this.mapRoad,
  });

  final Color primary;
  final Color background;
  final Color surface;
  final Color surfaceAlt; // Subtle fill: chips, inputs, inactive tiles
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color mapBackground;
  final Color mapBlock;
  final Color mapRoad;

  static const light = ZonePalette(
    primary: ZoneColors.primary,
    background: Color(0xFFF8FAFC), // Slate 50
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F5F9), // Slate 100
    border: Color(0xFFE2E8F0), // Slate 200
    textPrimary: Color(0xFF0F172A), // Slate 900
    textMuted: Color(0xFF64748B), // Slate 500
    mapBackground: Color(0xFFEEF1F5),
    mapBlock: Color(0xFFE3E8EF),
    mapRoad: Color(0xFFFFFFFF),
  );

  static const dark = ZonePalette(
    primary: ZoneColors.primaryLight,
    background: Color(0xFF0B1120),
    surface: Color(0xFF111827),
    surfaceAlt: Color(0xFF1E293B), // Slate 800
    border: Color(0xFF263244),
    textPrimary: Color(0xFFF1F5F9),
    textMuted: Color(0xFF94A3B8), // Slate 400
    mapBackground: Color(0xFF0F172A),
    mapBlock: Color(0xFF162033),
    mapRoad: Color(0xFF1F2B3E),
  );

  @override
  ZonePalette copyWith() => this;

  @override
  ZonePalette lerp(ZonePalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ZonePalette(
      primary: l(primary, other.primary),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceAlt: l(surfaceAlt, other.surfaceAlt),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textMuted: l(textMuted, other.textMuted),
      mapBackground: l(mapBackground, other.mapBackground),
      mapBlock: l(mapBlock, other.mapBlock),
      mapRoad: l(mapRoad, other.mapRoad),
    );
  }
}

extension ZonePaletteContext on BuildContext {
  ZonePalette get zc => Theme.of(this).extension<ZonePalette>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

/// Light / dark / follow-system. Changed from the Profile tab.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

class ZoneTheme {
  static ThemeData light() => _build(ZonePalette.light, Brightness.light);
  static ThemeData dark() => _build(ZonePalette.dark, Brightness.dark);

  static ThemeData _build(ZonePalette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: ZoneColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: p.primary,
      onPrimary: Colors.white,
      surface: p.surface,
      onSurface: p.textPrimary,
      outline: p.border,
      outlineVariant: p.border,
    );

    final radius = BorderRadius.circular(14);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      extensions: [p],
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: p.border, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: p.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: p.primary.withValues(alpha: 0.5),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          backgroundColor: p.surface,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        hintStyle: TextStyle(color: p.textMuted),
        labelStyle: TextStyle(color: p.textMuted),
        prefixIconColor: p.textMuted,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.primary, width: 1.6),
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: p.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.primary.withValues(alpha: 0.14),
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => TextStyle(
              fontSize: 12,
              fontWeight: s.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: s.contains(WidgetState.selected)
                  ? p.primary
                  : p.textMuted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((s) => IconThemeData(
              color: s.contains(WidgetState.selected)
                  ? p.primary
                  : p.textMuted,
            )),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        contentTextStyle: TextStyle(color: p.background),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: p.primary.withValues(alpha: 0.14),
          selectedForegroundColor: p.primary,
          foregroundColor: p.textMuted,
          side: BorderSide(color: p.border),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
