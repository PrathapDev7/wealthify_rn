import 'package:flutter/material.dart';

import '../../../core/data/provider_catalog.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/wallet_model.dart';
import '../wallet_ui.dart';

/// A credit-card style visual used for every wallet kind (cash/bank/card/wallet):
/// provider/kind icon, name, holder, a masked card number, and (optionally) the
/// balance — over the provider's brand-colored gradient.
class WalletCardVisual extends StatelessWidget {
  const WalletCardVisual({
    super.key,
    required this.wallet,
    this.balanceText,
    this.holderFallback,
  });

  final WalletModel wallet;
  final String? balanceText;
  final String? holderFallback; // e.g. profile name when the wallet has none

  @override
  Widget build(BuildContext context) {
    final accent = walletAccent(wallet);
    final provider = providerById(wallet.provider);
    final title = wallet.providerName ?? wallet.name;
    final holder = (wallet.holderName?.trim().isNotEmpty ?? false)
        ? wallet.holderName!.trim()
        : (holderFallback?.trim() ?? '');
    final sub = wallet.isCard && (wallet.cardType?.isNotEmpty ?? false)
        ? '${_cap(wallet.cardType!)} card'
        : kindLabel(wallet.kind);
    const white = Colors.white;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, _darken(accent)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: provider != null
                    ? ProviderAvatar(provider: provider, size: 34)
                    : Icon(kindIcon(wallet.kind), color: accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium.copyWith(
                            color: white, fontWeight: FontWeight.w700)),
                    Text(sub,
                        style: AppText.caption
                            .copyWith(color: white.withValues(alpha: 0.78))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            maskedNumber(wallet.last4),
            style: AppText.subtitle.copyWith(color: white, letterSpacing: 2.2),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _stack('HOLDER', holder.isEmpty ? '—' : holder, white,
                    end: false),
              ),
              if (balanceText != null)
                _stack('BALANCE', balanceText!, white, end: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stack(String label, String value, Color white, {required bool end}) {
    return Column(
      crossAxisAlignment:
          end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              color: white.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            )),
        const SizedBox(height: 2),
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.bodySm.copyWith(
                color: white, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

String _cap(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

Color _darken(Color c, [double amount = 0.18]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}
