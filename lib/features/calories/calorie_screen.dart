import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/calorie_entry.dart';

String errorMessage(Object e) {
  if (e is Exception) return e.toString();
  return 'Something went wrong';
}

class CalorieScreen extends ConsumerStatefulWidget {
  const CalorieScreen({super.key});
  @override
  ConsumerState<CalorieScreen> createState() => _CalorieScreenState();
}

class _CalorieScreenState extends ConsumerState<CalorieScreen> {
  final TextEditingController _textController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  String? _entryId;
  List<MealItem> _mealItems = [];
  DailyTotals? _dailyTotals;
  HealthProfile? _healthProfile;
  String _loadingMessage = '';
  Timer? _loadingTimer;
  int _loadingStep = 0;

  final List<String> _loadingMessages = [
    'Analyzing your food entry...',
    'Identifying ingredients...',
    'Calculating nutrition values...',
    'Almost done...',
  ];

  @override
  void dispose() {
    _textController.dispose();
    _loadingTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCalories() async {
    final repo = ref.read(caloriesRepositoryProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    try {
      final res = await repo.getDailyCalories(date: dateStr);
      if (mounted) {
        setState(() {
          _mealItems = (res['mealItems'] as List?)
                  ?.map((m) => MealItem.fromJson(m as Map<String, dynamic>))
                  .toList() ??
              [];
          final totals =
              Map<String, dynamic>.from(res['dailyTotals'] as Map? ?? {});
          final targets = res['dailyTargets'] as Map?;
          if (targets != null) totals.addAll(Map<String, dynamic>.from(targets));
          _dailyTotals = DailyTotals.fromJson(totals);
          _healthProfile = HealthProfile.fromJson(res['healthProfile'] as Map<String, dynamic>?);
        });
      }
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCalories();
  }

  Future<void> _analyzeFood() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      showAppSnack(context, 'Please enter what you ate', error: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(caloriesRepositoryProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final addRes = await repo.addCaloriesEntry(date: dateStr);
      _entryId = addRes['entryId'];
      _startLoadingMessages();
      final result = await repo.processFoodText(_entryId!, text);
      _stopLoadingMessages();
      final added = (result['addedItems'] as List?)
              ?.map((m) => MealItem.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [];
      await _fetchCalories();
      _textController.clear();
      if (mounted && added.isNotEmpty) _showMealAddedModal(added);
    } catch (e) {
      _stopLoadingMessages();
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startLoadingMessages() {
    _loadingStep = 0;
    _loadingMessage = _loadingMessages[0];
    _loadingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      _loadingStep = (_loadingStep + 1) % _loadingMessages.length;
      setState(() => _loadingMessage = _loadingMessages[_loadingStep]);
    });
  }

  void _stopLoadingMessages() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  Future<void> _deleteItem(String itemId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete meal item?'),
        content: const Text('This item will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: TextStyle(color: context.colors.negative)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final repo = ref.read(caloriesRepositoryProvider);
    try {
      await repo.deleteMealItem(itemId);
      await _fetchCalories();
      if (mounted) showAppSnack(context, 'Item removed');
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    }
  }

  void _moveDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _fetchCalories();
  }

  void _goToToday() {
    setState(() {
      _selectedDate = DateTime.now();
    });
    _fetchCalories();
  }

  Map<MealType, List<MealItem>> get _mealsByType {
    final grouped = <MealType, List<MealItem>>{};
    for (final item in _mealItems) {
      grouped.putIfAbsent(item.mealType, () => []).add(item);
    }
    return grouped;
  }

  void _showMealAddedModal(List<MealItem> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MealAddedSheet(items: items),
    );
  }

  Future<void> _editGoals() async {
    final totals = _dailyTotals;
    final result = await showModalBottomSheet<Map<String, int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditGoalSheet(
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
        date: DateFormat('yyyy-MM-dd').format(_selectedDate),
      );
      await _fetchCalories();
      if (mounted) showAppSnack(context, 'Goal updated');
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final groups = _mealsByType;
    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Calorie Tracker'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchCalories,
              color: c.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl4),
                children: [
                  _HorizontalDatePicker(
                    selectedDate: _selectedDate,
                    onDateSelected: (date) {
                      setState(() => _selectedDate = date);
                      _fetchCalories();
                    },
                    onTodayTap: _goToToday,
                    onPrevTap: () => _moveDate(-1),
                    onNextTap: () => _moveDate(1),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Compact hero + macro summary
                  if (_dailyTotals != null) ...[
                    _CalorieHeroCard(
                        totals: _dailyTotals!, onEditGoal: _editGoals),
                    const SizedBox(height: AppSpacing.md),
                    _MacroStatsRow(totals: _dailyTotals!),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Input area
                  _FoodInputCard(
                    controller: _textController,
                    loading: _isLoading,
                    loadingMessage: _loadingMessage,
                    onSubmit: _isLoading ? null : _analyzeFood,
                  ),

                  const SizedBox(height: AppSpacing.xl2),
                  const SectionHeader("Today's Meals"),
                  const SizedBox(height: AppSpacing.md),
                  if (_mealItems.isEmpty && !_isLoading)
                    const EmptyState(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'No meals logged yet',
                      message: 'Log what you ate above to start tracking today.',
                    )
                  else
                    ...MealType.values
                        .where((t) => groups[t]?.isNotEmpty ?? false)
                        .map((type) => _MealGroupCard(
                              mealType: type,
                              items: groups[type]!,
                              onDeleteItem: _deleteItem,
                            )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Food Input Card ─────────────────────────────────────────────
class _FoodInputCard extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final String loadingMessage;
  final VoidCallback? onSubmit;

  const _FoodInputCard({
    required this.controller,
    required this.loading,
    required this.loadingMessage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.primary.withValues(alpha: 0.22)),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, size: 18, color: c.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('What did you eat?',
                  style: AppText.label.copyWith(color: c.textSubtle)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: controller,
            hint: 'e.g. 100g peanuts, 2 eggs, 200g rice',
            maxLines: 2,
            fillColor: c.surfaceMuted,
            borderColor: c.primary.withValues(alpha: 0.28),
          ),
          const SizedBox(height: AppSpacing.md),
          PillButton(
            label: 'Add Meal',
            loading: loading,
            loadingLabel: loading ? loadingMessage : null,
            onPressed: onSubmit,
            leading: Icon(Icons.add_circle_outline,
                size: 18, color: c.textOnPrimary),
          ),
        ],
      ),
    );
  }
}

// ─── Horizontal Date Picker ──────────────────────────────────────
class _HorizontalDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onTodayTap;
  final VoidCallback onPrevTap;
  final VoidCallback onNextTap;

  const _HorizontalDatePicker({
    required this.selectedDate,
    required this.onDateSelected,
    required this.onTodayTap,
    required this.onPrevTap,
    required this.onNextTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final monthYear = DateFormat('MMMM yyyy').format(selectedDate);
    final days = _getWeekDays(selectedDate);
    final selectedKey = DateFormat('yyyy-MM-dd').format(selectedDate);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(monthYear, style: AppText.bodyLarge.copyWith(color: c.text)),
            const Spacer(),
            GestureDetector(
              onTap: onTodayTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: c.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text('Today',
                    style: AppText.bodySm
                        .copyWith(color: c.primary, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            CircleIconButton(
                icon: Icons.chevron_left,
                size: 32,
                iconSize: 18,
                onTap: onPrevTap),
            const SizedBox(width: AppSpacing.xs),
            CircleIconButton(
                icon: Icons.chevron_right,
                size: 32,
                iconSize: 18,
                onTap: onNextTap),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Weekday initials
        Row(
          children: days
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        (day['abbrev'] as String).substring(0, 1),
                        style: AppText.caption.copyWith(color: c.textSubtle),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Date circles
        Row(
          children: days
              .map((day) => Expanded(
                    child: Center(
                      child: _DateBadge(
                        day: day['day'] as int,
                        isSelected: (day['key'] as String) == selectedKey,
                        isToday: (day['key'] as String) == todayKey,
                        onTap: () => onDateSelected(day['date'] as DateTime),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getWeekDays(DateTime date) {
    final days = <Map<String, dynamic>>[];
    // Start from the Monday of the current week
    final startOfWeek = DateTime(date.year, date.month, date.day - date.weekday + 1);
    for (int i = 0; i < 7; i++) {
      final dayDate = startOfWeek.add(Duration(days: i));
      days.add({
        'abbrev': DateFormat('EEE').format(dayDate),
        'date': dayDate,
        'day': dayDate.day,
        'key': DateFormat('yyyy-MM-dd').format(dayDate),
      });
    }
    return days;
  }
}

/// Fixed-size circular date badge — a single centered number, so it can
/// never look vertically off-center regardless of the column width.
class _DateBadge extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DateBadge({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              isSelected ? LinearGradient(colors: [c.primaryDark, c.primaryDarker]) : null,
          color: isSelected
              ? null
              : (isToday ? c.primarySoft : Colors.transparent),
          border: !isSelected && isToday
              ? Border.all(color: c.primary, width: 1.2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: c.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6))
                ]
              : null,
        ),
        child: Text(
          '$day',
          style: AppText.bodyMedium.copyWith(
            color: isSelected
                ? Colors.white
                : (isToday ? c.primary : c.text),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─── Calorie Hero Card (compact) ─────────────────────────────────
class _CalorieHeroCard extends StatelessWidget {
  final DailyTotals totals;
  final VoidCallback onEditGoal;

  const _CalorieHeroCard({required this.totals, required this.onEditGoal});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final target = totals.calorieTarget;
    final hasTarget = target != null && target > 0;
    final pct = hasTarget ? (totals.calories / target * 100).clamp(0.0, 100.0) : 100.0;
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
      child: Row(
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
                          value: pct, color: accent, radius: 8, showTitle: false),
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
                    _AnimatedCount(
                      value: left.abs(),
                      style: AppText.bodyLarge.copyWith(color: c.text, fontWeight: FontWeight.w800),
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
                    Icon(Icons.local_fire_department_rounded, size: 16, color: accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Daily Calories',
                        style: AppText.bodyMedium.copyWith(color: c.text)),
                    const Spacer(),
                    if (hasTarget)
                      Text('${pct.round()}%',
                          style: AppText.caption.copyWith(color: c.textSubtle)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _heroStat(c, 'Consumed', '${totals.calories}')),
                    Container(width: 1, height: 26, color: c.divider),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                              child: _heroStat(
                                  c, 'Goal', hasTarget ? '$target' : '—')),
                          GestureDetector(
                            onTap: onEditGoal,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: c.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.edit_rounded,
                                  size: 12, color: c.primary),
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
      ),
    );
  }

  Widget _heroStat(AppColors c, String label, String value) => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: AppText.bodyMedium.copyWith(color: c.text, fontWeight: FontWeight.w700)),
            Text(label, style: AppText.caption.copyWith(color: c.textSubtle)),
          ],
        ),
      );
}

/// Counts a value up from 0 on mount/update, mirroring the dashboard's
/// animated money counter.
class _AnimatedCount extends StatelessWidget {
  const _AnimatedCount({required this.value, required this.style});

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

// ─── Macro Stats — 3 compact side-by-side cards ──────────────────
class _MacroStatsRow extends StatelessWidget {
  final DailyTotals totals;

  const _MacroStatsRow({required this.totals});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: _MacroMiniCard(
            icon: Icons.icecream_rounded,
            label: 'Sugar',
            value: totals.sugar.round(),
            target: totals.sugarTarget,
            progress: totals.sugarProgress,
            color: c.pink,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MacroMiniCard(
            icon: Icons.opacity_rounded,
            label: 'Fats',
            value: totals.fat.round(),
            target: totals.fatTarget,
            progress: totals.fatProgress,
            color: c.warning,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _MacroMiniCard(
            icon: Icons.fitness_center_rounded,
            label: 'Protein',
            value: totals.protein.round(),
            target: totals.proteinTarget,
            progress: totals.proteinProgress,
            color: c.accentDark,
          ),
        ),
      ],
    );
  }
}

class _MacroMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final int? target;
  final double progress; // 0..100
  final Color color;

  const _MacroMiniCard({
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
                decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(icon, size: 13, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(label,
                    style: AppText.bodySm.copyWith(color: c.text, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('$value/${target ?? 0}g', style: AppText.caption.copyWith(color: c.textSubtle)),
          const SizedBox(height: AppSpacing.xs),
          AppProgressBar(value: progress / 100, color: color, height: 4),
        ],
      ),
    );
  }
}

// ─── Meal Group Card (itemized) ───────────────────────────────────
class _MealGroupCard extends StatelessWidget {
  final MealType mealType;
  final List<MealItem> items;
  final ValueChanged<String> onDeleteItem;

  const _MealGroupCard({
    required this.mealType,
    required this.items,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = switch (mealType) {
      MealType.breakfast => c.warning,
      MealType.lunch => c.blue,
      MealType.dinner => c.pink,
    };
    final target = mealType.targetCalories;
    final totalCalories = items.fold<int>(0, (sum, m) => sum + m.calories);
    final progress = target == 0 ? 0.0 : (totalCalories / target).clamp(0.0, 1.0);
    final status = items.any((m) => m.mealStatus == MealStatus.inProgress)
        ? MealStatus.inProgress
        : items.every((m) => m.mealStatus == MealStatus.completed)
            ? MealStatus.completed
            : MealStatus.pending;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                child: Center(child: Text(mealType.emoji, style: const TextStyle(fontSize: 18))),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mealType.label,
                        style: AppText.bodyMedium.copyWith(color: c.text, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('$totalCalories / $target kcal', style: AppText.bodySm.copyWith(color: c.textSubtle)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  status.label,
                  style: AppText.caption.copyWith(color: status.color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppProgressBar(value: progress, color: color, height: 5),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: AppSpacing.lg, color: c.divider),
            _MealItemRow(item: items[i], onDelete: () => onDeleteItem(items[i].id)),
          ],
        ],
      ),
    );
  }
}

class _MealItemRow extends StatelessWidget {
  final MealItem item;
  final VoidCallback onDelete;

  const _MealItemRow({required this.item, required this.onDelete});

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ItemNutritionSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: () => _showDetail(context),
      onLongPress: onDelete,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.foodName,
                    style: AppText.bodySm.copyWith(color: c.text, fontWeight: FontWeight.w600)),
                if (item.portion != null && item.portion!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(item.portion!, style: AppText.caption.copyWith(color: c.textSubtle)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('${item.calories} kcal',
              style: AppText.bodySm.copyWith(color: c.warning, fontWeight: FontWeight.w600)),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.drag_indicator_rounded, size: 14, color: c.textPlaceholder),
        ],
      ),
    );
  }
}

// ─── Item Nutrition — details modal ───────────────────────────────
class _ItemNutritionSheet extends StatelessWidget {
  final MealItem item;

  const _ItemNutritionSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, bottom + AppSpacing.xl),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                  child: Icon(Icons.restaurant_rounded, color: c.primary, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text('Nutrition details', style: AppText.title.copyWith(color: c.text)),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => context.pop(),
                  icon: Icon(Icons.close, color: c.textSubtle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            NutrientDetailCard(item: item),
            const SizedBox(height: AppSpacing.xl),
            PillButton(label: 'Done', onPressed: () => context.pop()),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Goal Modal ───────────────────────────────────────────────
class _EditGoalSheet extends ConsumerStatefulWidget {
  final int calorieTarget;
  final int sugarTarget;
  final int fatTarget;
  final int proteinTarget;
  final HealthProfile? healthProfile;

  const _EditGoalSheet({
    required this.calorieTarget,
    required this.sugarTarget,
    required this.fatTarget,
    required this.proteinTarget,
    this.healthProfile,
  });

  @override
  ConsumerState<_EditGoalSheet> createState() => _EditGoalSheetState();
}

class _EditGoalSheetState extends ConsumerState<_EditGoalSheet> {
  late final TextEditingController _calorie;
  late final TextEditingController _sugar;
  late final TextEditingController _fat;
  late final TextEditingController _protein;
  bool _calculated = false;

  @override
  void initState() {
    super.initState();
    _calorie = TextEditingController(text: '${widget.calorieTarget}');
    _sugar = TextEditingController(text: '${widget.sugarTarget}');
    _fat = TextEditingController(text: '${widget.fatTarget}');
    _protein = TextEditingController(text: '${widget.proteinTarget}');
  }

  @override
  void dispose() {
    _calorie.dispose();
    _sugar.dispose();
    _fat.dispose();
    _protein.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop({
      'calorieTarget': int.tryParse(_calorie.text) ?? widget.calorieTarget,
      'sugarTarget': int.tryParse(_sugar.text) ?? widget.sugarTarget,
      'fatTarget': int.tryParse(_fat.text) ?? widget.fatTarget,
      'proteinTarget': int.tryParse(_protein.text) ?? widget.proteinTarget,
    });
  }

  Future<void> _openAutoCalculate() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HealthProfileSheet(initial: widget.healthProfile),
    );
    if (result == null || !mounted) return;
    final goals = Map<String, dynamic>.from(result['calorieGoals'] as Map);
    setState(() {
      _calorie.text = '${goals['calorieTarget']}';
      _sugar.text = '${goals['sugarTarget']}';
      _fat.text = '${goals['fatTarget']}';
      _protein.text = '${goals['proteinTarget']}';
      _calculated = true;
    });
    if (mounted) showAppSnack(context, 'Goals calculated — review and save below');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, bottom + AppSpacing.xl),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Edit daily goal', style: AppText.title.copyWith(color: c.text)),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: c.textSubtle),
                ),
              ],
            ),
            if (!_calculated) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
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
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Calculate for me',
                              style: AppText.bodyMedium
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          Text('Based on your age, height, weight & activity',
                              style: AppText.caption
                                  .copyWith(color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GestureDetector(
                      onTap: _openAutoCalculate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text('Calculate',
                            style: AppText.bodySm
                                .copyWith(color: c.primaryDarker, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: Divider(color: c.divider)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text('or enter manually',
                        style: AppText.caption.copyWith(color: c.textSubtle)),
                  ),
                  Expanded(child: Divider(color: c.divider)),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _calorie,
              label: 'Calories (kcal)',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.local_fire_department_rounded,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _sugar,
                    label: 'Sugar (g)',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _fat,
                    label: 'Fat (g)',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _protein,
              label: 'Protein (g)',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.xl),
            PillButton(label: 'Save goal', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

// ─── Auto-calculate — health profile modal ─────────────────────────
class _HealthProfileSheet extends ConsumerStatefulWidget {
  final HealthProfile? initial;

  const _HealthProfileSheet({this.initial});

  @override
  ConsumerState<_HealthProfileSheet> createState() => _HealthProfileSheetState();
}

class _HealthProfileSheetState extends ConsumerState<_HealthProfileSheet> {
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  String? _gender;
  late String _activityLevel;
  late String _goal;
  bool _loading = false;
  int _step = 0;

  static const _steps = ['gender', 'age', 'height', 'weight', 'activity', 'goal'];

  static const _genders = [
    ('male', 'Male', Icons.male_rounded),
    ('female', 'Female', Icons.female_rounded),
    ('other', 'Other', Icons.transgender_rounded),
  ];
  static const _activityLevels = [
    ('sedentary', 'Sedentary', 'Little to no exercise', Icons.weekend_rounded),
    ('light', 'Light', '1-3 days/week', Icons.directions_walk_rounded),
    ('moderate', 'Moderate', '3-5 days/week', Icons.directions_run_rounded),
    ('active', 'Active', '6-7 days/week', Icons.fitness_center_rounded),
    ('very_active', 'Very active', 'Athlete / physical job', Icons.whatshot_rounded),
  ];
  static const _goals = [
    ('lose', 'Lose weight', 'Trim down at a steady pace', Icons.trending_down_rounded),
    ('maintain', 'Maintain', 'Stay around your current weight', Icons.balance_rounded),
    ('gain', 'Gain weight', 'Build up gradually', Icons.trending_up_rounded),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _age = TextEditingController(text: p?.age != null ? '${p!.age}' : '');
    _height = TextEditingController(text: p?.heightCm != null ? '${p!.heightCm!.round()}' : '');
    _weight = TextEditingController(text: p?.weightKg != null ? '${p!.weightKg!.round()}' : '');
    _gender = p?.gender;
    _activityLevel = p?.activityLevel ?? 'moderate';
    _goal = p?.goal ?? 'maintain';
  }

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  bool get _stepValid => switch (_steps[_step]) {
        'gender' => _gender != null,
        'age' => (int.tryParse(_age.text) ?? 0) > 0 && (int.tryParse(_age.text) ?? 0) <= 120,
        'height' => (double.tryParse(_height.text) ?? 0) > 0,
        'weight' => (double.tryParse(_weight.text) ?? 0) > 0,
        _ => true,
      };

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step -= 1);
    }
  }

  void _next() {
    if (!_stepValid) return;
    if (_step == _steps.length - 1) {
      _submit();
    } else {
      setState(() => _step += 1);
    }
  }

  Future<void> _submit() async {
    final age = int.tryParse(_age.text);
    final height = double.tryParse(_height.text);
    final weight = double.tryParse(_weight.text);
    if (_gender == null || age == null || height == null || weight == null) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(caloriesRepositoryProvider);
      final res = await repo.calculateCalorieGoals(
        age: age,
        gender: _gender!,
        heightCm: height,
        weightKg: weight,
        activityLevel: _activityLevel,
        goal: _goal,
      );
      if (mounted) {
        Navigator.of(context).pop({
          'calorieGoals': Map<String, dynamic>.from(res['calorieGoals'] as Map),
          'healthProfile': res['healthProfile'],
        });
      }
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isLast = _step == _steps.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, bottom + AppSpacing.xl),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleIconButton(
                icon: _step == 0 ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded,
                iconSize: _step == 0 ? 20 : 16,
                size: 36,
                onTap: _back,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Row(
                  children: [
                    for (var i = 0; i < _steps.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _step ? c.primary : c.surfaceMuted,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
                    .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(_step),
              child: _buildStep(c),
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          PillButton(
            label: isLast ? 'Calculate my goals' : 'Continue',
            loading: _loading,
            loadingLabel: _loading ? 'Calculating...' : null,
            onPressed: _loading || !_stepValid ? null : _next,
            leading: Icon(isLast ? Icons.auto_awesome_rounded : Icons.arrow_forward_rounded,
                size: 18, color: c.textOnPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(AppColors c) {
    return switch (_steps[_step]) {
      'gender' => _QuestionStep(
          icon: Icons.person_rounded,
          title: "What's your gender?",
          subtitle: 'This helps us tailor your calorie needs',
          child: Column(
            children: _genders
                .map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _OptionCard(
                        icon: g.$3,
                        label: g.$2,
                        selected: _gender == g.$1,
                        onTap: () => setState(() => _gender = g.$1),
                      ),
                    ))
                .toList(),
          ),
        ),
      'age' => _QuestionStep(
          icon: Icons.cake_rounded,
          title: 'How old are you?',
          subtitle: 'Age affects your metabolic rate',
          child: _NumberField(
              controller: _age, suffix: 'years', onChanged: (_) => setState(() {})),
        ),
      'height' => _QuestionStep(
          icon: Icons.height_rounded,
          title: "What's your height?",
          subtitle: 'In centimeters',
          child: _NumberField(
              controller: _height, suffix: 'cm', onChanged: (_) => setState(() {})),
        ),
      'weight' => _QuestionStep(
          icon: Icons.monitor_weight_rounded,
          title: "What's your weight?",
          subtitle: 'In kilograms',
          child: _NumberField(
              controller: _weight, suffix: 'kg', onChanged: (_) => setState(() {})),
        ),
      'activity' => _QuestionStep(
          icon: Icons.directions_run_rounded,
          title: 'How active are you?',
          subtitle: 'Your typical week, on average',
          child: Column(
            children: _activityLevels
                .map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _OptionCard(
                        icon: a.$4,
                        label: a.$2,
                        description: a.$3,
                        selected: _activityLevel == a.$1,
                        onTap: () => setState(() => _activityLevel = a.$1),
                      ),
                    ))
                .toList(),
          ),
        ),
      _ => _QuestionStep(
          icon: Icons.flag_rounded,
          title: "What's your goal?",
          subtitle: 'We will shape your targets around this',
          child: Column(
            children: _goals
                .map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _OptionCard(
                        icon: g.$4,
                        label: g.$2,
                        description: g.$3,
                        selected: _goal == g.$1,
                        onTap: () => setState(() => _goal = g.$1),
                      ),
                    ))
                .toList(),
          ),
        ),
    };
  }
}

/// One-question-per-screen layout: icon badge + title/subtitle + the
/// question's input widget.
class _QuestionStep extends StatelessWidget {
  const _QuestionStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.primaryGradientStart, c.primaryGradientEnd]),
            shape: BoxShape.circle,
            boxShadow: AppShadows.primaryGlow,
          ),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(title, style: AppText.title.copyWith(color: c.text)),
        const SizedBox(height: 4),
        Text(subtitle, style: AppText.bodySm.copyWith(color: c.textSubtle)),
        const SizedBox(height: AppSpacing.lg),
        child,
      ],
    );
  }
}

