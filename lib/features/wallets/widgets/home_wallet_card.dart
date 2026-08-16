import 'package:flutter/material.dart';

import '../../../core/data/provider_catalog.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/wallet_model.dart';
import '../wallet_ui.dart';

/// Dashboard-only wallet card: a frosted glass panel sitting on top of the
/// hero gradient backdrop, showing a masked number + expiry like the
/// reference design. Distinct from [WalletCardVisual] (used on the Wallets
/// list screen), which carries its own per-wallet brand gradient — this card
/// relies on the backdrop for color instead.
class HomeWalletCard extends StatelessWidget {
  const HomeWalletCard({super.key, required this.wallet});

  final WalletModel wallet;

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final brand = (wallet.providerName ?? wallet.name).trim();
    final subtitle = brand.isEmpty ? kindLabel(wallet.kind) : brand;
    final last4 = wallet.last4?.trim() ?? '';
    final maskedTail = last4.isEmpty ? 'xxxx' : last4.padLeft(4, 'x');

    final accent = walletAccent(wallet);
    final provider = providerById(wallet.provider);

    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.none),
      decoration: BoxDecoration(
        color: white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '**** $maskedTail',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(
                      color: white,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w300),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.caption
                      .copyWith(color: white.withValues(alpha: 0.72)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: provider != null ? Colors.transparent : accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: provider != null
                ? ProviderAvatar(provider: provider, size: 28)
                : Icon(kindIcon(wallet.kind), color: white, size: 18),
          ),
        ],
      ),
    );
  }
}
