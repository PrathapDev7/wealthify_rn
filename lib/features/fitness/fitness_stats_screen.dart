import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/workout_models.dart';
import '../../data/repositories/workout_repository.dart';
import 'workout/workout_history_screen.dart';
import 'workout/workout_session_detail_screen.dart';
import 'workout/workout_widgets.dart';

/// Fitness → Statistics: the same shape as the Healthify statistics screen —
/// a week strip, a row of totals, a bar chart, then the detail underneath —
/// so switching apps does not mean learning a new page.
class FitnessStatsScreen extends ConsumerStatefulWidget {
  const FitnessStatsScreen({super.key, this.embedded = false});

  /// True when hosted inside the Analytics tab, which draws its own header.
  final bool embedded;

  @override
  ConsumerState<FitnessStatsScreen> createState() => _FitnessStatsScreenState();
}

class _FitnessStatsScreenState extends ConsumerState<FitnessStatsScreen> {
  int _weekOffset = 0; // 0 = the week containing today, -1 = the one before.
  DateTime _selectedDate = DateTime.now();

  WorkoutStats _stats = const WorkoutStats();
  bool _loading = true;

  DateTime get _weekStart {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day - now.weekday + 1);
    return monday.add(Duration(days: _weekOffset * 7));
  }

  int _weekOffsetFor(DateTime date) {
    final now = DateTime.now();
    final mondayThisWeek = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + 1,
    );
    final mondayOfDate = DateTime(
      date.year,
      date.month,
      date.day - date.weekday + 1,
    );
    return mondayOfDate.difference(mondayThisWeek).inDays ~/ 7;
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final start = _weekStart;
    // Exclusive end: the range runs to the last instant of Sunday in the
    // user's own timezone, which is what the week strip shows them.
    final end = start.add(const Duration(days: 7));
    try {
      final stats = await ref
          .read(workoutRepositoryProvider)
          .workoutStats(from: start, to: end);
      if (mounted) setState(() => _stats = stats);
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _moveWeek(int delta) {
    setState(() {
      _weekOffset += delta;
      _selectedDate = _weekStart;
    });
    _fetch();
  }

  /// Minutes trained per weekday, bucketed on the phone — the API deliberately
  /// hands back raw rows because it does not know the user's timezone.
  List<int> get _minutesByDay {
    final start = _weekStart;
    final minutes = List<int>.filled(7, 0);
    for (final session in _stats.sessions) {
      final at = session.startedAt?.toLocal();
      if (at == null) continue;
      final index = DateTime(
        at.year,
        at.month,
        at.day,
      ).difference(DateTime(start.year, start.month, start.day)).inDays;
      if (index < 0 || index > 6) continue;
      minutes[index] += (session.durationSec / 60).round();
    }
    return minutes;
  }

  Future<void> _openSession(WorkoutSessionRow row) async {
    final changed = await pushFitness<bool>(
      context,
      WorkoutSessionDetailScreen(sessionId: row.id),
    );
    if (changed == true) await _fetch();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final totals = _stats.totals;
    final slices = [
      for (final m in _stats.muscles)
        if (m.count > 0) MuscleSlice(label: m.muscle, count: m.count),
    ];

    final content = Expanded(
      child: RefreshIndicator(
        onRefresh: _fetch,
        color: c.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.screenBottomInset,
          ),
          children: [
            HorizontalDatePicker(
              selectedDate: _selectedDate,
              onDateSelected: (date) {
                setState(() {
                  _selectedDate = date;
                  _weekOffset = _weekOffsetFor(date);
                });
                _fetch();
              },
              onTodayTap: () {
                setState(() {
                  _selectedDate = DateTime.now();
                  _weekOffset = 0;
                });
                _fetch();
              },
              onPrevTap: () => _moveWeek(-1),
              onNextTap: _weekOffset < 0 ? () => _moveWeek(1) : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_loading)
              const _StatsSkeleton()
            else if (_stats.isEmpty)
              const EmptyState(
                icon: Icons.insights_rounded,
                title: 'Nothing logged this week',
                message: 'Finish a workout and your training shows up here.',
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _StatMini(
                      label: 'Workouts',
                      value: '${totals.workouts}',
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatMini(
                      label: 'Time',
                      value: _shortDuration(totals.durationSec),
                      color: c.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatMini(
                      label: 'Sets',
                      value: '${totals.completedSets}',
                      color: c.blue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatMini(
                      label: 'Volume',
                      value: _shortVolume(totals.volume),
                      color: c.pink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _MinutesBarChart(weekStart: _weekStart, minutes: _minutesByDay),
              if (slices.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl2),
                const SectionHeader('Muscle split'),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: MuscleDonut(
                    muscles: slices,
                    centerValue: '${totals.completedSets}',
                    centerLabel: totals.completedSets == 1 ? 'set' : 'sets',
                    size: 190,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                MuscleLegend(muscles: slices),
              ],
              const SizedBox(height: AppSpacing.xl2),
              SectionHeader(
                'This week',
                actionLabel: 'All workouts',
                onAction: () =>
                    pushFitness<void>(context, const WorkoutHistoryScreen()),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final row in _stats.sessions)
                WorkoutSessionRowCard(
                  row: row,
                  onTap: () => _openSession(row),
                ),
            ],
          ],
        ),
      ),
    );

    if (widget.embedded) {
      // The host tab paints the app-wide background, so the Fitness ground has
      // to be laid down here or the dark palette sits on a light page.
      return Container(
        color: c.background,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                'Statistics',
                style: AppText.screenTitle.copyWith(color: c.text),
              ),
            ),
            content,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  FitnessIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    iconSize: 16,
                    background: Colors.transparent,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Statistics',
                    style: AppText.screenTitle.copyWith(color: c.text),
                  ),
                ],
              ),
            ),
            content,
          ],
        ),
      ),
    );
  }
}

