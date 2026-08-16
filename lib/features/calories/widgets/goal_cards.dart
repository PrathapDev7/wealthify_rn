import 'package:flutter/material.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/calorie_entry.dart';

/// Goals-screen calorie target card. Deliberately not [CalorieHeroCard]:
/// same subject (daily calorie target) but a distinct, editorial treatment —
/// solid gradient fill and a big standalone number instead of the Today
/// tracker's bordered card + progress ring, so the Goals tab reads as its
/// own "set the target" surface rather than a live tracker.
class NutritionGoalCard extends StatelessWidget {
  final DailyTotals totals;
  final VoidCallback onEditGoal;

  const NutritionGoalCard({
    super.key,
    required this.totals,
    required this.onEditGoal,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = totals.calorieTarget;
    final hasTarget = target != null && target > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.primaryGradientStart, c.primaryGradientEnd],
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.primaryGlow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 15,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Daily calorie target',
                      style: AppText.bodySm.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: hasTarget ? '$target' : '—',
                        style: AppText.titleLg.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: ' kcal',
                        style: AppText.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEditGoal,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_rounded, size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Edit',
                    style: AppText.bodySm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Goals-screen macro targets. Deliberately not [MacroMiniCard]/its 2×2
/// grid: a single stacked list of rows (icon, label, target grams, thin
/// underline bar) inside one [AppCard], so it reads as a settings-style
/// list of targets rather than the Today tracker's grid of live stat cards.
class MacroGoalList extends StatelessWidget {
  const MacroGoalList({super.key, required this.totals});

  final DailyTotals totals;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rows = [
      (
        Icons.fitness_center_rounded,
        'Protein',
        totals.proteinTarget,
        c.accentDark,
      ),
      (Icons.grain_rounded, 'Carbs', totals.carbTarget, c.info),
      (Icons.opacity_rounded, 'Fats', totals.fatTarget, c.warning),
      (Icons.icecream_rounded, 'Sugar', totals.sugarTarget, c.pink),
    ];

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: AppSpacing.lg, color: c.divider),
            _MacroGoalRow(
              icon: rows[i].$1,
              label: rows[i].$2,
              target: rows[i].$3,
              color: rows[i].$4,
            ),
          ],
        ],
      ),
    );
  }
}

class _MacroGoalRow extends StatelessWidget {
  const _MacroGoalRow({
    required this.icon,
    required this.label,
    required this.target,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int? target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppText.bodyMedium.copyWith(
                color: c.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            '${target ?? 0}g',
            style: AppText.bodyMedium.copyWith(
              color: c.textSubtle,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for [NutritionGoalCard].
class NutritionGoalCardSkeleton extends StatelessWidget {
  const NutritionGoalCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonLine(width: 140, height: 12),
          SizedBox(height: AppSpacing.sm),
          SkeletonLine(width: 120, height: 26),
        ],
      ),
    );
  }
}

/// Placeholder for [MacroGoalList].
class MacroGoalListSkeleton extends StatelessWidget {
  const MacroGoalListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) Divider(height: AppSpacing.lg, color: c.divider),
            Row(
              children: [
                const SkeletonCircle(size: 30),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(child: SkeletonLine(height: 12)),
                const SizedBox(width: AppSpacing.sm),
                const SkeletonLine(width: 30, height: 12),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
