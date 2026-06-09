import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Poppins type scale ported from `legacy_rn/src/styles/typography.ts`.
/// Styles carry font/size/weight only — color is applied by the widget (so the
/// same style works in light & dark). Use `.copyWith(color: context.colors.x)`.
abstract class AppText {
  static TextStyle _p(double size, FontWeight weight, {double? height}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, height: height);

  static TextStyle get displayLg => _p(34, FontWeight.w800, height: 1.08);
  static TextStyle get display => _p(30, FontWeight.w800);
  static TextStyle get titleLg => _p(26, FontWeight.w800, height: 1.14);
  static TextStyle get title => _p(20, FontWeight.w700, height: 1.2);
  static TextStyle get screenTitle => _p(18, FontWeight.w600, height: 1.25);
  static TextStyle get subtitle => _p(16, FontWeight.w700);
  static TextStyle get body => _p(14, FontWeight.w400, height: 1.45);
  static TextStyle get bodyMedium => _p(14, FontWeight.w600);
  static TextStyle get bodyStrong => _p(14, FontWeight.w700);
  static TextStyle get bodySm => _p(12, FontWeight.w400, height: 1.4);
  static TextStyle get caption => _p(11, FontWeight.w500, height: 1.35);
  static TextStyle get label => _p(11, FontWeight.w600);
  static TextStyle get button => _p(14, FontWeight.w700);
  static TextStyle get link => _p(12, FontWeight.w700);
  static TextStyle get money => _p(34, FontWeight.w800);
  static TextStyle get moneyMd => _p(19, FontWeight.w700);
  static TextStyle get moneySm => _p(12, FontWeight.w700);
}
