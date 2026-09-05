import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/workout_models.dart';
import '../../data/repositories/workout_repository.dart';
import 'fitness_stats_screen.dart';
import 'workout/workout_history_screen.dart';
import 'workout/workout_session_detail_screen.dart';
import 'workout/workout_widgets.dart';

/// Fitness home, laid out like Healthify's: the week's dates across the top of
/// a coloured panel, the day's training in one hero card with three smaller
/// ones under it, and that day's workouts listed below.
///
/// Hosted inside the Home tab under the app switcher, so it renders as a
/// column rather than a Scaffold.
class FitnessHomeScreen extends ConsumerStatefulWidget {
  const FitnessHomeScreen({super.key, this.heroWrapper});

  /// Wraps the hero — the date picker and the day's cards — in the coloured
  /// panel the Home tab draws behind the app switcher. Null renders the same
  /// content flat on the background, for a host with no panel of its own.
  final Widget Function(BuildContext context, Widget hero)? heroWrapper;

  @override
  ConsumerState<FitnessHomeScreen> createState() => _FitnessHomeScreenState();
}

class _FitnessHomeScreenState extends ConsumerState<FitnessHomeScreen> {
  DateTime _selectedDate = DateTime.now();

  /// The chosen day, and the week around it — the small cards read as "today
  /// out of this week", so both ranges are wanted at once.
  WorkoutStats _day = const WorkoutStats();
  WorkoutStats _week = const WorkoutStats();
  bool _loading = true;

  DateTime get _dayStart =>
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

