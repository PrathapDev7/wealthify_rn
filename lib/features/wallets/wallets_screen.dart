import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/wallets_repository.dart';
import '../preferences/preferences_controller.dart';

final walletsListProvider = FutureProvider.autoDispose<List<WalletModel>>(
  (ref) => ref.read(walletsRepositoryProvider).getWallets(),
);

IconData _kindIcon(String kind) => switch (kind) {
      'bank' => Icons.account_balance_outlined,
      'card' => Icons.credit_card,
      'wallet' => Icons.account_balance_wallet_outlined,
      _ => Icons.payments_outlined,
    };

String _kindLabel(String kind) => switch (kind) {
      'bank' => 'Bank',
      'card' => 'Card',
      'wallet' => 'Wallet',
      _ => 'Cash',
    };

/// Parses a wallet's stored hex accent (e.g. '#7B3FF2' / '7B3FF2'), or null.
Color? _parseColor(String? hex) {
  if (hex == null) return null;
  var h = hex.trim().replaceFirst('#', '');
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return null;
  final value = int.tryParse(h, radix: 16);
  return value == null ? null : Color(value);
}

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(walletsListProvider);

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Wallets'),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(
                child: PillButton(
                  label: 'Retry',
                  expand: false,
                  onPressed: () => ref.invalidate(walletsListProvider),
                ),
              ),
              data: (wallets) {
                final total = wallets.fold<num>(0, (sum, w) => sum + w.balance);
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(walletsListProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total balance',
                                style: AppText.label
                                    .copyWith(color: c.textSubtle)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              money(total),
                              style: AppText.titleLg.copyWith(
                                  color: total < 0 ? c.negative : c.text),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${wallets.length} ${wallets.length == 1 ? 'account' : 'accounts'}',
                              style: AppText.bodySm
                                  .copyWith(color: c.textSubtle),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (wallets.isEmpty)
                        EmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'No wallets yet',
                          message:
                              'Add a cash, bank, card or wallet account to track balances separately.',
                        )
                      else
                        ...wallets.map((w) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _WalletCard(wallet: w, money: money),
                            )),
                      const SizedBox(height: AppSpacing.lg),
                      PillButton(
                        label: 'Add wallet',
                        onPressed: () => context.push(Routes.editWallet),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.wallet, required this.money});

  final WalletModel wallet;
  final String Function(num?) money;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final negative = wallet.balance < 0;
    final accent = _parseColor(wallet.color) ?? c.primary;
    return AppCard(
      onTap: () => context.push(Routes.editWallet, extra: wallet),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(_kindIcon(wallet.kind), size: 18, color: accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium.copyWith(color: c.text)),
                    Text(_kindLabel(wallet.kind),
                        style: AppText.caption.copyWith(color: c.textSubtle)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(money(wallet.balance),
                  style: AppText.moneySm
                      .copyWith(color: negative ? c.negative : c.text)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'in ${money(wallet.income)} · out ${money(wallet.expense)}',
            style: AppText.caption.copyWith(color: c.textSubtle),
          ),
        ],
      ),
    );
  }
}
