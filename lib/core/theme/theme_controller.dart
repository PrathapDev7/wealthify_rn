import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../storage/prefs.dart';
import '../../data/repositories/preferences_repository.dart';

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
    _syncRemote(mode);
  }

  Future<void> _syncRemote(ThemeMode mode) async {
    try {
      await ref
          .read(preferencesRepositoryProvider)
          .updatePreferences({'theme': mode.name});
    } catch (_) {}
  }

  Future<void> refreshFromServer() async {
    try {
      final remote =
          await ref.read(preferencesRepositoryProvider).getPreferences();
      final theme = remote['theme']?.toString();
      if (theme == null || theme.isEmpty) return;
      state = _parse(theme);
      ref.read(prefsProvider).setString(Prefs.kTheme, state.name);
    } catch (_) {}
  }

  void toggle() =>
      setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
