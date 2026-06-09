import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/transaction_row.dart';
import '../../core/widgets/wealthify_icon.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/stats_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/budgets_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../preferences/preferences_controller.dart';

final dashboardDataProvider =
    FutureProvider.autoDispose<(StatsModel, BudgetModel)>((ref) async {
  final stats = await ref.read(transactionsRepositoryProvider).getStats();
  final budget = await ref.read(budgetsRepositoryProvider).getBudgets();
  return (stats, budget);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(dashboardDataProvider);

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => Center(
        child: PillButton(
          label: 'Retry',
          expand: false,
          onPressed: () => ref.invalidate(dashboardDataProvider),
        ),
      ),
      data: (data) {
        final (stats, budget) = data;
        final recent = stats.allData.take(6).toList();
        final overall = budget.overall;
        final balance = stats.balance;
        final isFirstRun = recent.isEmpty &&
            stats.totalIncomes == 0 &&
            stats.totalExpenses == 0;
        final walletText = isFirstRun
            ? 'Set Budget'
            : '${balance < 0 ? '-' : ''}${money(balance.abs())}';

        return RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardDataProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 120),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleIconButton(
                      icon: Icons.settings_outlined,
                      onTap: () => context.push(Routes.preferences)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: c.border),
                    ),
                    child: Text(DateFormat('EEE, dd MMM').format(DateTime.now()),
                        style: AppText.bodySm.copyWith(color: c.text)),
                  ),
                  CircleIconButton(
                      icon: Icons.notifications_outlined,
                      onTap: () => context.push(Routes.notifications)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl2),
              Center(
                child: Column(
                  children: [
                    Text('This Month Spend',
                        style: AppText.label.copyWith(color: c.textSubtle)),
                    const SizedBox(height: AppSpacing.xs),
                    _AnimatedMoney(
                      value: stats.totalExpenses,
                      money: money,
                      style: AppText.displayLg.copyWith(color: c.text),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      balance >= 0
                          ? "You're under by ${money(balance)}"
                          : 'Over by ${money(balance.abs())}',
                      style: AppText.bodySm.copyWith(
                          color: balance >= 0 ? c.accentDark : c.negative),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              AppCard(
                onTap: () => context.push(
                    isFirstRun ? Routes.setBudget : Routes.analytics),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration:
                          BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                      child: Center(
                          child: WealthifyIcon('spending_wallet',
                              size: 26, color: c.primary)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text('Spending Wallet',
                          style: AppText.subtitle.copyWith(color: c.text)),
                    ),
                    Text(walletText,
                        style: AppText.subtitle.copyWith(color: c.text)),
                    const SizedBox(width: AppSpacing.sm),
                    Icon(Icons.chevron_right, size: 18, color: c.textSubtle),
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
                          Text('Budget',
                              style: AppText.subtitle.copyWith(color: c.text)),
                          Text(
                              '${money(stats.totalExpenses)} of ${money(overall)}',
                              style: AppText.bodySm.copyWith(color: c.textSubtle)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text('This month',
                          style: AppText.caption.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.sm),
                      AppProgressBar(
                          value: overall == 0
                              ? 0
                              : (stats.totalExpenses / overall).toDouble()),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              _Past7DaysCard(transactions: stats.allData),
              const SizedBox(height: AppSpacing.xl),
              SectionHeader('Recent Transactions',
                  actionLabel: 'See All',
                  onAction: () => context.go(Routes.transactions)),
              const SizedBox(height: AppSpacing.md),
              if (recent.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
                  child: Text('No transactions yet',
                      textAlign: TextAlign.center,
                      style: AppText.bodySm.copyWith(color: c.textSubtle)),
                )
              else
                ...recent.map((t) => TransactionRow(txn: t, money: money)),
            ],
          ),
        );
      },
    );
  }
}

/// Counts the value up from 0 on mount, mirroring RN's `AnimatedCounter`.
class _AnimatedMoney extends StatelessWidget {
  const _AnimatedMoney(
      {required this.value, required this.money, required this.style});

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

/// Last-7-days income vs expense paired bars, mirroring RN's `Past7DaysStats`.
class _Past7DaysCard extends StatelessWidget {
  const _Past7DaysCard({required this.transactions});

  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // Build the 7 day buckets ending today (oldest → newest), matching the
    // RN labels: subtract(i).format('ddd') reversed.
    final today = DateTime.now();
    final days = List.generate(7, (i) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: 6 - i));
      return d;
    });
    final income = List<double>.filled(7, 0);
    final expense = List<double>.filled(7, 0);

    for (final t in transactions) {
      final d = DateTime.tryParse(t.date);
      if (d == null) continue;
      final key = DateTime(d.year, d.month, d.day);
      final idx = days.indexWhere((day) => day == key);
      if (idx < 0) continue;
      if (t.isIncome) {
        income[idx] += t.amount.toDouble();
      } else {
        expense[idx] += t.amount.toDouble();
      }
    }

    final maxVal = [
      ...income,
      ...expense,
    ].fold<double>(0, (m, v) => v > m ? v : m);
    final maxY = maxVal <= 0 ? 10.0 : maxVal * 1.2;

    final groups = <BarChartGroupData>[
      for (var i = 0; i < 7; i++)
        BarChartGroupData(
          x: i,
          barsSpace: 3,
          barRods: [
            BarChartRodData(
                toY: income[i],
                color: c.accentDark,
                width: 7,
                borderRadius: BorderRadius.circular(3)),
            BarChartRodData(
                toY: expense[i],
                color: c.negative,
                width: 7,
                borderRadius: BorderRadius.circular(3)),
          ],
        ),
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Past 7 Days Stats',
              style: AppText.subtitle.copyWith(color: c.text)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _legendDot(c.accentDark),
              const SizedBox(width: 4),
              Text('Income', style: AppText.caption.copyWith(color: c.textSubtle)),
              const SizedBox(width: AppSpacing.md),
              _legendDot(c.negative),
              const SizedBox(width: 4),
              Text('Expense',
                  style: AppText.caption.copyWith(color: c.textSubtle)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= days.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(DateFormat('EEE').format(days[i]),
                              style: AppText.caption
                                  .copyWith(color: c.textSubtle)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: groups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
