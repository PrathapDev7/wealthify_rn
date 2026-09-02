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
import '../fitness/fitness_screen.dart';
import '../wallets/widgets/home_wallet_card.dart';
import '../wallets/widgets/wallet_card_stack.dart';

final dashboardDataProvider =
    FutureProvider.autoDispose<(StatsModel, BudgetModel)>((ref) async {
      ref.watch(dataRefreshProvider); // refetch after any transaction mutation
      final stats = await ref.read(transactionsRepositoryProvider).getStats();
      final budget = await ref.read(budgetsRepositoryProvider).getBudgets();
      return (stats, budget);
    });

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

/// Home tab root: a persistent Wealthify/Healthify/Fitness switcher pinned
/// above the finance dashboard, the calorie tracker or the fitness home.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeApp = ref.watch(activeAppProvider);
    final switcher = Padding(
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
    );
    if (activeApp == ActiveApp.fitness) {
      return Column(
        children: [
          switcher,
          const Expanded(child: FitnessHome()),
        ],
      );
    }
    if (activeApp == ActiveApp.healthify) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        children: [
          Expanded(
            child: HealthifyTheme(
              child: CalorieScreen(
                embedded: true,
                heroWrapper: (ctx, hero) => _heroBackdrop(
                  ctx,
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Theme(
                        data: isDark ? AppTheme.dark() : AppTheme.light(),
                        child: switcher,
                      ),
                      hero,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return _WealthifyDashboard(switcher: switcher);
  }
}

/// Wraps [content] with a green gradient backdrop that bleeds up behind the
/// status bar and peeks a little past [content]'s own bottom edge (so the
/// wallet card's ghost stack layers stay backed by color). Sized purely off
/// [content]'s natural height via top/bottom-relative Positioned — no guessed
/// fixed height needed.
Widget _heroBackdrop(BuildContext context, Widget content) {
  final c = context.colors;
  final topInset = MediaQuery.of(context).padding.top;
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Positioned(
        top: -topInset,
        left: 0,
        right: 0,
        bottom: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c.primary, c.primaryDark, c.primaryDarker],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppRadius.xl2),
              bottomRight: Radius.circular(AppRadius.xl2),
            ),
          ),
        ),
      ),
      content,
    ],
  );
}

class _WealthifyDashboard extends ConsumerStatefulWidget {
  const _WealthifyDashboard({required this.switcher});

  final Widget switcher;

  @override
  ConsumerState<_WealthifyDashboard> createState() =>
      _WealthifyDashboardState();
}

