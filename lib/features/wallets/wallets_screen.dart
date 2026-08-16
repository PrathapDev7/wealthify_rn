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
import '../../core/widgets/skeleton.dart';
import '../../data/repositories/wallets_repository.dart';
import '../preferences/preferences_controller.dart';
import 'widgets/wallet_card_visual.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(walletsListProvider);

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Wallets'),
          Expanded(
            child: async.when(
              loading: () => const _WalletsSkeleton(),
              error: (e, _) => Center(
                child: PillButton(
                  label: 'Retry',
                  expand: false,
                  onPressed: () => ref.invalidate(walletsListProvider),
                ),
              ),
              data: (wallets) {
                final total = wallets.fold<num>(0, (sum, w) => sum + w.balance);
                // Keep the local default pref in sync with the server's
                // primary wallet so pickers default to the right account.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    ref
                        .read(preferencesProvider.notifier)
                        .syncDefaultFromWallets(wallets);
                  }
                });
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
                        ...wallets.map((w) {
                          final isPrimary = w.isPrimary;
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Only the card opens the editor — the row below
                                // keeps its own tap target for "Set as primary".
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => context.push(Routes.editWallet,
                                      extra: w),
                                  child: WalletCardVisual(
                                      wallet: w,
                                      balanceText: money(w.balance)),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'in ${money(w.income)} · out ${money(w.expense)}',
                                          style: AppText.caption
                                              .copyWith(color: c.textSubtle),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      _DefaultControl(
                                        isDefault: isPrimary,
                                        onSet: () async {
                                          await ref
                                              .read(walletsRepositoryProvider)
                                              .setPrimaryWallet(w.id);
                                          if (context.mounted) {
                                            ref
                                                .read(preferencesProvider
                                                    .notifier)
                                                .setDefaultWallet(w.id);
                                            ref.invalidate(walletsListProvider);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
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

/// Loading placeholder mirroring the loaded layout: a total-balance card,
/// a few wallet-card-shaped blocks, and a caption row under each.
class _WalletsSkeleton extends StatelessWidget {
  const _WalletsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonLine(width: 90, height: 12),
              const SizedBox(height: AppSpacing.xs),
              const SkeletonLine(width: 160, height: 28),
              const SizedBox(height: AppSpacing.xs),
              const SkeletonLine(width: 100, height: 12),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Roughly matches WalletCardVisual's height (icon row +
                // masked number + holder/balance footer).
                const SkeletonBox(
                    width: double.infinity,
                    height: 150,
                    radius: AppRadius.md),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Row(
                    children: [
                      const Expanded(
                        child: SkeletonLine(width: 140, height: 12),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const SkeletonBox(
                          width: 90, height: 18, radius: AppRadius.pill),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Per-wallet trailing control: a "Primary" badge for the active primary wallet,
/// or a tappable "Set as primary" affordance for the rest.
class _DefaultControl extends StatelessWidget {
  const _DefaultControl({required this.isDefault, this.onSet});

  final bool isDefault;
  final VoidCallback? onSet;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (isDefault) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
        decoration: BoxDecoration(
          color: c.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 14, color: c.primary),
            const SizedBox(width: 4),
            Text('Primary',
                style: AppText.caption
                    .copyWith(color: c.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSet,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_outline_rounded, size: 14, color: c.textSubtle),
          const SizedBox(width: 4),
          Text('Set as primary',
              style: AppText.caption
                  .copyWith(color: c.textSubtle, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
