import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Builds the light & dark [ThemeData] from the [AppColors] palettes and the
/// Poppins type scale. The palette is attached as a [ThemeExtension] so widgets
/// can read the active colors via `context.colors`.
abstract class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);
  static ThemeData healthifyLight() =>
      _build(AppColors.healthifyLight, Brightness.light);
  static ThemeData healthifyDark() =>
      _build(AppColors.healthifyDark, Brightness.dark);
  static ThemeData alignLight() =>
      _build(AppColors.alignLight, Brightness.light);
  static ThemeData alignDark() => _build(AppColors.alignDark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
    ).copyWith(
      primary: c.primary,
      onPrimary: c.textOnPrimary,
      secondary: c.accentDark,
      surface: c.surface,
      onSurface: c.text,
      error: c.negative,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      dividerColor: c.divider,
      extensions: <ThemeExtension<dynamic>>[c],
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme)
          .apply(bodyColor: c.text, displayColor: c.text),
    );
  }
}

/// Convenience accessor: `context.colors.primary`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

/// Swaps in the Healthify brand palette (matching the ambient light/dark
/// brightness) for its subtree — the calorie tracker's tab content and
/// standalone routes. Everything under it keeps reading `context.colors`
/// as usual; only the resolved palette changes.
class HealthifyTheme extends StatelessWidget {
  const HealthifyTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: isDark ? AppTheme.healthifyDark() : AppTheme.healthifyLight(),
      child: child,
    );
  }
}

/// Swaps in the Align brand palette (matching the ambient light/dark
/// brightness) for its subtree — the launch surfaces: splash, onboarding and
/// auth. The Wealthify and Healthify tab palettes are unaffected.
class AlignTheme extends StatelessWidget {
  const AlignTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: isDark ? AppTheme.alignDark() : AppTheme.alignLight(),
      child: child,
    );
  }
}
