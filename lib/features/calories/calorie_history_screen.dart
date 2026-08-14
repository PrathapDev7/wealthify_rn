import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/weight_entry.dart';

String _errorMessage(Object e) => e.toString();

/// Weekly calories/macro trends — a 7-day window that can be paged
/// backwards/forwards, backed by `get-calorie-history`.
class CalorieHistoryScreen extends ConsumerStatefulWidget {
  const CalorieHistoryScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<CalorieHistoryScreen> createState() => _CalorieHistoryScreenState();
}

class _CalorieHistoryScreenState extends ConsumerState<CalorieHistoryScreen> {
  int _weekOffset = 0; // 0 = week containing today, -1 = previous week, ...
  bool _loading = false;
  List<DailyCalorieSummary> _days = [];

  DateTime get _weekStart {
    final now = DateTime.now();
    final mondayThisWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
    return mondayThisWeek.add(Duration(days: _weekOffset * 7));
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final start = _weekStart;
    final end = start.add(const Duration(days: 6));
    final fmt = DateFormat('yyyy-MM-dd');
    final repo = ref.read(caloriesRepositoryProvider);
    try {
      final res = await repo.getCalorieHistory(from: fmt.format(start), to: fmt.format(end));
      if (!mounted) return;
      setState(() {
        _days = (res['days'] as List? ?? [])
            .map((d) => DailyCalorieSummary.fromJson(d as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (mounted) showAppSnack(context, _errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _moveWeek(int delta) {
    setState(() => _weekOffset += delta);
    _fetch();
  }

  Map<String, DailyCalorieSummary> get _byDate => {
        for (final d in _days) d.date: d,
      };

  @override
  Widget build(BuildContext context) {
    final content = Expanded(
      child: RefreshIndicator(
        onRefresh: _fetch,
        color: context.colors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl4,
          ),
          children: [
            _WeekNavigator(
              weekStart: _weekStart,
              onPrev: () => _moveWeek(-1),
              onNext: _weekOffset < 0 ? () => _moveWeek(1) : null,
              onToday: _weekOffset == 0 ? null : () {
                setState(() => _weekOffset = 0);
                _fetch();
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_loading && _days.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl3),
                child: LoadingView(),
              )
            else if (_days.every((d) => d.calories == 0))
              const EmptyState(
                icon: Icons.show_chart_rounded,
                title: 'No meals logged this week',
                message: 'Log meals on the Today tab to see trends here.',
              )
            else ...[
              _WeeklyStatsRow(weekStart: _weekStart, byDate: _byDate),
              const SizedBox(height: AppSpacing.xl),
              _CaloriesBarChartCard(weekStart: _weekStart, byDate: _byDate),
            ],
          ],
        ),
      ),
    );

    if (widget.embedded) {
      return Column(children: [const SizedBox(height: AppSpacing.sm), content]);
    }

    return GradientScaffold(
      child: Column(
        children: [const ScreenHeader(title: 'Calorie History'), content],
      ),
    );
  }
}

class _WeekNavigator extends StatelessWidget {
  const _WeekNavigator({
    required this.weekStart,
    required this.onPrev,
    this.onNext,
    this.onToday,
  });

  final DateTime weekStart;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final weekEnd = weekStart.add(const Duration(days: 6));
    final sameMonth = weekStart.month == weekEnd.month;
    final label = sameMonth
        ? '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('d, yyyy').format(weekEnd)}'
        : '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d, yyyy').format(weekEnd)}';

    return Row(
      children: [
        CircleIconButton(icon: Icons.chevron_left, size: 32, iconSize: 18, onTap: onPrev),
        Expanded(
          child: Center(
            child: Text(label, style: AppText.bodyLarge.copyWith(color: c.text)),
          ),
        ),
        CircleIconButton(icon: Icons.chevron_right, size: 32, iconSize: 18, onTap: onNext),
        if (onToday != null) ...[
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: onToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: c.primarySoft,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                'Today',
                style: AppText.bodySm.copyWith(color: c.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _WeeklyStatsRow extends StatelessWidget {
  const _WeeklyStatsRow({required this.weekStart, required this.byDate});

  final DateTime weekStart;
  final Map<String, DailyCalorieSummary> byDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fmt = DateFormat('yyyy-MM-dd');
    final logged = [
      for (var i = 0; i < 7; i++)
        byDate[fmt.format(weekStart.add(Duration(days: i)))],
    ].whereType<DailyCalorieSummary>().where((d) => d.calories > 0).toList();

    final avgCalories = logged.isEmpty
        ? 0
        : (logged.fold<int>(0, (sum, d) => sum + d.calories) / logged.length).round();
    final avgProtein = logged.isEmpty
        ? 0.0
        : logged.fold<double>(0, (sum, d) => sum + d.protein) / logged.length;
    final avgCarbs = logged.isEmpty
        ? 0.0
        : logged.fold<double>(0, (sum, d) => sum + d.carbs) / logged.length;
    final avgFat = logged.isEmpty
        ? 0.0
        : logged.fold<double>(0, (sum, d) => sum + d.fat) / logged.length;

    return Row(
      children: [
        Expanded(child: _StatMini(label: 'Avg kcal/day', value: '$avgCalories', color: c.warning)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatMini(label: 'Avg protein', value: '${avgProtein.round()}g', color: c.accentDark)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatMini(label: 'Avg carbs', value: '${avgCarbs.round()}g', color: c.blue)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _StatMini(label: 'Avg fat', value: '${avgFat.round()}g', color: c.pink)),
      ],
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(value, style: AppText.bodyMedium.copyWith(color: c.text, fontWeight: FontWeight.w800)),
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

class _CaloriesBarChartCard extends StatelessWidget {
  const _CaloriesBarChartCard({required this.weekStart, required this.byDate});

  final DateTime weekStart;
  final Map<String, DailyCalorieSummary> byDate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fmt = DateFormat('yyyy-MM-dd');
    final days = [
      for (var i = 0; i < 7; i++) weekStart.add(Duration(days: i)),
    ];
    final summaries = [
      for (final d in days) byDate[fmt.format(d)],
    ];
    final target = summaries.firstWhere(
      (d) => d?.calorieTarget != null,
      orElse: () => null,
    )?.calorieTarget;
    final maxCalories = summaries.fold<int>(
      target ?? 0,
      (max, d) => (d?.calories ?? 0) > max ? d!.calories : max,
    );
    final maxY = (maxCalories * 1.2).clamp(500, 100000).toDouble();
    final todayKey = fmt.format(DateTime.now());

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            extraLinesData: target == null
                ? const ExtraLinesData()
                : ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: target.toDouble(),
                        color: c.accentDark.withValues(alpha: 0.6),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= days.length) return const SizedBox.shrink();
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
                getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                  '${rod.toY.round()} kcal\n${DateFormat('EEE, MMM d').format(days[group.x])}',
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
                      toY: (summaries[i]?.calories ?? 0).toDouble(),
                      color: fmt.format(days[i]) == todayKey ? c.primary : c.primary.withValues(alpha: 0.45),
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
