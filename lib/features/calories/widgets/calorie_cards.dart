import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/calorie_entry.dart';

/// Calorie ring + Consumed/Goal hero card. Shared between the Today tracker
/// and the Goals screen so calorie progress renders identically on both.
class CalorieHeroCard extends StatelessWidget {
  final DailyTotals totals;
  final VoidCallback onEditGoal;

  const CalorieHeroCard({super.key, required this.totals, required this.onEditGoal});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = totals.calorieTarget;
    final hasTarget = target != null && target > 0;
    final left = totals.caloriesLeft;
    final over = hasTarget && left < 0;
    final accent = over ? c.negative : c.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: CalorieHeroContent(totals: totals, onEditGoal: onEditGoal),
    );
  }
}

/// Inner content of [CalorieHeroCard] — the donut chart + Consumed/Goal
/// stats row. Exported so the Healthify dashboard hero can embed it in a
/// combined card alongside the date picker.
class CalorieHeroContent extends StatelessWidget {
  final DailyTotals totals;
  final VoidCallback onEditGoal;

  const CalorieHeroContent({super.key, required this.totals, required this.onEditGoal});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = totals.calorieTarget;
    final hasTarget = target != null && target > 0;
    final pct = hasTarget
        ? (totals.calories / target * 100).clamp(0.0, 100.0)
        : 100.0;
    final left = totals.caloriesLeft;
    final over = hasTarget && left < 0;
    final accent = over ? c.negative : c.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                duration: const Duration(milliseconds: 400),
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 0,
                  centerSpaceRadius: 24,
                  centerSpaceColor: Colors.transparent,
                  sections: [
                    PieChartSectionData(
                      value: pct,
                      color: accent,
                      radius: 8,
                      showTitle: false,
                    ),
                    PieChartSectionData(
                      value: 100 - pct,
                      color: accent.withValues(alpha: 0.15),
                      radius: 8,
                      showTitle: false,
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedCount(
                    value: left.abs(),
                    style: AppText.bodyLarge.copyWith(
                      color: c.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    over ? 'over' : 'left',
                    style: AppText.caption.copyWith(color: c.textSubtle),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 16,
                    color: accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Daily Calories',
                    style: AppText.bodyMedium.copyWith(color: c.text),
                  ),
                  const Spacer(),
                  if (hasTarget)
                    Text(
                      '${pct.round()}%',
                      style: AppText.caption.copyWith(color: c.textSubtle),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _heroStat(c, 'Consumed', '${totals.calories}'),
                  ),
                  Container(width: 1, height: 26, color: c.divider),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _heroStat(
                            c,
                            'Goal',
                            hasTarget ? '$target' : '—',
                          ),
                        ),
                        GestureDetector(
                          onTap: onEditGoal,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: c.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit_rounded,
                              size: 12,
                              color: c.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _heroStat(AppColors c, String label, String value) => Padding(
    padding: const EdgeInsets.only(left: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppText.bodyMedium.copyWith(
            color: c.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: AppText.caption.copyWith(color: c.textSubtle)),
      ],
    ),
  );
}

/// Counts a value up from 0 on mount/update, mirroring the dashboard's
/// animated money counter.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.value, required this.style});

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (_, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// Compact icon + label + "value/target" + progress bar card for a single
/// macro (sugar, fat, protein, carbs, ...). Shared between the Today
/// tracker's 3-across row and the Goals screen's macro grid.
class MacroMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int? target;
  final double progress; // 0..100
  final Color color;

  const MacroMiniCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.target,
    required this.progress,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: AppText.bodySm.copyWith(
                    color: c.text,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value/${target ?? 0}g',
            style: AppText.caption.copyWith(color: c.textSubtle),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppProgressBar(value: progress / 100, color: color, height: 4),
        ],
      ),
    );
  }
}

/// Placeholder for [CalorieHeroCard] (ring + two stat lines).
class CalorieHeroSkeleton extends StatelessWidget {
  const CalorieHeroSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SkeletonCircle(size: 68),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                SkeletonLine(width: 110, height: 14),
                SizedBox(height: AppSpacing.sm),
                SkeletonLine(width: 160, height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder for [MacroMiniCard].
class MacroMiniCardSkeleton extends StatelessWidget {
  const MacroMiniCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              SkeletonCircle(size: 24),
              SizedBox(width: AppSpacing.xs),
              Expanded(child: SkeletonLine(height: 12)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const SkeletonLine(width: 50, height: 10),
          const SizedBox(height: AppSpacing.xs),
          const SkeletonBox(height: 4, width: double.infinity),
        ],
      ),
    );
  }
}
