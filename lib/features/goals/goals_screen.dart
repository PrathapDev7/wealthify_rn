import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goals_repository.dart';
import '../preferences/preferences_controller.dart';

final goalsProvider = FutureProvider.autoDispose<List<GoalModel>>(
  (ref) => ref.read(goalsRepositoryProvider).getGoals(),
);

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(goalsProvider);

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Savings goals'),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(
                child: PillButton(
                  label: 'Retry',
                  expand: false,
                  onPressed: () => ref.invalidate(goalsProvider),
                ),
              ),
              data: (goals) {
                final totalSaved =
                    goals.fold<num>(0, (sum, g) => sum + g.savedAmount);

                return RefreshIndicator(
                  onRefresh: () => ref.refresh(goalsProvider.future),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
                    children: [
                      if (goals.isEmpty)
                        EmptyState(
                          icon: Icons.flag_outlined,
                          title: 'No savings goals yet',
                          message:
                              'Set a target to save towards, then track every contribution here.',
                        )
                      else ...[
                        AppCard(
                          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total saved across goals',
                                  style: AppText.label
                                      .copyWith(color: c.textSubtle)),
                              const SizedBox(height: AppSpacing.xs),
                              Text(money(totalSaved),
                                  style:
                                      AppText.titleLg.copyWith(color: c.text)),
                            ],
                          ),
                        ),
                        ...goals.map((goal) {
                          final percent = (goal.progress * 100).round();
                          return AppCard(
                            margin:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            onTap: () => context.push(Routes.goalDetail,
                                extra: goal),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        goal.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppText.bodyMedium
                                            .copyWith(color: c.text),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    if (goal.completed)
                                      _CompletedBadge()
                                    else
                                      Text('$percent%',
                                          style: AppText.bodyMedium
                                              .copyWith(color: c.textSubtle)),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppProgressBar(value: goal.progress),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '${money(goal.savedAmount)} of ${money(goal.targetAmount)}',
                                  style: AppText.caption
                                      .copyWith(color: c.textSubtle),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      PillButton(
                        label: 'New goal',
                        onPressed: () async {
                          await context.push(Routes.goalDetail);
                          ref.invalidate(goalsProvider);
                        },
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

class _CompletedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: c.accentDark,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: c.textInverse),
          const SizedBox(width: 3),
          Text('Completed',
              style: AppText.caption.copyWith(
                  color: c.textInverse, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
