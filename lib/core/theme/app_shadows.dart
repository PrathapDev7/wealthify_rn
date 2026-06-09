import 'package:flutter/material.dart';

/// Ink-tinted shadow presets ported from `legacy_rn/src/styles/shadows.ts`.
/// All neutral shadows use the deep-purple ink (#1C1140) for cohesion.
abstract class AppShadows {
  static const List<BoxShadow> none = [];

  static const List<BoxShadow> xs = [
    BoxShadow(color: Color(0x081C1140), offset: Offset(0, 3), blurRadius: 10),
  ];
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0F1C1140), offset: Offset(0, 8), blurRadius: 20),
  ];
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x141C1140), offset: Offset(0, 10), blurRadius: 28),
  ];
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x1A1C1140), offset: Offset(0, 12), blurRadius: 30),
  ];
  static const List<BoxShadow> xl = [
    BoxShadow(color: Color(0x291C1140), offset: Offset(0, 18), blurRadius: 40),
  ];
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(color: Color(0x477B3FF2), offset: Offset(0, 12), blurRadius: 24),
  ];
  static const List<BoxShadow> primaryGlowSoft = [
    BoxShadow(color: Color(0x2E7B3FF2), offset: Offset(0, 8), blurRadius: 18),
  ];
  static const List<BoxShadow> fab = [
    BoxShadow(color: Color(0x2E1C1140), offset: Offset(0, 16), blurRadius: 36),
  ];
}
