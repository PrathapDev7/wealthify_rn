import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/insights_model.dart';
import '../../data/repositories/insights_repository.dart';
import '../preferences/preferences_controller.dart';

final insightsDataProvider = FutureProvider.autoDispose<InsightsModel>(
  (ref) => ref.read(insightsRepositoryProvider).getInsights(),
);

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(insightsDataProvider);

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Insights'),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(
                child: PillButton(
                  label: 'Retry',
                  expand: false,
                  onPressed: () => ref.invalidate(insightsDataProvider),
                ),
              ),
              data: (data) {
                final spendUp = data.expenseDeltaPct >= 0;
                final deltaColor = spendUp ? c.negative : c.accentDark;

                final maxCategory = data.topCategories.isEmpty
                    ? 1.0
                    : data.topCategories
                        .map((cat) => cat.current)
                        .reduce((a, b) => a > b ? a : b)
                        .toDouble();

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(insightsDataProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
                    children: [
                      // Hero — this month spend.
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('This month spend',
                                style:
                                    AppText.label.copyWith(color: c.textSubtle)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(money(data.currentExpense),
                                style:
                                    AppText.titleLg.copyWith(color: c.text)),
                            if (data.month.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(data.month,
                                  style: AppText.bodySm
                                      .copyWith(color: c.textSubtle)),
                            ],
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: deltaColor.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                      spendUp
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward,
                                      size: 14,
                                      color: deltaColor),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text(
                                    '${spendUp ? '+' : ''}${data.expenseDeltaPct.round()}% vs last month',
                                    style: AppText.caption
                                        .copyWith(color: deltaColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Stat cards row.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Income',
                              value: money(data.currentIncome),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              label: 'Savings',
                              value: money(data.savings),
                              sub: '${data.savingsRate.round()}% saved',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatCard(
                              label: 'Projected',
                              value: money(data.projectedExpense),
                              sub: 'month-end',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Top categories.
                      const SectionHeader('Top categories'),
                      const SizedBox(height: AppSpacing.md),
                      if (data.topCategories.isEmpty)
                        Text('No category spending this month',
                            style:
                                AppText.bodySm.copyWith(color: c.textSubtle))
                      else
                        AppCard(
                          child: Column(
                            children: [
                              for (var i = 0;
                                  i < data.topCategories.length;
                                  i++) ...[
                                if (i > 0)
                                  const SizedBox(height: AppSpacing.lg),
                                _CategoryRow(
                                  category: data.topCategories[i],
                                  maxCurrent: maxCategory,
                                  money: money,
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      // Biggest changes.
                      const SectionHeader('Biggest changes'),
                      const SizedBox(height: AppSpacing.md),
                      if (data.movers.isEmpty)
                        Text('No notable changes this month',
                            style:
                                AppText.bodySm.copyWith(color: c.textSubtle))
                      else
                        AppCard(
                          child: Column(
                            children: [
                              for (var i = 0; i < data.movers.length; i++) ...[
                                if (i > 0)
                                  const SizedBox(height: AppSpacing.md),
                                _MoverRow(
                                  mover: data.movers[i],
                                  money: money,
                                ),
                              ],
                            ],
                          ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.sub});

  final String label;
  final String value;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: c.textSubtle)),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.moneySm.copyWith(color: c.text)),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(color: c.textSubtle)),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.maxCurrent,
    required this.money,
  });

  final InsightCategory category;
  final double maxCurrent;
  final String Function(num?) money;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final denom = maxCurrent < 1 ? 1.0 : maxCurrent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(color: c.text)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(money(category.current),
                style: AppText.bodySm.copyWith(color: c.textSubtle)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AppProgressBar(
          value: (category.current / denom).toDouble(),
          color: c.primary,
        ),
      ],
    );
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({required this.mover, required this.money});

  final InsightCategory mover;
  final String Function(num?) money;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final up = mover.delta >= 0;
    final moverColor = up ? c.negative : c.accentDark;
    return Row(
      children: [
        Expanded(
          child: Text(mover.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.bodyMedium.copyWith(color: c.text)),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 14, color: moverColor),
        const SizedBox(width: AppSpacing.xs),
        Text('${up ? '+' : ''}${money(mover.delta)}',
            style: AppText.bodySm.copyWith(color: moverColor)),
        const SizedBox(width: AppSpacing.sm),
        Text('${mover.deltaPct.round()}%',
            style: AppText.caption.copyWith(color: c.textSubtle)),
      ],
    );
  }
}
