import 'package:flutter/material.dart';

/// Wealthify semantic color palette — money-green brand theme.
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
    'car': Color(0xFF1EB583),
    'home': Color(0xFFF22AC8),
    'insurance': Color(0xFF12C8D8),
    'education': Color(0xFF1B8855),
    'marketing': Color(0xFFFF991B),
    'shopping': Color(0xFF24D46B),
    'internet': Color(0xFF22C55E),
    'water': Color(0xFF3364F6),
    'rent': Color(0xFFFF6B21),
    'gym': Color(0xFFFF991B),
    'subscription': Color(0xFF1EB583),
    'vacation': Color(0xFF22C55E),
    'other': Color(0xFF1B8855),
    'spotify': Color(0xFF1ED760),
    'wallet': Color(0xFF12C8D8),
  };

  static const AppColors light = AppColors(
    primary: Color(0xFF1EB583),
    primaryDark: Color(0xFF1B8855),
    primaryDarker: Color(0xFF19602E),
    primarySoft: Color(0xFFE2FAEE),
    primarySoftStrong: Color(0xFFD1FAE5),
    primaryGradientStart: Color(0xFF4BC77C),
    primaryGradientEnd: Color(0xFF1EB583),
    deepPurple: Color(0xFF102600),
    accent: Color(0xFF9FE870),
    accentDark: Color(0xFF7DBB54),
    accentSoft: Color(0xFFEEFBE5),
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
    background: Color(0xFFF7FAF8),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEAFAF1),
    surfaceSoft: Color(0xFFF7FAF8),
    surfaceLifted: Color(0xDBFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    overlay: Color(0x73163300),
    text: Color(0xFF163300),
    textStrong: Color(0xFF132B00),
    textSecondary: Color(0xFF3E572D),
    textBody: Color(0xFF5E734F),
    textMuted: Color(0xFF5E734F),
    textSubtle: Color(0xFF68708F),
    textPlaceholder: Color(0xFFB8B1C6),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFFECFAF3),
    borderStrong: Color(0xFFE1FAED),
    divider: Color(0xB8ECFAF3),
    fab: Color(0xFF163300),
    fabRing: Color(0xF2FFFFFF),
    lavenderWashTop: Color(0xFFE4FAEE),
    lavenderWashTopSoft: Color(0xFFEEFAF3),
    lavenderWashMid: Color(0xFFFFFFFF),
    lavenderWashBottom: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFECFAF3),
    category: _category,
  );

  static const AppColors dark = AppColors(
    primary: Color(0xFF3EC27E),
    primaryDark: Color(0xFF1EB583),
    primaryDarker: Color(0xFF1B8855),
    primarySoft: Color(0xFF0F2400),
    primarySoftStrong: Color(0xFF132B00),
    primaryGradientStart: Color(0xFF65D178),
    primaryGradientEnd: Color(0xFF1EB583),
    deepPurple: Color(0xFF040900),
    accent: Color(0xFF9FE870),
    accentDark: Color(0xFF82DD74),
    accentSoft: Color(0xFF0E2100),
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
    background: Color(0xFF081300),
    surface: Color(0xFF0C1C00),
    surfaceMuted: Color(0xFF0F2400),
    surfaceSoft: Color(0xFF0A1700),
    surfaceLifted: Color(0xDB0F2400),
    surfaceElevated: Color(0xFF0E2100),
    overlay: Color(0x99000000),
    text: Color(0xFFECF7EF),
    textStrong: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFC6E3D0),
    textBody: Color(0xFFAED0B8),
    textMuted: Color(0xFF93B5A0),
    textSubtle: Color(0xFF7C9A86),
    textPlaceholder: Color(0xFF5A735F),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFF102600),
    borderStrong: Color(0xFF132D00),
    divider: Color(0x80132D00),
    fab: Color(0xFFFFFFFF),
    fabRing: Color(0xE6081300),
    lavenderWashTop: Color(0xFF0D1F00),
    lavenderWashTopSoft: Color(0xFF0B1A00),
    lavenderWashMid: Color(0xFF081300),
    lavenderWashBottom: Color(0xFF081300),
    inputBackground: Color(0xFF0C1C00),
    inputBorder: Color(0xFF102600),
    category: _category,
  );

  /// Healthify (calorie tracker) palette — flat slate/green brand, distinct
  /// from Wealthify's soft-emerald theme. Applied only to the Healthify tab
  /// and its screens via [HealthifyTheme].
  static const AppColors healthifyLight = AppColors(
    primary: Color(0xFF16A34A),
    primaryDark: Color(0xFF15803D),
    primaryDarker: Color(0xFF166534),
    primarySoft: Color(0xFFDCFCE7),
    primarySoftStrong: Color(0xFFBBF7D0),
    primaryGradientStart: Color(0xFF22C55E),
    primaryGradientEnd: Color(0xFF16A34A),
    deepPurple: Color(0xFF0F172A),
    accent: Color(0xFF6366F1),
    accentDark: Color(0xFF4F46E5),
    accentSoft: Color(0xFFE0E7FF),
    negative: Color(0xFFEF4444),
    negativeDark: Color(0xFFDC2626),
    negativeSoft: Color(0xFFFEE2E2),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0xFFFEF3C7),
    info: Color(0xFF0D9488),
    infoSoft: Color(0xFFCCFBF1),
    pink: Color(0xFFEC4899),
    pinkSoft: Color(0xFFFCE7F3),
    cyan: Color(0xFF06B6D4),
    blue: Color(0xFF3B82F6),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F5F9),
    surfaceSoft: Color(0xFFF8FAFC),
    surfaceLifted: Color(0xDBFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    overlay: Color(0x7317251B),
    text: Color(0xFF17251B),
    textStrong: Color(0xFF0B120D),
    textSecondary: Color(0xFF64748B),
    textBody: Color(0xFF64748B),
    textMuted: Color(0xFF64748B),
    textSubtle: Color(0xFF94A3B8),
    textPlaceholder: Color(0xFFCBD5E1),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFFE2E8F0),
    borderStrong: Color(0xFFCBD5E1),
    divider: Color(0xB8E2E8F0),
    fab: Color(0xFF17251B),
    fabRing: Color(0xF2FFFFFF),
    lavenderWashTop: Color(0xFFECFDF5),
    lavenderWashTopSoft: Color(0xFFF0FDF4),
    lavenderWashMid: Color(0xFFF8FAFC),
    lavenderWashBottom: Color(0xFFF8FAFC),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFE2E8F0),
    category: _category,
  );

  static const AppColors healthifyDark = AppColors(
    primary: Color(0xFF22C55E),
    primaryDark: Color(0xFF16A34A),
    primaryDarker: Color(0xFF15803D),
    primarySoft: Color(0xFF14532D),
    primarySoftStrong: Color(0xFF166534),
    primaryGradientStart: Color(0xFF4ADE80),
    primaryGradientEnd: Color(0xFF22C55E),
    deepPurple: Color(0xFF020617),
    accent: Color(0xFF818CF8),
    accentDark: Color(0xFF6366F1),
    accentSoft: Color(0xFF312E81),
    negative: Color(0xFFF87171),
    negativeDark: Color(0xFFEF4444),
    negativeSoft: Color(0xFF450A0A),
    warning: Color(0xFFFBBF24),
    warningSoft: Color(0xFF451A03),
    info: Color(0xFF2DD4BF),
    infoSoft: Color(0xFF134E4A),
    pink: Color(0xFFF472B6),
    pinkSoft: Color(0xFF500724),
    cyan: Color(0xFF22D3EE),
    blue: Color(0xFF60A5FA),
    background: Color(0xFF0F172A),
    surface: Color(0xFF1E293B),
    surfaceMuted: Color(0xFF16202E),
    surfaceSoft: Color(0xFF0F172A),
    surfaceLifted: Color(0xDB1E293B),
    surfaceElevated: Color(0xFF1E293B),
    overlay: Color(0x99000000),
    text: Color(0xFFF1F5F9),
    textStrong: Color(0xFFFFFFFF),
    textSecondary: Color(0xFF94A3B8),
    textBody: Color(0xFF94A3B8),
    textMuted: Color(0xFF94A3B8),
    textSubtle: Color(0xFF64748B),
    textPlaceholder: Color(0xFF475569),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFF1E293B),
    borderStrong: Color(0xFF334155),
    divider: Color(0x801E293B),
    fab: Color(0xFFFFFFFF),
    fabRing: Color(0xE60F172A),
    lavenderWashTop: Color(0xFF0D1F17),
    lavenderWashTopSoft: Color(0xFF0B1A14),
    lavenderWashMid: Color(0xFF0F172A),
    lavenderWashBottom: Color(0xFF0F172A),
    inputBackground: Color(0xFF1E293B),
    inputBorder: Color(0xFF334155),
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
