import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/transaction_row.dart';
import '../../data/models/stats_model.dart';
import '../../data/repositories/transactions_repository.dart';
import '../preferences/preferences_controller.dart';

final transactionsListProvider =
    FutureProvider.autoDispose<StatsModel>((ref) async {
  return ref.read(transactionsRepositoryProvider).getStats();
});

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(transactionsListProvider);

    return async.when(
      loading: () => const LoadingView(),
      error: (e, _) => const EmptyState(
          icon: Icons.error_outline, title: 'Could not load transactions'),
      data: (stats) {
        final items = stats.allData;
        return RefreshIndicator(
          onRefresh: () => ref.refresh(transactionsListProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 120),
            children: [
              Center(
                  child: Text('Transactions',
                      style: AppText.screenTitle.copyWith(color: c.text))),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Row(
                  children: [
                    _summary(c, 'Income', money(stats.totalIncomes), c.accentDark),
                    Container(width: 1, height: 32, color: c.divider),
                    _summary(
                        c, 'Expense', money(stats.totalExpenses), c.negative),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionHeader('This month'),
              const SizedBox(height: AppSpacing.md),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xl2),
                  child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions yet',
                      message: 'Tap + to add your first entry.'),
                )
              else
                ...items.map((t) => TransactionRow(txn: t, money: money)),
            ],
          ),
        );
      },
    );
  }

  Widget _summary(AppColors c, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppText.caption.copyWith(color: c.textSubtle)),
          const SizedBox(height: 2),
          Text(value, style: AppText.subtitle.copyWith(color: color)),
        ],
      ),
    );
  }
}
