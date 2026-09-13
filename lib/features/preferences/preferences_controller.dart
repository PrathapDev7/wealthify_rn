import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/storage/prefs.dart';
import '../../core/utils/currency.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/preferences_repository.dart';

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
  final String defaultTxnType;
  final String? defaultCategory;
  final String? defaultWallet;
  final String weekStart;

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

  void _persistLocal(Preferences next) {
    ref
        .read(prefsProvider)
        .setString(Prefs.kPreferences, jsonEncode(next.toJson()));
  }

  Future<void> _syncRemote(Preferences next) async {
    try {
      await ref
          .read(preferencesRepositoryProvider)
          .updatePreferences(next.toJson());
    } catch (_) {}
  }

  void update(Preferences next) {
    state = next;
    _persistLocal(next);
    _syncRemote(next);
  }

  Future<void> refreshFromServer() async {
    try {
      final remote =
          await ref.read(preferencesRepositoryProvider).getPreferences();
      if (remote.isEmpty) return;
      final next = Preferences.fromJson(remote);
      state = next;
      _persistLocal(next);
    } catch (_) {}
  }

  void setDefaultWallet(String? walletId) {
    if (state.defaultWallet == walletId) return;
    update(Preferences(
      currencySymbol: state.currencySymbol,
      currencyCode: state.currencyCode,
      defaultTxnType: state.defaultTxnType,
      defaultCategory: state.defaultCategory,
      defaultWallet: walletId,
      weekStart: state.weekStart,
    ));
  }

  void syncDefaultFromWallets(List<WalletModel> wallets) {
    WalletModel? primary;
    for (final w in wallets) {
      if (w.isPrimary) {
        primary = w;
        break;
      }
    }
    if (primary != null) {
      setDefaultWallet(primary.id);
    }
  }

  String money(num? value) =>
      formatCurrency(value, symbol: state.currencySymbol);
}

final preferencesProvider =
    NotifierProvider<PreferencesController, Preferences>(PreferencesController.new);
