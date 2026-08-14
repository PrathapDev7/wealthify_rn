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
    this.compact = false,
  });

  final WalletModel wallet;
  final String? balanceText;
  final String? holderFallback; // e.g. profile name when the wallet has none
  final bool compact; // tighter padding/type scale for space-constrained spots (e.g. dashboard)

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
    final avatarSize = compact ? 34.0 : 44.0;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, _darken(accent)],
        ),
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: compact ? 12 : 16,
            offset: Offset(0, compact ? 6 : 8),
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
                width: avatarSize,
                height: avatarSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: provider != null
                    ? ProviderAvatar(provider: provider, size: compact ? 26 : 34)
                    : Icon(kindIcon(wallet.kind),
                        color: accent, size: compact ? 18 : 22),
              ),
              SizedBox(width: compact ? AppSpacing.sm : AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium.copyWith(
                            color: white, fontWeight: FontWeight.w700)),
                    if (!compact)
                      Text(sub,
                          style: AppText.caption
                              .copyWith(color: white.withValues(alpha: 0.78))),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
          Text(
            maskedNumber(wallet.last4),
            style: (compact ? AppText.bodyStrong : AppText.subtitle)
                .copyWith(color: white, letterSpacing: compact ? 1.6 : 2.2),
          ),
          SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _stack('HOLDER', holder.isEmpty ? '—' : holder, white,
                    end: false, compact: compact),
              ),
              if (balanceText != null)
                _stack('BALANCE', balanceText!, white,
                    end: true, compact: compact),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stack(String label, String value, Color white,
      {required bool end, required bool compact}) {
    return Column(
      crossAxisAlignment:
          end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              color: white.withValues(alpha: 0.6),
              fontSize: compact ? 8 : 9,
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
