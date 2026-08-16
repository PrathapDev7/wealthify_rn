import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_switcher.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/transaction_row.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/stats_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/budgets_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../data/repositories/wallets_repository.dart';
import '../preferences/preferences_controller.dart';
import '../calories/calorie_screen.dart';
import '../wallets/widgets/wallet_card_visual.dart';

final dashboardDataProvider =
    FutureProvider.autoDispose<(StatsModel, BudgetModel)>((ref) async {
      ref.watch(dataRefreshProvider); // refetch after any transaction mutation
      final stats = await ref.read(transactionsRepositoryProvider).getStats();
      final budget = await ref.read(budgetsRepositoryProvider).getBudgets();
      return (stats, budget);
    });

/// Wallet the dashboard's stats/recent-transactions are scoped to when the
/// wallet card switches to carousel mode (more than one wallet). Null falls
/// back to the primary wallet.
final dashboardWalletFilterProvider =
    NotifierProvider.autoDispose<DashboardWalletFilterController, String?>(
      DashboardWalletFilterController.new,
    );

class DashboardWalletFilterController extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String walletId) => state = walletId;
}

/// Narrows [stats] (already this-month-only from the server) down to just
/// [walletId]'s entries, recomputing totals from the filtered transactions.
StatsModel _statsForWallet(StatsModel stats, String walletId) {
  final items = stats.allData.where((t) => t.account == walletId).toList();
  final incomes =
      items.where((t) => t.isIncome).fold<num>(0, (sum, t) => sum + t.amount);
  final expenses = items
      .where((t) => !t.isIncome)
      .fold<num>(0, (sum, t) => sum + t.amount);
  return StatsModel(
    allData: items,
    totalIncomes: incomes,
    totalExpenses: expenses,
  );
}

/// Home tab root: a persistent Wealthify/Healthify switcher pinned above
/// either the finance dashboard or the calorie tracker.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeApp = ref.watch(activeAppProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: AppSwitcher(
            active: activeApp,
            onChanged: (app) => ref.read(activeAppProvider.notifier).set(app),
          ),
        ),
        Expanded(
          child: activeApp == ActiveApp.healthify
              ? const HealthifyTheme(child: CalorieScreen(embedded: true))
              : const _WealthifyDashboard(),
        ),
      ],
    );
  }
}

class _WealthifyDashboard extends ConsumerWidget {
  const _WealthifyDashboard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final prefs = ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(dashboardDataProvider);

    // The chosen default ("primary") wallet, if any, drives the wallet-card icon.
    // Prefer the locally-synced default; fall back to the server's isPrimary
    // flag so the card shows even before the user has opened the Wallets tab.
    final wallets = ref.watch(walletsListProvider).asData?.value ?? const [];
    final defaultWalletId = prefs.defaultWallet;
    WalletModel? primaryWallet;
    if (defaultWalletId != null && defaultWalletId.isNotEmpty) {
      for (final w in wallets) {
        if (w.id == defaultWalletId) {
          primaryWallet = w;
          break;
        }
      }
    }
    if (primaryWallet == null) {
      for (final w in wallets) {
        if (w.isPrimary) {
          primaryWallet = w;
          break;
        }
      }
    }

