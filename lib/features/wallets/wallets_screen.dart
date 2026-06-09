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
import '../../data/repositories/wallets_repository.dart';
import '../preferences/preferences_controller.dart';
import 'widgets/wallet_card_visual.dart';

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
                        const EmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'No wallets yet',
                          message:
                              'Add a cash, bank, card or wallet account to track balances separately.',
                        )
                      else
                        ...wallets.map((w) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.lg),
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => context.push(Routes.editWallet,
                                    extra: w),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    WalletCardVisual(
                                        wallet: w,
                                        balanceText: money(w.balance)),
                                    const SizedBox(height: AppSpacing.xs),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xs),
                                      child: Text(
                                        'in ${money(w.income)} · out ${money(w.expense)}',
                                        style: AppText.caption
                                            .copyWith(color: c.textSubtle),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      const SizedBox(height: AppSpacing.sm),
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
