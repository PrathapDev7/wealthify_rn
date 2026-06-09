import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/misc.dart';
import '../preferences/preferences_controller.dart';
import '../transactions/transactions_screen.dart' show transactionsListProvider;

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(transactionsListProvider);

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) =>
          const EmptyState(icon: Icons.error_outline, title: 'Could not load'),
      data: (stats) {
        final income = stats.totalIncomes.toDouble();
        final expense = stats.totalExpenses.toDouble();
        final maxY = (income > expense ? income : expense);
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 120),
          children: [
            Center(
                child: Text('Analytics',
                    style: AppText.screenTitle.copyWith(color: c.text))),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    maxY: maxY <= 0 ? 10 : maxY * 1.2,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
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
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(value == 0 ? 'Income' : 'Expense',
                                style: AppText.caption
                                    .copyWith(color: c.textSubtle)),
                          ),
                        ),
                      ),
                    ),
                    barGroups: [
                      BarChartGroupData(x: 0, barRods: [
                        BarChartRodData(
                            toY: income,
                            color: c.accentDark,
                            width: 36,
                            borderRadius: BorderRadius.circular(6)),
                      ]),
                      BarChartGroupData(x: 1, barRods: [
                        BarChartRodData(
                            toY: expense,
                            color: c.negative,
                            width: 36,
                            borderRadius: BorderRadius.circular(6)),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                    child: _statCard(
                        c, 'Income', money(stats.totalIncomes), c.accentDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                    child: _statCard(
                        c, 'Expense', money(stats.totalExpenses), c.negative)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _statCard(c, 'Balance', money(stats.balance), c.primary),
          ],
        );
      },
    );
  }

  Widget _statCard(AppColors c, String label, String value, Color color) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label.copyWith(color: c.textSubtle)),
          const SizedBox(height: AppSpacing.xs),
          Text(value, style: AppText.titleLg.copyWith(color: color)),
        ],
      ),
    );
  }
}