    return async.when(
      loading: () => const _DashboardSkeleton(),
      error: (e, _) => Center(
        child: PillButton(
          label: 'Retry',
          expand: false,
          onPressed: () => ref.invalidate(dashboardDataProvider),
        ),
      ),
      data: (data) {
        final (stats, budget) = data;
        final overall = budget.overall;
        // First-run detection stays global — a wallet with no activity this
        // month shouldn't itself look like a brand-new account.
        final isFirstRun =
            stats.allData.isEmpty &&
            stats.totalIncomes == 0 &&
            stats.totalExpenses == 0;

        String balanceTextFor(num walletBalance) => isFirstRun
            ? 'Set Budget'
            : '${walletBalance < 0 ? '-' : ''}${money(walletBalance.abs())}';

        // More than one wallet → the card becomes a carousel, and whichever
        // wallet is centered scopes the spend/balance/recent-transactions
        // sections below to just that wallet's entries.
        final showCarousel = wallets.length > 1;
        final selectedWalletId = showCarousel
            ? (ref.watch(dashboardWalletFilterProvider) ??
                primaryWallet?.id ??
                wallets.first.id)
            : null;
        final displayStats = selectedWalletId != null
            ? _statsForWallet(stats, selectedWalletId)
            : stats;
        final recent = displayStats.allData.take(6).toList();
        final balance = displayStats.balance;
        final walletText = balanceTextFor(balance);

        return RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardDataProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.screenBottomInset,
            ),
            children: [
              if (showCarousel)
                _WalletCarousel(
                  wallets: wallets,
                  selectedWalletId: selectedWalletId!,
                  balanceTextFor: (w) => balanceTextFor(
                    _statsForWallet(stats, w.id).balance,
                  ),
                  onTap: () => context.push(
                    isFirstRun ? Routes.setBudget : Routes.analytics,
                  ),
                  onWalletChanged: (id) =>
                      ref.read(dashboardWalletFilterProvider.notifier).select(id),
                )
              else
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.push(
                    isFirstRun ? Routes.setBudget : Routes.analytics,
                  ),
                  child: primaryWallet != null
                      ? WalletCardVisual(
                          wallet: primaryWallet,
                          balanceText: walletText,
                          compact: true,
                        )
                      : AppCard(
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: c.primarySoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.account_balance_wallet_outlined,
                                    size: 24,
                                    color: c.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'Spending Wallet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppText.subtitle.copyWith(color: c.text),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  walletText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      AppText.subtitle.copyWith(color: c.text),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(Icons.chevron_right,
                                  size: 18, color: c.textSubtle),
                            ],
                          ),
                        ),
                ),
              const SizedBox(height: AppSpacing.xl2),
              Center(
                child: Column(
                  children: [
                    Text(
                      'This Month Spend',
                      style: AppText.label.copyWith(color: c.textSubtle),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _AnimatedMoney(
                      value: displayStats.totalExpenses,
                      money: money,
                      style: AppText.displayLg.copyWith(color: c.text),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      balance >= 0
                          ? "You're under by ${money(balance)}"
                          : 'Over by ${money(balance.abs())}',
                      style: AppText.bodySm.copyWith(
                        color: balance >= 0 ? c.accentDark : c.negative,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (overall != null && overall > 0)
                AppCard(
                  onTap: () => context.push(Routes.budgets),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Budget',
                            style: AppText.subtitle.copyWith(color: c.text),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              '${money(displayStats.totalExpenses)} of ${money(overall)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: AppText.bodySm.copyWith(color: c.textSubtle),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'This month',
                        style: AppText.caption.copyWith(color: c.textSubtle),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppProgressBar(
                        value: overall == 0
                            ? 0
                            : (displayStats.totalExpenses / overall)
                                .toDouble(),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                'Recent Transactions',
                actionLabel: 'See All',
                onAction: () => context.go(Routes.transactions),
              ),
              const SizedBox(height: AppSpacing.md),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
                  child: Text(
                    'No transactions yet',
                    textAlign: TextAlign.center,
                    style: AppText.bodySm.copyWith(color: c.textSubtle),
                  ),
                )
              else
                ...recent.map(
                  (t) => TransactionRow(
                    txn: t,
                    money: money,
                    onTap: () =>
                        context.push(Routes.transactionDetail, extra: t),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Mirrors [_WealthifyDashboard]'s data layout: wallet card, centered spend
/// label + amount, budget card, recent-transactions section.
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.screenBottomInset,
      ),
      children: [
        AppCard(
          child: Row(
            children: [
              const SkeletonCircle(size: 42),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: SkeletonLine(width: 120)),
              const SizedBox(width: AppSpacing.sm),
              const SkeletonLine(width: 60),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl2),
        Center(
          child: Column(
            children: [
              const SkeletonLine(width: 110, height: 12),
              const SizedBox(height: AppSpacing.sm),
              const SkeletonLine(width: 160, height: 36),
              const SizedBox(height: AppSpacing.sm),
              const SkeletonLine(width: 140, height: 12),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SkeletonLine(width: 70),
                  SkeletonLine(width: 100),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const SkeletonLine(width: 90, height: 10),
              const SizedBox(height: AppSpacing.sm),
              const SkeletonBox(height: 8, width: double.infinity),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SkeletonLine(width: 140, height: 16),
            SkeletonLine(width: 50, height: 12),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < 5; i++) const _TransactionRowSkeleton(),
      ],
    );
  }
}

/// Mirrors [TransactionRow]'s 40x40 icon box, 2-line text column, and
/// right-aligned amount.
class _TransactionRowSkeleton extends StatelessWidget {
  const _TransactionRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          const SkeletonBox(width: 40, height: 40, radius: AppRadius.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 100),
                const SizedBox(height: 6),
                SkeletonLine(width: 70, height: 10),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SkeletonLine(width: 50),
        ],
      ),
    );
  }
}

/// Counts the value up from 0 on mount, mirroring RN's `AnimatedCounter`.
class _AnimatedMoney extends StatelessWidget {
  const _AnimatedMoney({
    required this.value,
    required this.money,
    required this.style,
  });

  final num value;
  final String Function(num?) money;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (_, v, _) => Text(money(v.floorToDouble()), style: style),
    );
  }
}

/// Loops infinitely through [wallets]' compact cards; the centered wallet
/// scopes the dashboard's stats/recent-transactions sections via
/// [onWalletChanged].
class _WalletCarousel extends StatefulWidget {
  const _WalletCarousel({
    required this.wallets,
    required this.selectedWalletId,
    required this.balanceTextFor,
    required this.onTap,
    required this.onWalletChanged,
  });

  final List<WalletModel> wallets;
  final String selectedWalletId;
  final String Function(WalletModel) balanceTextFor;
  final VoidCallback onTap;
  final ValueChanged<String> onWalletChanged;

  @override
  State<_WalletCarousel> createState() => _WalletCarouselState();
}

class _WalletCarouselState extends State<_WalletCarousel> {
  // Large virtual page count with modulo indexing simulates an infinite
  // loop — PageView has no native loop mode.
  static const _loopSpan = 2000;

  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    final n = widget.wallets.length;
    final start = widget.wallets.indexWhere((w) => w.id == widget.selectedWalletId);
    _index = start < 0 ? 0 : start;
    _controller = PageController(
      initialPage: (n * (_loopSpan ~/ 2)) + _index,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final n = widget.wallets.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 84,
          child: PageView.builder(
            controller: _controller,
            itemCount: n * _loopSpan,
            onPageChanged: (i) {
              final idx = i % n;
              final wallet = widget.wallets[idx];
              setState(() => _index = idx);
              widget.onWalletChanged(wallet.id);
            },
            itemBuilder: (_, i) {
              final wallet = widget.wallets[i % n];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: WalletCardVisual(
                  wallet: wallet,
                  balanceText: widget.balanceTextFor(wallet),
                  compact: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            n,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _index ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _index ? c.primary : c.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
