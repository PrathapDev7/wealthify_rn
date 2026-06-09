import 'package:flutter/material.dart';

/// Wealthify semantic color palette, ported 1:1 from the RN app
/// (`legacy_rn/src/styles/colors.ts` + `colorsDark.ts`).
///
/// Exposed as a [ThemeExtension] so the active palette switches with the app
/// theme. Access via `Theme.of(context).extension<AppColors>()!` or the
/// `context.colors` helper in `app_theme.dart`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // Brand
  final Color primary;
  final Color primaryDark;
  final Color primaryDarker;
  final Color primarySoft;
  final Color primarySoftStrong;
  final Color primaryGradientStart;
  final Color primaryGradientEnd;
  final Color deepPurple;
  // Accents
  final Color accent;
  final Color accentDark;
  final Color accentSoft;
  final Color negative;
  final Color negativeDark;
  final Color negativeSoft;
  final Color warning;
  final Color warningSoft;
  final Color info;
  final Color infoSoft;
  final Color pink;
  final Color pinkSoft;
  final Color cyan;
  final Color blue;
  // Surfaces
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceSoft;
  final Color surfaceLifted;
  final Color surfaceElevated;
  final Color overlay;
  // Text
  final Color text;
  final Color textStrong;
  final Color textSecondary;
  final Color textBody;
  final Color textMuted;
  final Color textSubtle;
  final Color textPlaceholder;
  final Color textInverse;
  final Color textOnPrimary;
  // Borders
  final Color border;
  final Color borderStrong;
  final Color divider;
  // Special
  final Color fab;
  final Color fabRing;
  final Color lavenderWashTop;
  final Color lavenderWashTopSoft;
  final Color lavenderWashMid;
  final Color lavenderWashBottom;
  // Inputs
  final Color inputBackground;
  final Color inputBorder;
  // Category brand colors (keyed by lowercase category slug)
  final Map<String, Color> category;

  const AppColors({
    required this.primary,
    required this.primaryDark,
    required this.primaryDarker,
    required this.primarySoft,
    required this.primarySoftStrong,
    required this.primaryGradientStart,
    required this.primaryGradientEnd,
    required this.deepPurple,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.negative,
    required this.negativeDark,
    required this.negativeSoft,
    required this.warning,
    required this.warningSoft,
    required this.info,
    required this.infoSoft,
    required this.pink,
    required this.pinkSoft,
    required this.cyan,
    required this.blue,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceSoft,
    required this.surfaceLifted,
    required this.surfaceElevated,
    required this.overlay,
    required this.text,
    required this.textStrong,
    required this.textSecondary,
    required this.textBody,
    required this.textMuted,
    required this.textSubtle,
    required this.textPlaceholder,
    required this.textInverse,
    required this.textOnPrimary,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.fab,
    required this.fabRing,
    required this.lavenderWashTop,
    required this.lavenderWashTopSoft,
    required this.lavenderWashMid,
    required this.lavenderWashBottom,
    required this.inputBackground,
    required this.inputBorder,
    required this.category,
  });

  /// Category brand colors — identical in light & dark (vibrant on both).
  static const Map<String, Color> _category = {
    'groceries': Color(0xFF24D46B),
    'travel': Color(0xFF12C8D8),
    'car': Color(0xFF5437E7),
    'home': Color(0xFFF22AC8),
    'insurance': Color(0xFF12C8D8),
    'education': Color(0xFF5437E7),
    'marketing': Color(0xFFFF991B),
    'shopping': Color(0xFF24D46B),
    'internet': Color(0xFF7B3FF2),
    'water': Color(0xFF3364F6),
    'rent': Color(0xFFFF6B21),
    'gym': Color(0xFFFF991B),
    'subscription': Color(0xFF7B3FF2),
    'vacation': Color(0xFF24D46B),
    'other': Color(0xFF7B3FF2),
    'spotify': Color(0xFF1ED760),
    'wallet': Color(0xFF12C8D8),
  };

  static const AppColors light = AppColors(
    primary: Color(0xFF7B3FF2),
    primaryDark: Color(0xFF6D35E8),
    primaryDarker: Color(0xFF5437E7),
    primarySoft: Color(0xFFEFE8FF),
    primarySoftStrong: Color(0xFFE2D5FF),
    primaryGradientStart: Color(0xFF8B5CFF),
    primaryGradientEnd: Color(0xFF6637F4),
    deepPurple: Color(0xFF160947),
    accent: Color(0xFF9FE39A),
    accentDark: Color(0xFF24D46B),
    accentSoft: Color(0xFFE8F8EE),
    negative: Color(0xFFF04D4D),
    negativeDark: Color(0xFFD94242),
    negativeSoft: Color(0xFFFFEDED),
    warning: Color(0xFFFF991B),
    warningSoft: Color(0xFFFFF3E2),
    info: Color(0xFF3364F6),
    infoSoft: Color(0xFFEAF1FF),
    pink: Color(0xFFF22AC8),
    pinkSoft: Color(0xFFFFEAF5),
    cyan: Color(0xFF12C8D8),
    blue: Color(0xFF3364F6),
    background: Color(0xFFF8F6FE),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF0EDF5),
    surfaceSoft: Color(0xFFF7F5FA),
    surfaceLifted: Color(0xDBFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    overlay: Color(0x73130B3D),
    text: Color(0xFF130B3D),
    textStrong: Color(0xFF130B3D),
    textSecondary: Color(0xFF2A2550),
    textBody: Color(0xFF3B365F),
    textMuted: Color(0xFF3B365F),
    textSubtle: Color(0xFF68708F),
    textPlaceholder: Color(0xFFB8B1C6),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFFE7E1F0),
    borderStrong: Color(0xFFD0C8DE),
    divider: Color(0xB8E7E1F0),
    fab: Color(0xFF160947),
    fabRing: Color(0xF2FFFFFF),
    lavenderWashTop: Color(0xFFEAE0FF),
    lavenderWashTopSoft: Color(0xFFF7F3FF),
    lavenderWashMid: Color(0xFFFFFFFF),
    lavenderWashBottom: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFE7E1F0),
    category: _category,
  );

  static const AppColors dark = AppColors(
    primary: Color(0xFF9B6CFF),
    primaryDark: Color(0xFF8B5CFF),
    primaryDarker: Color(0xFF7B4DF5),
    primarySoft: Color(0xFF2A1E54),
    primarySoftStrong: Color(0xFF34276A),
    primaryGradientStart: Color(0xFF8B5CFF),
    primaryGradientEnd: Color(0xFF6637F4),
    deepPurple: Color(0xFF0E0726),
    accent: Color(0xFF9FE39A),
    accentDark: Color(0xFF2BE07A),
    accentSoft: Color(0xFF16321F),
    negative: Color(0xFFFF6B6B),
    negativeDark: Color(0xFFF04D4D),
    negativeSoft: Color(0xFF3A1E1E),
    warning: Color(0xFFFFB04D),
    warningSoft: Color(0xFF3A2A12),
    info: Color(0xFF5B86F8),
    infoSoft: Color(0xFF1B2747),
    pink: Color(0xFFF95FD6),
    pinkSoft: Color(0xFF3A1730),
    cyan: Color(0xFF3AD8E6),
    blue: Color(0xFF5B86F8),
    background: Color(0xFF0F0A24),
    surface: Color(0xFF1A1140),
    surfaceMuted: Color(0xFF241A4D),
    surfaceSoft: Color(0xFF181030),
    surfaceLifted: Color(0xDB241A4D),
    surfaceElevated: Color(0xFF221848),
    overlay: Color(0x99000000),
    text: Color(0xFFF4F1FF),
    textStrong: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFD7D0F0),
    textBody: Color(0xFFC4BCE4),
    textMuted: Color(0xFFA89FCB),
    textSubtle: Color(0xFF8E86AE),
    textPlaceholder: Color(0xFF6A6390),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFF2E2552),
    borderStrong: Color(0xFF3D3370),
    divider: Color(0x803C3370),
    fab: Color(0xFFFFFFFF),
    fabRing: Color(0xE60F0A24),
    lavenderWashTop: Color(0xFF241A4D),
    lavenderWashTopSoft: Color(0xFF1C1438),
    lavenderWashMid: Color(0xFF0F0A24),
    lavenderWashBottom: Color(0xFF0F0A24),
    inputBackground: Color(0xFF1A1140),
    inputBorder: Color(0xFF2E2552),
    category: _category,
  );

  /// Resolve a category brand color by name, defaulting to `other`.
  Color categoryColor(String? name) =>
      category[(name ?? '').toLowerCase().trim()] ?? category['other']!;

  @override
  AppColors copyWith() => this; // palettes are fixed presets; no field overrides needed

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    // Theme switches are instant (no per-color tween needed).
    return t < 0.5 ? this : other;
  }
}