class _WealthifyDashboardState extends ConsumerState<_WealthifyDashboard>
    with SingleTickerProviderStateMixin {
  int _walletIndex = 0;
  bool _indexSeeded = false;
  bool _swipeLocked = false;
  late final AnimationController _ghostAnimCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _ghostAnimCtrl.reverse();
      }
    });

  @override
  void dispose() {
    _ghostAnimCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(dashboardDataProvider);

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

    if (!_indexSeeded && primaryWallet != null) {
      final idx = wallets.indexOf(primaryWallet);
      if (idx >= 0) _walletIndex = idx;
      _indexSeeded = true;
    }
    final safeIndex = wallets.isEmpty
        ? 0
        : _walletIndex.clamp(0, wallets.length - 1);
    final displayedWallet = wallets.isEmpty ? primaryWallet : wallets[safeIndex];

    return async.when(
      loading: () => Column(
        children: [
          _heroBackdrop(
            context,
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.switcher,
                const _DashboardSkeletonHero(),
              ],
            ),
          ),
          const Expanded(child: _DashboardSkeletonBody()),
        ],
      ),
      error: (e, _) => Column(
        children: [
          widget.switcher,
          Expanded(
            child: Center(
              child: PillButton(
                label: 'Retry',
                expand: false,
                onPressed: () => ref.invalidate(dashboardDataProvider),
              ),
            ),
          ),
        ],
      ),
      data: (data) {
        final c = context.colors;
        final (stats, budget) = data;
        final overall = budget.overall;
        final isFirstRun =
            stats.allData.isEmpty &&
            stats.totalIncomes == 0 &&
            stats.totalExpenses == 0;

        String balanceTextFor(num walletBalance) => isFirstRun
            ? 'Set Budget'
            : '${walletBalance < 0 ? '-' : ''}${money(walletBalance.abs())}';

        final displayStats = displayedWallet != null
            ? _statsForWallet(stats, displayedWallet.id)
            : stats;
        final recent = displayStats.allData.take(6).toList();
        final balance = displayStats.balance;
        final walletText = balanceTextFor(balance);

        final walletCardChild = displayedWallet != null
            ? HomeWalletCard(wallet: displayedWallet)
            : Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Spending Wallet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium
                            .copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        walletText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.bodyMedium
                            .copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.chevron_right,
                        size: 18, color: Colors.white70),
                  ],
                ),
              );

        final statusPositive = balance >= 0;
        final statusMessage = isFirstRun
            ? null
            : (statusPositive
                ? "Under budget by ${money(balance)}"
                : 'Over budget by ${money(balance.abs())}');

        final heroContent = Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.none),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BalanceHero(
                balanceText: walletText,
                statusMessage: statusMessage,
                statusPositive: statusPositive,
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: AnimatedBuilder(
                  animation: _ghostAnimCtrl,
                  builder: (context, child) {
                    final backScale = 1.0 + (_ghostAnimCtrl.value * 0.2);
                    final middleScale = 1.0 + (_ghostAnimCtrl.value * 1.0);
                    return WalletCardStack(
                      backGhostScale: backScale,
                      middleGhostScale: middleScale,
                      child: ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: 0.75,
                          child: Stack(
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => context.push(
                                  isFirstRun ? Routes.setBudget : Routes.analytics,
                                ),
                                onVerticalDragStart: (_) {
                                  _swipeLocked = false;
                                },
                                onVerticalDragUpdate: (details) {
                                  if (wallets.length <= 1 || _swipeLocked) return;
                                  if (details.delta.dy < -5) {
                                    _swipeLocked = true;
                                    _ghostAnimCtrl.forward(from: 0);
                                    final next = (safeIndex + 1) % wallets.length;
                                    setState(() => _walletIndex = next);
                                  } else if (details.delta.dy > 5) {
                                    _swipeLocked = true;
                                    _ghostAnimCtrl.forward(from: 0);
                                    final prev = (safeIndex - 1 + wallets.length) %
                                        wallets.length;
                                    setState(() => _walletIndex = prev);
                                  }
                                },
                                onVerticalDragEnd: (_) {
                                  _swipeLocked = false;
                                },
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  switchInCurve: Curves.easeOut,
                                  switchOutCurve: Curves.easeIn,
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: ScaleTransition(
                                        scale: Tween<double>(
                                          begin: 0.92,
                                          end: 1.0,
                                        ).animate(animation),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey(safeIndex),
                                    child: walletCardChild,
                                  ),
                                ),
                              ),
                              if (wallets.length > 1)
                                Positioned(
                                  right: 8,
                                  top: 48,
                                  child: IconButton(
                                    onPressed: () {
                                      _ghostAnimCtrl.forward(from: 0);
                                      final next = (safeIndex + 1) % wallets.length;
                                      setState(() => _walletIndex = next);
                                    },
                                    icon: Icon(
                                      Icons.swap_vert_rounded,
                                      size: 20,
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );

        return Column(
          children: [
            _heroBackdrop(
              context,
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [widget.switcher, heroContent],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(dashboardDataProvider.future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.screenBottomInset,
                  ),
                  children: [
                    _DepositWithdrawRow(
                      onDeposit: () => context
                          .push('${Routes.addTransaction}?type=income'),
                      onWithdraw: () => context
                          .push('${Routes.addTransaction}?type=expense'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                                  style:
                                      AppText.subtitle.copyWith(color: c.text),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Flexible(
                                  child: Text(
                                    '${money(displayStats.totalExpenses)} of ${money(overall)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: AppText.bodySm
                                        .copyWith(color: c.textSubtle),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'This month',
                              style:
                                  AppText.caption.copyWith(color: c.textSubtle),
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
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xl2),
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
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Profile avatar (initials) + notification bell, pinned above the balance
/// hero. Sits on the green gradient backdrop, so the bell is styled as a
/// translucent light circle rather than the theme-adaptive default.
/// Centered "Balance" label + big animated amount + a small under/over-spend
/// status pill. Sits on the green gradient backdrop, so everything renders
/// in white/translucent-white instead of the theme's text colors.
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({
    required this.balanceText,
    required this.statusMessage,
    required this.statusPositive,
  });

  final String balanceText;
  final String? statusMessage;
  final bool statusPositive;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text('Balance',
              style: AppText.label
                  .copyWith(color: Colors.white.withValues(alpha: 0.75))),
          const SizedBox(height: 0),
          Text(balanceText,
              style: AppText.money.copyWith(color: Colors.white)),
          if (statusMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusPositive
                        ? Icons.check_circle_outline_rounded
                        : Icons.arrow_upward_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    statusMessage!,
                    style: AppText.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Deposit / Withdraw pill pair, sitting right under the stacked wallet
/// card — wired to the same add-transaction route the Quick Add sheet uses.
class _DepositWithdrawRow extends StatelessWidget {
  const _DepositWithdrawRow({
    required this.onDeposit,
    required this.onWithdraw,
  });

  final VoidCallback onDeposit;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: _ActionPill(
            icon: Icons.arrow_upward_rounded,
            iconColor: c.primary,
            label: 'Deposit',
            onTap: onDeposit,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _ActionPill(
            icon: Icons.arrow_downward_rounded,
            iconColor: c.negative,
            label: 'Withdraw',
            onTap: onWithdraw,
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: const Color(0xFF2A2A2A),
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xs),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border.all(color: const Color(0xFF3A3A3A)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero portion of the skeleton — sits inside the green gradient backdrop.
class _DashboardSkeletonHero extends StatelessWidget {
  const _DashboardSkeletonHero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.none),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                const SkeletonLine(width: 110, height: 12),
                const SizedBox(height: 0),
                const SkeletonLine(width: 160, height: 36),
                const SizedBox(height: AppSpacing.sm),
                SkeletonBox(
                  width: 140,
                  height: 26,
                  radius: AppRadius.pill,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: WalletCardStack(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 0.75,
                  child: AppCard(
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Body portion of the skeleton — budget card + recent transactions.
class _DashboardSkeletonBody extends StatelessWidget {
  const _DashboardSkeletonBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.screenBottomInset,
      ),
      children: [
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
