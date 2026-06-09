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
import '../../data/models/budget_model.dart';
import '../../data/models/stats_model.dart';
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
                    Text(money(stats.totalExpenses),
                        style: AppText.displayLg.copyWith(color: c.text)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      stats.balance >= 0
                          ? "You're under by ${money(stats.balance)}"
                          : 'Over by ${money(stats.balance.abs())}',
                      style: AppText.bodySm.copyWith(
                          color: stats.balance >= 0 ? c.accentDark : c.negative),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
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
