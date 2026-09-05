import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/models/workout_models.dart';
import '../../../data/repositories/workout_repository.dart';
import 'workout_widgets.dart';

/// The chart behind the bar-chart button on every exercise card and on the
/// session player: how this movement has gone over time.
Future<void> showExerciseHistory(
  BuildContext context, {
  required String name,
}) {
  return showFitnessSheet<void>(
    context: context,
    builder: (sheetContext) => _ExerciseHistorySheet(name: name),
  );
}

class _ExerciseHistorySheet extends ConsumerStatefulWidget {
  const _ExerciseHistorySheet({required this.name});

  final String name;

  @override
  ConsumerState<_ExerciseHistorySheet> createState() =>
      _ExerciseHistorySheetState();
}

class _ExerciseHistorySheetState extends ConsumerState<_ExerciseHistorySheet> {
  List<ExerciseHistoryPoint> _points = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final points = await ref
          .read(workoutRepositoryProvider)
          .exerciseHistory(widget.name);
      if (mounted) setState(() => _points = points);
    } catch (_) {
      // Nothing to show is the same outcome as failing to fetch, and the empty
      // state already says it plainly.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dateFmt = DateFormat('d MMM');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.name, style: AppText.subtitle.copyWith(color: c.text)),
          Text(
            'Best weight per session',
            style: AppText.caption.copyWith(color: c.textSubtle),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_loading)
            const _HistorySkeleton()
          else if (_points.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
              child: Text(
                'No history yet — finish a workout with this exercise and it '
                'will show up here.',
                style: AppText.body.copyWith(color: c.textSubtle),
              ),
            )
          else ...[
            SizedBox(height: 160, child: _chart(c)),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Newest first in the list, while the chart runs
                    // oldest-to-newest left-to-right.
                    for (final p in _points.reversed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 64,
                              child: Text(
                                p.date == null ? '--' : dateFmt.format(p.date!),
                                style: AppText.bodySm.copyWith(
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${p.sets} sets · ${p.totalReps} reps',
                                style: AppText.bodySm.copyWith(
                                  color: c.textSubtle,
                                ),
                              ),
                            ),
                            Text(
                              p.bestWeight > 0
                                  ? '${formatValue(p.bestWeight)} kg'
                                  : formatClock(p.totalDurationSec),
                              style: AppText.bodyMedium.copyWith(color: c.text),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chart(AppColors c) {
    // Weight is the headline for lifts and stays flat at zero for timed work,
    // where the total duration is the number that actually moves.
    final usesWeight = _points.any((p) => p.bestWeight > 0);
    final values = [
      for (final p in _points)
        usesWeight ? p.bestWeight : p.totalDurationSec.toDouble(),
    ];
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          show: true,
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => c.surfaceElevated,
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.x.round().clamp(0, values.length - 1);
              return LineTooltipItem(
                usesWeight
                    ? '${formatValue(values[i])} kg'
                    : formatClock(values[i].round()),
                AppText.caption.copyWith(color: c.text),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            color: c.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  c.primary.withValues(alpha: 0.22),
                  c.primary.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder mirroring the loaded layout: the chart, then a few
/// date / detail / value rows.
class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    Widget row() => const Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SkeletonLine(width: 50, height: 12),
          SizedBox(width: AppSpacing.md),
          Expanded(child: SkeletonLine(width: 100, height: 12)),
          SkeletonLine(width: 50, height: 14),
        ],
      ),
    );

    return Column(
      children: [
        const SkeletonBox(width: double.infinity, height: 160, radius: AppRadius.md),
        const SizedBox(height: AppSpacing.lg),
        row(),
        row(),
        row(),
        row(),
      ],
    );
  }
}
