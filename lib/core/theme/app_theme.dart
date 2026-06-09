import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Builds the light & dark [ThemeData] from the [AppColors] palettes and the
/// Poppins type scale. The palette is attached as a [ThemeExtension] so widgets
/// can read the active colors via `context.colors`.
abstract class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

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
