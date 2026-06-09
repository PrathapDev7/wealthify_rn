import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/prefs.dart';
import '../../core/utils/currency.dart';

class Preferences {
  const Preferences({
    this.currencySymbol = '₹',
    this.currencyCode = 'INR',
    this.defaultTxnType = 'expense',
    this.defaultCategory,
    this.defaultWallet,
    this.weekStart = 'monday',
  });

  final String currencySymbol;
  final String currencyCode;
  final String defaultTxnType; // 'expense' | 'income'
  final String? defaultCategory; // pre-selected category for new transactions
  final String? defaultWallet; // pre-selected wallet id for new transactions
  final String weekStart; // 'monday' | 'sunday'

  Preferences copyWith({
    String? currencySymbol,
    String? currencyCode,
    String? defaultTxnType,
    String? defaultCategory,
    String? defaultWallet,
    String? weekStart,
  }) =>
      Preferences(
        currencySymbol: currencySymbol ?? this.currencySymbol,
        currencyCode: currencyCode ?? this.currencyCode,
        defaultTxnType: defaultTxnType ?? this.defaultTxnType,
        defaultCategory: defaultCategory ?? this.defaultCategory,
        defaultWallet: defaultWallet ?? this.defaultWallet,
        weekStart: weekStart ?? this.weekStart,
      );

  factory Preferences.fromJson(Map<String, dynamic> j) => Preferences(
        currencySymbol: (j['currencySymbol'] ?? '₹').toString(),
        currencyCode: (j['currencyCode'] ?? 'INR').toString(),
        defaultTxnType: (j['defaultTxnType'] ?? 'expense').toString(),
        defaultCategory: (j['defaultCategory'] as String?)?.trim().isEmpty ?? true
            ? null
            : (j['defaultCategory'] as String).trim(),
        defaultWallet: (j['defaultWallet'] as String?)?.trim().isEmpty ?? true
            ? null
            : (j['defaultWallet'] as String).trim(),
        weekStart: (j['weekStart'] ?? 'monday').toString(),
      );

  Map<String, dynamic> toJson() => {
        'currencySymbol': currencySymbol,
        'currencyCode': currencyCode,
        'defaultTxnType': defaultTxnType,
        'defaultCategory': defaultCategory,
        'defaultWallet': defaultWallet,
        'weekStart': weekStart,
      };
}

class PreferencesController extends Notifier<Preferences> {
  @override
  Preferences build() {
    final raw = ref.read(prefsProvider).getString(Prefs.kPreferences);
    if (raw != null) {
      try {
        return Preferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    return const Preferences();
  }

  void update(Preferences next) {
    state = next;
    ref.read(prefsProvider).setString(Prefs.kPreferences, jsonEncode(next.toJson()));
  }

  /// Formats a value using the active currency symbol.
  String money(num? value) =>
      formatCurrency(value, symbol: state.currencySymbol);
}

final preferencesProvider =
    NotifierProvider<PreferencesController, Preferences>(PreferencesController.new);