/// `1h 20m` rather than `01:20:00` — a week's total is read at a glance, not
/// counted down.
String _shortDuration(int seconds) {
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '${minutes}m';
  return '${minutes ~/ 60}h ${minutes % 60}m';
}

String _shortVolume(double volume) {
  if (volume <= 0) return '-';
  if (volume < 1000) return '${volume.round()}kg';
  return '${(volume / 1000).toStringAsFixed(1)}t';
}

/// Loading placeholder mirroring the loaded layout: the four mini stat
/// cards, the bar chart, and a couple of session rows.
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget miniCard() => const Expanded(
      child: SkeletonBox(width: double.infinity, height: 72, radius: AppRadius.md),
    );

    return Column(
      children: [
        Row(
          children: [
            miniCard(),
            const SizedBox(width: AppSpacing.sm),
            miniCard(),
            const SizedBox(width: AppSpacing.sm),
            miniCard(),
            const SizedBox(width: AppSpacing.sm),
            miniCard(),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const SkeletonBox(width: double.infinity, height: 160, radius: AppRadius.md),
        const SizedBox(height: AppSpacing.xl2),
        const WorkoutSessionRowSkeleton(),
        const WorkoutSessionRowSkeleton(),
      ],
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: AppText.bodyMedium.copyWith(
              color: c.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(color: c.textSubtle),
          ),
        ],
      ),
    );
  }
}

class _MinutesBarChart extends StatelessWidget {
  const _MinutesBarChart({required this.weekStart, required this.minutes});

  final DateTime weekStart;
  final List<int> minutes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final days = [for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i))];
    final peak = minutes.fold<int>(0, (max, m) => m > max ? m : max);
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            maxY: (peak * 1.25).clamp(30, 100000).toDouble(),
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= days.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        DateFormat('EEE').format(days[i]).substring(0, 1),
                        style: AppText.caption.copyWith(color: c.textSubtle),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => c.surfaceElevated,
                getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                    BarTooltipItem(
                      '${rod.toY.round()} min\n'
                      '${DateFormat('EEE, MMM d').format(days[group.x])}',
                      AppText.caption.copyWith(color: c.text),
                    ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < days.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: minutes[i].toDouble(),
                      color: DateFormat('yyyy-MM-dd').format(days[i]) == todayKey
                          ? c.primary
                          : c.primary.withValues(alpha: 0.45),
                      width: 18,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
