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
      'weekly' => 'Weekly',
      'monthly' => 'Monthly',
      'yearly' => 'Yearly',
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

class _RecurringCard extends ConsumerStatefulWidget {
  const _RecurringCard({required this.rule, required this.money});

  final RecurringModel rule;
  final String Function(num?) money;

  @override
  ConsumerState<_RecurringCard> createState() => _RecurringCardState();
}

class _RecurringCardState extends ConsumerState<_RecurringCard> {
  bool _busy = false;

  RecurringModel get rule => widget.rule;

  Future<void> _toggleActive() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(recurringRepositoryProvider)
          .updateRecurring(rule.id, {'active': !rule.active});
      if (!mounted) return;
      showAppSnack(
          context, rule.active ? 'Recurring paused' : 'Recurring resumed');
      ref.invalidate(recurringListProvider);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
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
      if (mounted) showAppSnack(context, 'Recurring deleted');
      ref.invalidate(recurringListProvider);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isExpense = rule.kind == 'expense';
    final kindColor = isExpense ? c.negative : c.accentDark;
    final hasDescription =
        rule.description != null && rule.description!.isNotEmpty;
    final subtitle = frequencyLabel(rule.interval, rule.frequency) +
        (rule.nextRunDate.isNotEmpty ? ' · next ${rule.nextRunDate}' : '');

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
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kindColor.withValues(alpha: 0.13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isExpense ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 16,
                    color: kindColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rule.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodyMedium.copyWith(color: c.text)),
                      if (hasDescription)
                        Text(rule.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                AppText.bodySm.copyWith(color: c.textSubtle)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(widget.money(rule.amount),
                    style: AppText.bodyStrong.copyWith(color: kindColor)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle,
                style: AppText.caption.copyWith(color: c.textSubtle)),
            const SizedBox(height: AppSpacing.xs),
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      busy: _busy,
                      icon: rule.active
                          ? Icons.pause
                          : Icons.play_arrow,
                      label: rule.active ? 'Pause' : 'Resume',
                      color: c.primary,
                      onTap: _busy ? null : _toggleActive,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: c.negative,
                      onTap: _delete,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Labeled row action (Pause/Resume, Delete) mirroring the RN `actionBtn`.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: busy
            ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: c.primary),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 5),
                  Text(label,
                      style: AppText.bodySm
                          .copyWith(color: color, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
