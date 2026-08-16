import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/calorie_entry.dart';
import 'calorie_screen.dart';

String _errorMessage(Object e) => e.toString();

/// Healthify "Goals" tab: view and update the daily nutrition intake goal
/// (calories/protein/carbs/fat/sugar) and the weight goal, in one place —
/// separate from the day-to-day tracking on the Today/Statistics tabs.
class HealthGoalsScreen extends ConsumerStatefulWidget {
  const HealthGoalsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

class _HealthGoalsScreenState extends ConsumerState<HealthGoalsScreen> {
  bool _loading = false;
  DailyTotals? _dailyTotals;
  HealthProfile? _healthProfile;
  double? _targetWeightKg;
  double? _currentWeightKg;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final repo = ref.read(caloriesRepositoryProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      final results = await Future.wait([
        repo.getDailyCalories(date: dateStr),
        repo.getWeightHistory(),
      ]);
      if (!mounted) return;
      final caloriesRes = results[0];
      final weightRes = results[1];
      setState(() {
        final totals = Map<String, dynamic>.from(
          caloriesRes['dailyTotals'] as Map? ?? {},
        );
        final targets = caloriesRes['dailyTargets'] as Map?;
        if (targets != null) totals.addAll(Map<String, dynamic>.from(targets));
        _dailyTotals = DailyTotals.fromJson(totals);
        _healthProfile = HealthProfile.fromJson(
          caloriesRes['healthProfile'] as Map<String, dynamic>?,
        );
        _targetWeightKg = (weightRes['targetWeightKg'] as num?)?.toDouble();
        _currentWeightKg = (weightRes['currentWeightKg'] as num?)?.toDouble();
      });
    } catch (e) {
      if (mounted) showAppSnack(context, _errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editNutritionGoal() async {
    final totals = _dailyTotals;
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditGoalSheet(
        calorieTarget: totals?.calorieTarget ?? 2000,
        sugarTarget: totals?.sugarTarget ?? 50,
        fatTarget: totals?.fatTarget ?? 80,
        proteinTarget: totals?.proteinTarget ?? 100,
        healthProfile: _healthProfile,
      ),
    );
    if (result == null || !mounted) return;
    final repo = ref.read(caloriesRepositoryProvider);
    try {
      await repo.updateCalorieGoals(
        calorieTarget: result['calorieTarget'],
        sugarTarget: result['sugarTarget'],
        fatTarget: result['fatTarget'],
        proteinTarget: result['proteinTarget'],
      );
      await _fetch();
      if (mounted) showAppSnack(context, 'Nutrition goal updated');
    } catch (e) {
      if (mounted) showAppSnack(context, _errorMessage(e), error: true);
    }
  }

  Future<void> _editWeightGoal() async {
    final controller = TextEditingController(
      text: _targetWeightKg != null ? '${_targetWeightKg!.round()}' : '',
    );
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = context.colors;
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Container(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                bottom + AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set goal weight',
                      style: AppText.title.copyWith(color: c.text)),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    controller: controller,
                    label: 'Goal weight (kg)',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.flag_rounded,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PillButton(
                    label: 'Save goal',
                    gradientColors: [c.primaryDark, c.primaryDarker],
                    onPressed: () {
                      final v = double.tryParse(controller.text.trim());
                      Navigator.of(ctx).pop(v);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result == null || result <= 0 || !mounted) return;
    final repo = ref.read(caloriesRepositoryProvider);
    try {
      await repo.updateTargetWeight(result);
      await _fetch();
      if (mounted) showAppSnack(context, 'Weight goal updated');
    } catch (e) {
      if (mounted) showAppSnack(context, _errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Expanded(
      child: RefreshIndicator(
        onRefresh: _fetch,
        color: context.colors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.xl4,
          ),
          children: [
            const SectionHeader('Nutrition intake goal'),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const _GoalCardSkeleton()
            else
              _NutritionGoalCard(
                totals: _dailyTotals,
                onEdit: _editNutritionGoal,
              ),
            const SizedBox(height: AppSpacing.xl2),
            const SectionHeader('Weight goal'),
            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const _GoalCardSkeleton()
            else
              _WeightGoalCard(
                currentWeightKg: _currentWeightKg,
                targetWeightKg: _targetWeightKg,
                onEdit: _editWeightGoal,
              ),
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Column(children: [const SizedBox(height: AppSpacing.sm), content]);
    }

    return GradientScaffold(
      child: Column(
        children: [const ScreenHeader(title: 'Goals'), content],
      ),
    );
  }
}

class _NutritionGoalCard extends StatelessWidget {
  const _NutritionGoalCard({required this.totals, required this.onEdit});

  final DailyTotals? totals;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(icon: Icons.local_fire_department_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Daily targets',
                    style: AppText.bodyStrong.copyWith(color: c.text)),
              ),
              CircleIconButton(
                icon: Icons.edit_rounded,
                size: 32,
                iconSize: 15,
                background: c.primarySoft,
                color: c.primary,
                onTap: onEdit,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: c.divider),
          const SizedBox(height: AppSpacing.sm),
          _GoalRow(label: 'Calories', value: '${totals?.calorieTarget ?? '—'}', unit: 'kcal'),
          _GoalRow(label: 'Protein', value: '${totals?.proteinTarget ?? '—'}', unit: 'g'),
          _GoalRow(label: 'Carbs', value: '${totals?.carbTarget ?? '—'}', unit: 'g'),
          _GoalRow(label: 'Fat', value: '${totals?.fatTarget ?? '—'}', unit: 'g'),
          _GoalRow(label: 'Sugar', value: '${totals?.sugarTarget ?? '—'}', unit: 'g', isLast: true),
        ],
      ),
    );
  }
}

/// Small circular icon badge used at the head of the Nutrition/Weight cards.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
      child: Icon(icon, size: 16, color: c.primary),
    );
  }
}

