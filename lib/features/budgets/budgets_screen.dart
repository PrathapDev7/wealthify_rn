import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/category_icon.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/stats_model.dart';
import '../../data/repositories/budgets_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../preferences/preferences_controller.dart';

final budgetsDataProvider =
    FutureProvider.autoDispose<(BudgetModel, StatsModel)>((ref) async {
  final budget = await ref.read(budgetsRepositoryProvider).getBudgets();
  final stats = await ref.read(transactionsRepositoryProvider).getStats();
  return (budget, stats);
});

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(budgetsDataProvider);

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Budgets'),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(
                child: PillButton(
                  label: 'Retry',
                  expand: false,
                  onPressed: () => ref.invalidate(budgetsDataProvider),
                ),
              ),
              data: (data) {
                final (budget, stats) = data;

                // Sum this-month expense spend per category.
                final spentByCategory = <String, num>{};
                for (final t in stats.allData) {
                  if (t.isIncome) continue;
                  spentByCategory[t.category] =
                      (spentByCategory[t.category] ?? 0) + t.amount;
                }

                final overall = budget.overall;
                // Sort category rows by spend ratio descending (mirrors RN).
                final categoryKeys = budget.budgets.keys
                    .where((k) => k != 'Overall')
                    .toList()
                  ..sort((a, b) {
                    final ra = (spentByCategory[a] ?? 0) /
                        ((budget.budgets[a] ?? 0) == 0
                            ? 1
                            : budget.budgets[a]!);
                    final rb = (spentByCategory[b] ?? 0) /
                        ((budget.budgets[b] ?? 0) == 0
                            ? 1
                            : budget.budgets[b]!);
                    return rb.compareTo(ra);
                  });

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(budgetsDataProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
                    children: [
                      if (overall != null)
                        AppCard(
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overall this month',
                                  style: AppText.label
                                      .copyWith(color: c.textSubtle)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${money(stats.totalExpenses)} / ${money(overall)}',
                                style:
                                    AppText.titleLg.copyWith(color: c.text),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppProgressBar(
                                value: overall == 0
                                    ? 0
                                    : (stats.totalExpenses / overall)
                                        .toDouble(),
                              ),
                            ],
                          ),
                        ),
                      if (categoryKeys.isEmpty)
                        EmptyState(
                          icon: Icons.pie_chart_outline,
                          title: 'No category budgets yet',
                          message:
                              'Set a monthly limit per category to track your spending against it.',
                        )
                      else
                        ...categoryKeys.map((key) {
                          final limit = budget.budgets[key]!;
                          final spent = spentByCategory[key] ?? 0;
                          final remaining = limit - spent;
                          final over = remaining < 0;
                          final iconSpec = resolveCategoryIcon(key, colors: c);
                          return AppCard(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            onTap: () => context.push(
                                '${Routes.setBudget}?category=${Uri.encodeComponent(key)}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 30,
                                      height: 30,
                                      alignment: Alignment.center,
                                      margin: const EdgeInsets.only(
                                          right: AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: iconSpec.color
                                            .withValues(alpha: 0.13),
                                        shape: BoxShape.circle,
                                      ),
                                      child: WealthifyIcon(iconSpec.name,
                                          size: 16),
                                    ),
                                    Expanded(
                                      child: Text(
                                        key,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.bodyMedium
                                            .copyWith(color: c.text),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      over
                                          ? '${money(remaining.abs())} over'
                                          : '${money(remaining)} left',
                                      style: AppText.bodySm.copyWith(
                                          color:
                                              over ? c.negative : c.textSubtle),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppProgressBar(
                                  value: limit == 0
                                      ? 0
                                      : (spent / limit).toDouble(),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${money(spent)} of ${money(limit)}',
                                  style: AppText.caption
                                      .copyWith(color: c.textSubtle),
                                ),
                              ],
                            ),
                          );
                        }),
                      const SizedBox(height: AppSpacing.lg),
                      PillButton(
                        label: 'Set / edit a budget',
                        variant: PillVariant.secondary,
                        onPressed: () => context.push(Routes.setBudget),
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
