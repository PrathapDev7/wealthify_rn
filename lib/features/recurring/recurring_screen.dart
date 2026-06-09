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
import '../../data/models/recurring_model.dart';
import '../../data/repositories/recurring_repository.dart';
import '../auth/auth_screen.dart';
import '../preferences/preferences_controller.dart';

final recurringListProvider = FutureProvider.autoDispose<List<RecurringModel>>(
  (ref) => ref.read(recurringRepositoryProvider).getRecurring(),
);

/// Human-readable cadence like "Every day" / "Every 2 weeks".
/// Mirrors `describeFrequency` in `legacy_rn/app/recurring.tsx`.
String frequencyLabel(int interval, String frequency) {
  final n = interval > 0 ? interval : 1;
  const unit = {
    'daily': 'day',
    'weekly': 'week',
    'monthly': 'month',
    'yearly': 'year',
  };
  final u = unit[frequency] ?? 'time';
  if (n == 1) {
    return switch (frequency) {
      'daily' => 'Every day',
      'weekly' => 'Every week',
      'monthly' => 'Every month',
      'yearly' => 'Every year',
      _ => 'Every $u',
    };
  }
  return 'Every $n ${u}s';
}

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(recurringListProvider);

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Recurring'),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(
                child: PillButton(
                  label: 'Retry',
                  expand: false,
                  onPressed: () => ref.invalidate(recurringListProvider),
                ),
              ),
              data: (rules) => RefreshIndicator(
                onRefresh: () => ref.refresh(recurringListProvider.future),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
                  children: [
                    if (rules.isEmpty)
                      const EmptyState(
                        icon: Icons.autorenew,
                        title: 'No recurring transactions',
                        message:
                            'Add a rule and Wealthify will create each entry on schedule.',
                      )
                    else
                      ...rules.map((rule) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _RecurringCard(rule: rule, money: money),
                          )),
                    const SizedBox(height: AppSpacing.lg),
                    PillButton(
                      label: 'Add recurring',
                      onPressed: () async {
                        await context.push(Routes.editRecurring);
                        ref.invalidate(recurringListProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringCard extends ConsumerWidget {
  const _RecurringCard({required this.rule, required this.money});

  final RecurringModel rule;
  final String Function(num?) money;

  Future<void> _toggleActive(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(recurringRepositoryProvider)
          .updateRecurring(rule.id, {'active': !rule.active});
      ref.invalidate(recurringListProvider);
    } catch (e) {
      if (context.mounted) showAppSnack(context, errorMessage(e), error: true);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Delete recurring',
            style: AppText.subtitle.copyWith(color: c.text)),
        content: Text(
          'Delete this recurring transaction? Future entries will no longer be created.',
          style: AppText.bodySm.copyWith(color: c.textSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppText.button.copyWith(color: c.textSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: AppText.button.copyWith(color: c.negative)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(recurringRepositoryProvider).deleteRecurring(rule.id);
      if (context.mounted) showAppSnack(context, 'Recurring deleted');
      ref.invalidate(recurringListProvider);
    } catch (e) {
      if (context.mounted) showAppSnack(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isIncome = rule.kind == 'income';
    final tagColor = isIncome ? c.accentDark : c.negative;

    return Opacity(
      opacity: rule.active ? 1 : 0.55,
      child: AppCard(
        onTap: () async {
          await context.push(Routes.editRecurring, extra: rule);
          ref.invalidate(recurringListProvider);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.autorenew, size: 18, color: c.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyMedium.copyWith(color: c.text)),
                      Text(frequencyLabel(rule.interval, rule.frequency),
                          style: AppText.caption.copyWith(color: c.textSubtle)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(money(rule.amount),
                    style: AppText.moneySm.copyWith(color: tagColor)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(isIncome ? 'Income' : 'Expense',
                      style: AppText.caption.copyWith(
                          color: tagColor, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    rule.nextRunDate.isNotEmpty
                        ? 'Next: ${rule.nextRunDate}'
                        : '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(color: c.textSubtle),
                  ),
                ),
                Switch(
                  value: rule.active,
                  activeThumbColor: c.primary,
                  onChanged: (_) => _toggleActive(context, ref),
                ),
                IconButton(
                  onPressed: () => _delete(context, ref),
                  icon: Icon(Icons.delete_outline, size: 20, color: c.negative),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
