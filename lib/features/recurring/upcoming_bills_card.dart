import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/misc.dart';
import '../../data/models/recurring_model.dart';
import '../../data/repositories/bills_repository.dart';
import '../auth/auth_screen.dart';
import '../preferences/preferences_controller.dart';

class UpcomingBillsCard extends ConsumerStatefulWidget {
  const UpcomingBillsCard({super.key});

  @override
  ConsumerState<UpcomingBillsCard> createState() => _UpcomingBillsCardState();
}

class _UpcomingBillsCardState extends ConsumerState<UpcomingBillsCard> {
  String? _busyId;

  Future<void> _mark(RecurringModel bill, String status) async {
    setState(() => _busyId = bill.id);
    try {
      await ref.read(billsRepositoryProvider).markBill(bill.id, status);
      if (!mounted) return;
      showAppSnack(context, status == 'paid' ? 'Bill marked paid' : 'Bill skipped');
      ref.invalidate(upcomingBillsProvider);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(upcomingBillsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (bills) {
        if (bills.isEmpty) return const SizedBox.shrink();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upcoming bills',
                  style: AppText.subtitle.copyWith(color: c.text)),
              const SizedBox(height: AppSpacing.sm),
              for (final b in bills.take(5)) ...[
                Row(
                  children: [
                    Icon(
                      b.overdue
                          ? Icons.error_outline
                          : Icons.receipt_long_outlined,
                      size: 18,
                      color: b.overdue ? c.negative : c.textSubtle,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.title?.isNotEmpty == true ? b.title! : b.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyMedium
                                  .copyWith(color: c.text)),
                          Text(
                            b.overdue
                                ? 'Overdue · ${b.nextRunDate}'
                                : 'Due ${b.nextRunDate}',
                            style: AppText.caption.copyWith(
                                color: b.overdue
                                    ? c.negative
                                    : c.textSubtle),
                          ),
                        ],
                      ),
                    ),
                    Text(money(b.amount),
                        style: AppText.bodyStrong.copyWith(
                            color:
                                b.overdue ? c.negative : c.text)),
                    const SizedBox(width: AppSpacing.xs),
                    if (_busyId == b.id)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      GestureDetector(
                        onTap: () => _mark(b, 'paid'),
                        child: Icon(Icons.check_circle_outline,
                            size: 22, color: c.accentDark),
                      ),
                  ],
                ),
                if (b != bills.take(5).last)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }
}
