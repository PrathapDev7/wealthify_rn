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

  /// Healthify (calorie tracker) palette — warm orange/mint/indigo brand,
  /// distinct from Wealthify's soft-emerald theme. Applied only to the
  /// Healthify tab and its screens via [HealthifyTheme].
  static const AppColors healthifyLight = AppColors(
    primary: Color(0xFFFF6B35),
    primaryDark: Color(0xFFE8551F),
    primaryDarker: Color(0xFFC2451C),
    primarySoft: Color(0xFFFFE8DD),
    primarySoftStrong: Color(0xFFFFD1BA),
    primaryGradientStart: Color(0xFFFF8C5A),
    primaryGradientEnd: Color(0xFFFF6B35),
    deepPurple: Color(0xFF111827),
    accent: Color(0xFF6366F1),
    accentDark: Color(0xFF4F46E5),
    accentSoft: Color(0xFFE0E7FF),
    negative: Color(0xFFEF4444),
    negativeDark: Color(0xFFDC2626),
    negativeSoft: Color(0xFFFEE2E2),
    warning: Color(0xFFFFD23F),
    warningSoft: Color(0xFFFFF3C4),
    info: Color(0xFF00BFA6),
    infoSoft: Color(0xFFCCFAF3),
    pink: Color(0xFFEC4899),
    pinkSoft: Color(0xFFFCE7F3),
    cyan: Color(0xFF00BFA6),
    blue: Color(0xFF3B82F6),
    background: Color(0xFFFFFBF7),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFFFF3EA),
    surfaceSoft: Color(0xFFFFFBF7),
    surfaceLifted: Color(0xDBFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    overlay: Color(0x731F2937),
    text: Color(0xFF1F2937),
    textStrong: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textBody: Color(0xFF6B7280),
    textMuted: Color(0xFF6B7280),
    textSubtle: Color(0xFF9CA3AF),
    textPlaceholder: Color(0xFFD1D5DB),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFFF1E4D8),
    borderStrong: Color(0xFFE3CBB4),
    divider: Color(0xB8F1E4D8),
    fab: Color(0xFF1F2937),
    fabRing: Color(0xF2FFFFFF),
    lavenderWashTop: Color(0xFFFFF0E5),
    lavenderWashTopSoft: Color(0xFFFFF6EF),
    lavenderWashMid: Color(0xFFFFFBF7),
    lavenderWashBottom: Color(0xFFFFFBF7),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFF1E4D8),
    category: _category,
  );

  static const AppColors healthifyDark = AppColors(
    primary: Color(0xFFFF8A5C),
    primaryDark: Color(0xFFFF6B35),
    primaryDarker: Color(0xFFE8551F),
    primarySoft: Color(0xFF4A2415),
    primarySoftStrong: Color(0xFF5C2E1A),
    primaryGradientStart: Color(0xFFFFA477),
    primaryGradientEnd: Color(0xFFFF8A5C),
    deepPurple: Color(0xFF0A0806),
    accent: Color(0xFF818CF8),
    accentDark: Color(0xFF6366F1),
    accentSoft: Color(0xFF312E81),
    negative: Color(0xFFF87171),
    negativeDark: Color(0xFFEF4444),
    negativeSoft: Color(0xFF450A0A),
    warning: Color(0xFFFFD23F),
    warningSoft: Color(0xFF4A3B0A),
    info: Color(0xFF2DD9C0),
    infoSoft: Color(0xFF0F3D35),
    pink: Color(0xFFF472B6),
    pinkSoft: Color(0xFF4A0E2E),
    cyan: Color(0xFF2DD9C0),
    blue: Color(0xFF60A5FA),
    background: Color(0xFF1A1410),
    surface: Color(0xFF241C17),
    surfaceMuted: Color(0xFF1F1712),
    surfaceSoft: Color(0xFF1A1410),
    surfaceLifted: Color(0xDB241C17),
    surfaceElevated: Color(0xFF241C17),
    overlay: Color(0x99000000),
    text: Color(0xFFF3EDE8),
    textStrong: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFB8AFA8),
    textBody: Color(0xFFB8AFA8),
    textMuted: Color(0xFFB8AFA8),
    textSubtle: Color(0xFF8A7F77),
    textPlaceholder: Color(0xFF5C5249),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFF2E2420),
    borderStrong: Color(0xFF3D322B),
    divider: Color(0x802E2420),
    fab: Color(0xFFFFFFFF),
    fabRing: Color(0xE61A1410),
    lavenderWashTop: Color(0xFF241A12),
    lavenderWashTopSoft: Color(0xFF1E160F),
    lavenderWashMid: Color(0xFF1A1410),
    lavenderWashBottom: Color(0xFF1A1410),
    inputBackground: Color(0xFF241C17),
    inputBorder: Color(0xFF3D322B),
    category: _category,
  );

  /// Align (brand shell) palette — the deep-navy / violet→blue→teal identity
  /// used by the launch surfaces: splash, onboarding and auth. Applied via
  /// [AlignTheme]; the Wealthify and Healthify tab palettes are untouched.
  static const AppColors alignLight = AppColors(
    primary: Color(0xFF3B7BF6),
    primaryDark: Color(0xFF6C4BF0),
    primaryDarker: Color(0xFF22D3A6),
    primarySoft: Color(0xFFEAF1FF),
    primarySoftStrong: Color(0xFFDCE7FF),
    primaryGradientStart: Color(0xFF7C3AED),
    primaryGradientEnd: Color(0xFF22D3A6),
    deepPurple: Color(0xFF0B1122),
    accent: Color(0xFF22D3A6),
    accentDark: Color(0xFF12B48C),
    accentSoft: Color(0xFFE2FBF3),
    negative: Color(0xFFF04D4D),
    negativeDark: Color(0xFFD94242),
    negativeSoft: Color(0xFFFFEDED),
    warning: Color(0xFFF59E0B),
    warningSoft: Color(0xFFFFF4E0),
    info: Color(0xFF3B7BF6),
    infoSoft: Color(0xFFEAF1FF),
    pink: Color(0xFFD946EF),
    pinkSoft: Color(0xFFFBEAFE),
    cyan: Color(0xFF06B6D4),
    blue: Color(0xFF3B7BF6),
    background: Color(0xFFF6F8FD),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEEF3FD),
    surfaceSoft: Color(0xFFF6F8FD),
    surfaceLifted: Color(0xDBFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    overlay: Color(0x730B1122),
    text: Color(0xFF0F172A),
    textStrong: Color(0xFF0B1122),
    textSecondary: Color(0xFF3C4A63),
    textBody: Color(0xFF55637D),
    textMuted: Color(0xFF55637D),
    textSubtle: Color(0xFF7B879E),
    textPlaceholder: Color(0xFFAEB7C8),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFFE4EAF6),
    borderStrong: Color(0xFFD3DCEE),
    divider: Color(0xB8E4EAF6),
    fab: Color(0xFF0F172A),
    fabRing: Color(0xF2FFFFFF),
    lavenderWashTop: Color(0xFFE6EDFB),
    lavenderWashTopSoft: Color(0xFFF1F5FD),
    lavenderWashMid: Color(0xFFFFFFFF),
    lavenderWashBottom: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFE4EAF6),
    category: _category,
  );

  static const AppColors alignDark = AppColors(
    primary: Color(0xFF4F8EFF),
    primaryDark: Color(0xFF6C4BF0),
    primaryDarker: Color(0xFF22D3A6),
    primarySoft: Color(0xFF17203A),
    primarySoftStrong: Color(0xFF1D2748),
    primaryGradientStart: Color(0xFF7C3AED),
    primaryGradientEnd: Color(0xFF22D3A6),
    deepPurple: Color(0xFF05080F),
    accent: Color(0xFF22D3A6),
    accentDark: Color(0xFF17B78E),
    accentSoft: Color(0xFF10241F),
    negative: Color(0xFFFF6B6B),
    negativeDark: Color(0xFFF04D4D),
    negativeSoft: Color(0xFF3A1E1E),
    warning: Color(0xFFFFBA5B),
    warningSoft: Color(0xFF3A2C14),
    info: Color(0xFF4F8EFF),
    infoSoft: Color(0xFF16233F),
    pink: Color(0xFFE879F9),
    pinkSoft: Color(0xFF2A163A),
    cyan: Color(0xFF22D3EE),
    blue: Color(0xFF4F8EFF),
    background: Color(0xFF070C18),
    surface: Color(0xFF0F1729),
    surfaceMuted: Color(0xFF131C33),
    surfaceSoft: Color(0xFF0A1120),
    surfaceLifted: Color(0xDB131C33),
    surfaceElevated: Color(0xFF16203A),
    overlay: Color(0x99000000),
    text: Color(0xFFE8EDF7),
    textStrong: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFC2CBDD),
    textBody: Color(0xFFAAB4C8),
    textMuted: Color(0xFF93A0B8),
    textSubtle: Color(0xFF7A87A0),
    textPlaceholder: Color(0xFF55607A),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFF1B2540),
    borderStrong: Color(0xFF26314F),
    divider: Color(0x8026314F),
    fab: Color(0xFFFFFFFF),
    fabRing: Color(0xE6070C18),
    lavenderWashTop: Color(0xFF101A33),
    lavenderWashTopSoft: Color(0xFF0B1326),
    lavenderWashMid: Color(0xFF070C18),
    lavenderWashBottom: Color(0xFF070C18),
    inputBackground: Color(0xFF0F1729),
    inputBorder: Color(0xFF232E4C),
    category: _category,
  );

  /// Fitness (workout) palette — a graphite ground with near-black elevated
  /// cards and a single electric-blue accent, matching the workout reference.
  /// Applied to the workout surfaces via [FitnessTheme].
  ///
  /// Blue rather than green: green is Wealthify's brand color, so Fitness
  /// gets its own hue to stay visually distinct in the app switcher and tab.
  ///
  /// The design is dark-first: the reference is black pills floating on a
  /// graphite page, and the contrast between `surface` and `background` is the
  /// whole visual system. The light pair below inverts that relationship
  /// (white cards on a cool grey page) rather than trying to reproduce it, so
  /// a user on a light device still gets a legible screen.
  static const AppColors fitnessLight = AppColors(
    primary: Color(0xFF2E7DF7),
    primaryDark: Color(0xFF1E63D6),
    primaryDarker: Color(0xFF154AA8),
    primarySoft: Color(0xFFE3EDFE),
    primarySoftStrong: Color(0xFFC7DBFC),
    primaryGradientStart: Color(0xFF5FA0FA),
    primaryGradientEnd: Color(0xFF2E7DF7),
    deepPurple: Color(0xFF101114),
    accent: Color(0xFF2E7DF7),
    accentDark: Color(0xFF1E63D6),
    accentSoft: Color(0xFFE3EDFE),
    negative: Color(0xFFE5484D),
    negativeDark: Color(0xFFC93B40),
    negativeSoft: Color(0xFFFDECEC),
    warning: Color(0xFFE08A28),
    warningSoft: Color(0xFFFCF0DF),
    info: Color(0xFF3B82F6),
    infoSoft: Color(0xFFE6EEFE),
    pink: Color(0xFFD946EF),
    pinkSoft: Color(0xFFFBEAFE),
    cyan: Color(0xFF06B6D4),
    blue: Color(0xFF3B82F6),
    background: Color(0xFFF3F4F6),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE9EBEF),
    surfaceSoft: Color(0xFFF3F4F6),
    surfaceLifted: Color(0xDBFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    overlay: Color(0x73101114),
    text: Color(0xFF101114),
    textStrong: Color(0xFF000000),
    textSecondary: Color(0xFF4B5058),
    textBody: Color(0xFF5B616B),
    textMuted: Color(0xFF6B717B),
    textSubtle: Color(0xFF878D97),
    textPlaceholder: Color(0xFFB3B8C0),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFFE0E3E8),
    borderStrong: Color(0xFFCBD0D8),
    divider: Color(0xB8E0E3E8),
    fab: Color(0xFF2E7DF7),
    fabRing: Color(0xF2FFFFFF),
    lavenderWashTop: Color(0xFFEDEFF3),
    lavenderWashTopSoft: Color(0xFFF1F2F6),
    lavenderWashMid: Color(0xFFF3F4F6),
    lavenderWashBottom: Color(0xFFF3F4F6),
    inputBackground: Color(0xFFFFFFFF),
    inputBorder: Color(0xFFE0E3E8),
    category: _category,
  );

  static const AppColors fitnessDark = AppColors(
    primary: Color(0xFF5B9DFF),
    primaryDark: Color(0xFF3B82F6),
    primaryDarker: Color(0xFF2E7DF7),
    // The filled ground behind an active set row: blue enough to read as
    // "this one", dark enough that white numerals still sit on it.
    primarySoft: Color(0xFF122A4A),
    primarySoftStrong: Color(0xFF1A3A63),
    primaryGradientStart: Color(0xFF7FB6FF),
    primaryGradientEnd: Color(0xFF4A93FF),
    deepPurple: Color(0xFF000000),
    accent: Color(0xFF5B9DFF),
    accentDark: Color(0xFF3B82F6),
    accentSoft: Color(0xFF122A4A),
    negative: Color(0xFFFF5C5C),
    negativeDark: Color(0xFFE5484D),
    negativeSoft: Color(0xFF381718),
    // The rest state owns amber outright — the session bar turns this color
    // the moment a set is ticked off, so it has to be as loud as the blue.
    warning: Color(0xFFF0A94B),
    warningSoft: Color(0xFF3A2A12),
    info: Color(0xFF4F9DFF),
    infoSoft: Color(0xFF13233A),
    pink: Color(0xFFE879F9),
    pinkSoft: Color(0xFF2A163A),
    cyan: Color(0xFF22D3EE),
    blue: Color(0xFF4F9DFF),
    background: Color(0xFF26272A),
    // Deliberately *darker* than the background: the reference's cards, pills
    // and chips are near-black shapes cut out of a graphite page, so elevation
    // here reads as depth rather than as lift.
    surface: Color(0xFF0E0E10),
    surfaceMuted: Color(0xFF1A1B1D),
    surfaceSoft: Color(0xFF202124),
    surfaceLifted: Color(0xDB0E0E10),
    surfaceElevated: Color(0xFF303134),
    overlay: Color(0xB3000000),
    text: Color(0xFFFFFFFF),
    textStrong: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFA8AAAE),
    textBody: Color(0xFF9A9CA1),
    textMuted: Color(0xFF9A9CA1),
    textSubtle: Color(0xFF7C7E83),
    textPlaceholder: Color(0xFF5A5C60),
    textInverse: Color(0xFFFFFFFF),
    textOnPrimary: Color(0xFFFFFFFF),
    border: Color(0xFF303236),
    borderStrong: Color(0xFF3D4045),
    divider: Color(0x80303236),
    fab: Color(0xFF5B9DFF),
    fabRing: Color(0xE626272A),
    lavenderWashTop: Color(0xFF202124),
    lavenderWashTopSoft: Color(0xFF232427),
    lavenderWashMid: Color(0xFF26272A),
    lavenderWashBottom: Color(0xFF26272A),
    inputBackground: Color(0xFF0E0E10),
    inputBorder: Color(0xFF303236),
    category: _category,
  );

  /// Brand gradient for the Fitness segment of the app switcher, and for the
  /// blue action bars inside the workout screens. Kept as a bare constant (not
  /// a palette field) because the switcher pill renders *outside*
  /// [FitnessTheme] — it sits in the ambient Wealthify theme and still has to
  /// show the Fitness hue.
  static const List<Color> fitnessGradient = [
    Color(0xFF5B9DFF),
    Color(0xFF2E7DF7),
  ];

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
