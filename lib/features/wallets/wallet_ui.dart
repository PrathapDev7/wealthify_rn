import 'package:flutter/material.dart';

import '../../core/data/provider_catalog.dart';
import '../../data/models/wallet_model.dart';

/// Material fallback icon for a wallet [kind].
IconData kindIcon(String kind) {
  switch (kind) {
    case 'bank':
      return Icons.account_balance_outlined;
    case 'card':
      return Icons.credit_card;
    case 'wallet':
      return Icons.account_balance_wallet_outlined;
    case 'cash':
    default:
      return Icons.payments_outlined;
  }
}

/// Human label for a wallet [kind].
String kindLabel(String kind) {
  switch (kind) {
    case 'bank':
      return 'Bank account';
    case 'card':
      return 'Card';
    case 'wallet':
      return 'Wallet';
    case 'cash':
    default:
      return 'Cash';
  }
}

/// Avatar for a saved wallet: catalog provider badge → stored color + name →
/// a generic kind icon (cash/card/etc.).
Widget walletAvatar(WalletModel w, {double size = 40}) {
  final p = providerById(w.provider);
  if (p != null) return ProviderAvatar(provider: p, size: size);
  return ProviderAvatar(
    label: w.kind == 'cash' ? null : (w.providerName ?? w.name),
    color: parseHexColor(w.color),
    icon: kindIcon(w.kind),
    size: size,
  );
}

/// Card-style masked number: `xxxx xxxx xxxx 1234` (all `xxxx` when no last-4).
String maskedNumber(String? last4) {
  final t = last4?.trim() ?? '';
  final tail = t.isEmpty ? 'xxxx' : t.padLeft(4, 'x');
  return 'xxxx xxxx xxxx $tail';
}

/// Parses a `#RRGGBB` / `RRGGBB` / `AARRGGBB` hex string to a [Color].
Color? parseHexColor(String? hex) {
  if (hex == null) return null;
  var h = hex.trim().replaceFirst('#', '');
  if (h.isEmpty) return null;
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? null : Color(v);
}

/// Resolved accent color for a wallet: catalog provider → stored color → brand.
Color walletAccent(WalletModel w, {Color fallback = const Color(0xFF6C5CE7)}) =>
    providerById(w.provider)?.color ?? parseHexColor(w.color) ?? fallback;

/// `#RRGGBB` string for a [Color] (alpha dropped).
String hexFromColor(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