/// Large tappable option row used for single-choice questions (gender,
/// activity level, goal) — replaces the old cramped [AppChip] wrap.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
  });

  final IconData icon;
  final String label;
  final String? description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? c.primarySoft : c.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: selected ? c.primary : c.border, width: selected ? 1.6 : 1),
          boxShadow: selected ? AppShadows.sm : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.primary : c.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: selected ? Colors.white : c.textSubtle),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style:
                          AppText.bodyMedium.copyWith(color: c.text, fontWeight: FontWeight.w600)),
                  if (description != null)
                    Text(description!, style: AppText.caption.copyWith(color: c.textSubtle)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle_rounded, color: c.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Big centered number entry with +/- steppers, for age/height/weight
/// questions — one field per screen instead of a row of cramped inputs.
class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.suffix, required this.onChanged});

  final TextEditingController controller;
  final String suffix;
  final ValueChanged<String> onChanged;

  void _bump(int delta) {
    final v = (int.tryParse(controller.text) ?? 0) + delta;
    if (v < 0) return;
    controller.text = '$v';
    onChanged(controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        CircleIconButton(icon: Icons.remove_rounded, onTap: () => _bump(-1)),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: c.inputBackground,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: c.inputBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: onChanged,
                    style: AppText.title.copyWith(color: c.text, fontWeight: FontWeight.w800),
                    decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                  ),
                ),
                const SizedBox(width: 4),
                Text(suffix, style: AppText.bodySm.copyWith(color: c.textSubtle)),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        CircleIconButton(icon: Icons.add_rounded, onTap: () => _bump(1)),
      ],
    );
  }
}