/// Renders a numeric value with its unit de-emphasized, e.g. **2000** kcal —
/// keeps the number as the visual anchor and the unit as a quiet label.
class _StatValue extends StatelessWidget {
  const _StatValue({
    required this.value,
    required this.unit,
    this.valueStyle,
    this.unitStyle,
  });

  final String value;
  final String unit;
  final TextStyle? valueStyle;
  final TextStyle? unitStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: value,
            style: valueStyle ??
                AppText.bodyLarge.copyWith(color: c.text, fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: ' $unit',
            style: unitStyle ?? AppText.bodySm.copyWith(color: c.textSubtle),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.label,
    required this.value,
    required this.unit,
    this.isLast = false,
  });

  final String label;
  final String value;
  final String unit;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppText.body.copyWith(color: c.textSubtle)),
          ),
          _StatValue(value: value, unit: unit),
        ],
      ),
    );
  }
}

class _WeightGoalCard extends StatelessWidget {
  const _WeightGoalCard({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.onEdit,
  });

  final double? currentWeightKg;
  final double? targetWeightKg;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasBoth = currentWeightKg != null && targetWeightKg != null;
    final delta = hasBoth ? currentWeightKg! - targetWeightKg! : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _IconBadge(icon: Icons.monitor_weight_rounded),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text('Weight', style: AppText.bodyStrong.copyWith(color: c.text)),
              ),
              CircleIconButton(
                icon: Icons.edit_rounded,
                size: 32,
                iconSize: 15,
                background: c.primarySoft,
                color: c.primary,
                onTap: onEdit,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: c.divider),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current', style: AppText.label.copyWith(color: c.textSubtle)),
                    const SizedBox(height: 4),
                    currentWeightKg != null
                        ? _StatValue(
                            value: currentWeightKg!.toStringAsFixed(1), unit: 'kg')
                        : Text('Not logged',
                            style: AppText.body.copyWith(color: c.textSubtle)),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: c.divider),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Goal', style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: 4),
                      targetWeightKg != null
                          ? _StatValue(
                              value: targetWeightKg!.toStringAsFixed(1), unit: 'kg')
                          : Text('Not set',
                              style: AppText.body.copyWith(color: c.textSubtle)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (delta != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: (delta.abs() < 0.05 ? c.accentDark : c.warning).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                delta.abs() < 0.05
                    ? 'On target'
                    : '${delta > 0 ? '-' : '+'}${delta.abs().toStringAsFixed(1)} kg to go',
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(
                  color: delta.abs() < 0.05 ? c.accentDark : c.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalCardSkeleton extends StatelessWidget {
  const _GoalCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonCircle(size: 32),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(child: SkeletonLine(height: 14)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: context.colors.divider),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < 3; i++) ...[
            const SkeletonLine(height: 14),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