  DateTime get _weekStart {
    final day = _dayStart;
    return day.subtract(Duration(days: day.weekday - 1));
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    final repo = ref.read(workoutRepositoryProvider);
    final day = _dayStart;
    final week = _weekStart;
    try {
      final results = await Future.wait([
        repo.workoutStats(from: day, to: day.add(const Duration(days: 1))),
        repo.workoutStats(from: week, to: week.add(const Duration(days: 7))),
      ]);
      if (!mounted) return;
      setState(() {
        _day = results[0];
        _week = results[1];
      });
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _fetch();
  }

  void _moveDate(int days) =>
      _selectDate(_selectedDate.add(Duration(days: days)));

  Future<void> _openSession(WorkoutSessionRow row) async {
    await pushFitness<bool>(
      context,
      WorkoutSessionDetailScreen(sessionId: row.id),
    );
    if (mounted) await _fetch();
  }

  /// Exercises are counted per session rather than in the totals, so they are
  /// summed off the rows the range came back with.
  int _exerciseCount(WorkoutStats stats) =>
      stats.sessions.fold(0, (sum, row) => sum + row.exerciseCount);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final wrapper = widget.heroWrapper;
    // On the coloured panel the date picker has to read against the palette,
    // not against the background it would otherwise sit on.
    final onHero = wrapper != null;
    final today = DateTime.now();
    final isToday =
        _dayStart == DateTime(today.year, today.month, today.day);

    final hero = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HorizontalDatePicker(
            selectedDate: _selectedDate,
            onDateSelected: _selectDate,
            onTodayTap: () => _selectDate(DateTime.now()),
            onPrevTap: () => _moveDate(-1),
            onNextTap: () => _moveDate(1),
            onGradient: onHero,
          ),
          const SizedBox(height: AppSpacing.xl),
          _TrainingHeroCard(
            totals: _day.totals,
            onTap: () => pushFitness<void>(context, const FitnessStatsScreen()),
          ),
          const SizedBox(height: AppSpacing.md),
          _TrainingStatsRow(
            day: _day,
            week: _week,
            dayExercises: _exerciseCount(_day),
            weekExercises: _exerciseCount(_week),
          ),
        ],
      ),
    );

    return Container(
      color: c.background,
      child: Column(
        children: [
          if (wrapper == null) hero else wrapper(context, hero),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetch,
              color: c.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.screenBottomInset,
                ),
                children: [
                  SectionHeader(
                    isToday
                        ? "Today's Workouts"
                        : '${DateFormat('d MMM').format(_selectedDate)} '
                              'Workouts',
                    actionLabel: 'See all',
                    onAction: () => pushFitness<void>(
                      context,
                      const WorkoutHistoryScreen(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_loading && _day.sessions.isEmpty)
                    const WorkoutSessionListSkeleton(count: 3)
                  else if (_day.sessions.isEmpty)
                    EmptyState(
                      icon: Icons.fitness_center_rounded,
                      title: 'No workouts logged',
                      message: isToday
                          ? 'Start one from the Workouts tab.'
                          : 'Nothing was trained on this day.',
                    )
                  else
                    for (final row in _day.sessions)
                      WorkoutSessionRowCard(
                        row: row,
                        onTap: () => _openSession(row),
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

/// The day's training in one card — minutes in the circle, then the two
/// headline counts. Healthify's calorie hero, with sets and workouts in place
/// of consumed and goal.
class _TrainingHeroCard extends StatelessWidget {
  const _TrainingHeroCard({required this.totals, required this.onTap});

  final WorkoutTotals totals;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final minutes = totals.durationSec ~/ 60;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: c.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$minutes',
                    style: AppText.bodyLarge.copyWith(color: c.text),
                  ),
                  Text(
                    'min',
                    style: AppText.caption.copyWith(color: c.textSubtle),
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
                        Icons.fitness_center_rounded,
                        size: 16,
                        color: c.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Daily Training',
                        style: AppText.bodyMedium.copyWith(color: c.text),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: c.textSubtle,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _stat(c, 'Workouts', '${totals.workouts}'),
                      ),
                      Container(width: 1, height: 26, color: c.divider),
                      Expanded(
                        child: _stat(c, 'Time', formatClock(totals.durationSec)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(AppColors c, String label, String value) => Padding(
    padding: const EdgeInsets.only(left: AppSpacing.sm),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.bodyMedium.copyWith(color: c.text)),
        Text(label, style: AppText.caption.copyWith(color: c.textSubtle)),
      ],
    ),
  );
}

/// The three small cards under the hero — sets, exercises and volume, each
/// showing the day against the week the way the macro cards show grams against
/// a goal.
class _TrainingStatsRow extends StatelessWidget {
  const _TrainingStatsRow({
    required this.day,
    required this.week,
    required this.dayExercises,
    required this.weekExercises,
  });

  final WorkoutStats day;
  final WorkoutStats week;
  final int dayExercises;
  final int weekExercises;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: _StatMiniCard(
            icon: Icons.repeat_rounded,
            label: 'Sets',
            value: day.totals.completedSets,
            weekValue: week.totals.completedSets,
            color: c.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatMiniCard(
            icon: Icons.list_alt_rounded,
            label: 'Exercises',
            value: dayExercises,
            weekValue: weekExercises,
            color: c.accentDark,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatMiniCard(
            icon: Icons.monitor_weight_rounded,
            label: 'Volume',
            value: day.totals.volume.round(),
            weekValue: week.totals.volume.round(),
            suffix: 'kg',
            color: c.warning,
          ),
        ),
      ],
    );
  }
}

class _StatMiniCard extends StatelessWidget {
  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.weekValue,
    required this.color,
    this.suffix = '',
  });

  final IconData icon;
  final String label;

  /// The selected day, and the week it falls in — the bar is the day's share
  /// of that week, which is the only reference a workout has without inventing
  /// a target for it.
  final int value;
  final int weekValue;

  final String suffix;
  final Color color;

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
                  style: AppText.bodySm.copyWith(color: c.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value/$weekValue$suffix',
            style: AppText.caption.copyWith(color: c.textSubtle),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppProgressBar(
            value: weekValue == 0 ? 0 : value / weekValue,
            color: color,
            height: 4,
          ),
        ],
      ),
    );
  }
}
