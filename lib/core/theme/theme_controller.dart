import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../storage/prefs.dart';

/// Persisted theme mode (light/dark/system), mirroring RN's ThemeContext
/// (`wealthify_theme` key). Drives MaterialApp.themeMode.
class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => _parse(ref.read(prefsProvider).getString(Prefs.kTheme));

  ThemeMode _parse(String? value) => switch (value) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  void setMode(ThemeMode mode) {
    state = mode;
    ref.read(prefsProvider).setString(Prefs.kTheme, mode.name);
  }

  void toggle() =>
      setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
