import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/misc.dart';
import '../../data/repositories/bills_repository.dart';
import '../preferences/preferences_controller.dart';

class DebtsCard extends ConsumerWidget {
  const DebtsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(debtsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (result) {
        if (result.debts.isEmpty) return const SizedBox.shrink();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('What you owe',
                        style:
                            AppText.subtitle.copyWith(color: c.text)),
                  ),
                  Text(money(result.totalOwed),
                      style: AppText.bodyStrong.copyWith(
                          color: result.totalOwed > 0
                              ? c.negative
                              : c.text)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final w in result.debts.take(5)) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.bodyMedium
                                  .copyWith(color: c.text)),
                          Text(
                            [
                              if (w.dueDay != null)
                                'Due day ${w.dueDay}',
                              if (w.minPayment != null)
                                'Min ${money(w.minPayment)}',
                              if (w.apr != null) '${w.apr}% APR',
                            ].join(' · '),
                            style: AppText.caption
                                .copyWith(color: c.textSubtle),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(money(w.owedBalance),
                        style: AppText.bodyStrong
                            .copyWith(color: c.negative)),
                  ],
                ),
                if (w.payoffProgress != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppProgressBar(value: w.payoffProgress!.clamp(0.0, 1.0)),
                ],
                if (w != result.debts.take(5).last)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        );
      },
    );
  }
}
