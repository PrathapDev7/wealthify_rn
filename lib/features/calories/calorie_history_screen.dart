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
  DateTime _selectedDate = DateTime.now();
  bool _loading = false;
  List<DailyCalorieSummary> _days = [];

  bool _weightLoading = false;
  List<WeightEntry> _weightEntries = [];
  double? _targetWeightKg;
  double? _currentWeightKg;

  DateTime get _weekStart {
    final now = DateTime.now();
    final mondayThisWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
    return mondayThisWeek.add(Duration(days: _weekOffset * 7));
  }

  int _weekOffsetFor(DateTime date) {
    final now = DateTime.now();
    final mondayThisWeek = DateTime(now.year, now.month, now.day - now.weekday + 1);
    final mondayOfDate = DateTime(date.year, date.month, date.day - date.weekday + 1);
    return mondayOfDate.difference(mondayThisWeek).inDays ~/ 7;
  }

  @override
  void initState() {
    super.initState();
    _fetch();
    _fetchWeight();
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
    setState(() {
      _weekOffset += delta;
      _selectedDate = _weekStart;
    });
    _fetch();
  }

  Map<String, DailyCalorieSummary> get _byDate => {
        for (final d in _days) d.date: d,
      };

  Future<void> _fetchWeight() async {
    setState(() => _weightLoading = true);
    final repo = ref.read(caloriesRepositoryProvider);
    try {
      final res = await repo.getWeightHistory();
      if (!mounted) return;
      setState(() {
        _weightEntries = (res['entries'] as List? ?? [])
            .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        _targetWeightKg = (res['targetWeightKg'] as num?)?.toDouble();
        _currentWeightKg = (res['currentWeightKg'] as num?)?.toDouble();
      });
    } catch (e) {
      if (mounted) showAppSnack(context, _errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _weightLoading = false);
    }
  }

  double? get _latestWeightKg =>
      _weightEntries.isNotEmpty ? _weightEntries.last.weightKg : _currentWeightKg;

  Future<void> _deleteWeightEntry(WeightEntry entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete weight entry?'),
        content: Text('Remove the entry from ${entry.date}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: context.colors.negative)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final repo = ref.read(caloriesRepositoryProvider);
    try {
      await repo.deleteWeightEntry(entry.id);
      await _fetchWeight();
    } catch (e) {
      if (mounted) showAppSnack(context, _errorMessage(e), error: true);
    }
  }

  Future<void> _editTarget() async {
    final controller = TextEditingController(
      text: _targetWeightKg != null ? '${_targetWeightKg!.round()}' : '',
    );
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = ctx.colors;
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Container(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
                  Text('Set goal weight', style: AppText.title.copyWith(color: c.text)),
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
      await _fetchWeight();
      if (mounted) showAppSnack(context, 'Goal weight updated');
    } catch (e) {
      if (mounted) showAppSnack(context, _errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Expanded(
      child: RefreshIndicator(
        onRefresh: () => Future.wait([_fetch(), _fetchWeight()]),
        color: context.colors.primary,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl4,
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
            const SizedBox(height: AppSpacing.xl2),
            const SectionHeader('Weight'),
            const SizedBox(height: AppSpacing.md),
            if (_weightLoading && _weightEntries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl3),
                child: LoadingView(),
              )
            else ...[
              _WeightHeroCard(
                currentWeightKg: _latestWeightKg,
                targetWeightKg: _targetWeightKg,
                onEditTarget: _editTarget,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_weightEntries.length >= 2) ...[
                _WeightChartCard(
                  entries: _weightEntries,
                  targetWeightKg: _targetWeightKg,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_weightEntries.isEmpty)
                const EmptyState(
                  icon: Icons.monitor_weight_outlined,
                  title: 'No weight logged yet',
                  message: 'Use the + button to log your weight.',
                )
              else
                ...[for (final e in _weightEntries.reversed) e].map(
                  (e) => _WeightHistoryRow(
                    entry: e,
                    onDelete: () => _deleteWeightEntry(e),
                  ),
                ),
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
        children: [const ScreenHeader(title: 'Statistics'), content],
      ),
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

// ── Weight ────────────────────────────────────────────────────────────────

class _WeightHeroCard extends StatelessWidget {
  const _WeightHeroCard({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.onEditTarget,
  });

  final double? currentWeightKg;
  final double? targetWeightKg;
  final VoidCallback onEditTarget;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasBoth = currentWeightKg != null && targetWeightKg != null;
    final delta = hasBoth ? currentWeightKg! - targetWeightKg! : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current', style: AppText.label.copyWith(color: c.textSubtle)),
                const SizedBox(height: 2),
                Text(
                  currentWeightKg != null ? '${currentWeightKg!.toStringAsFixed(1)} kg' : '—',
                  style: AppText.bodyLarge.copyWith(color: c.text, fontWeight: FontWeight.w800),
                ),
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
                  Row(
                    children: [
                      Text('Goal', style: AppText.label.copyWith(color: c.textSubtle)),
                      const Spacer(),
                      GestureDetector(
                        onTap: onEditTarget,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                          child: Icon(Icons.edit_rounded, size: 12, color: c.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    targetWeightKg != null ? '${targetWeightKg!.toStringAsFixed(1)} kg' : 'Not set',
                    style: AppText.bodyLarge.copyWith(color: c.text, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          if (delta != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: (delta.abs() < 0.05 ? c.accentDark : c.warning).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                delta.abs() < 0.05
                    ? 'On target'
                    : '${delta > 0 ? '-' : '+'}${delta.abs().toStringAsFixed(1)} kg to go',
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

class _WeightChartCard extends StatelessWidget {
  const _WeightChartCard({required this.entries, required this.targetWeightKg});

  final List<WeightEntry> entries;
  final double? targetWeightKg;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final weights = entries.map((e) => e.weightKg).toList();
    var minY = weights.reduce((a, b) => a < b ? a : b);
    var maxY = weights.reduce((a, b) => a > b ? a : b);
    if (targetWeightKg != null) {
      minY = minY < targetWeightKg! ? minY : targetWeightKg!;
      maxY = maxY > targetWeightKg! ? maxY : targetWeightKg!;
    }
    final pad = ((maxY - minY).abs() < 2 ? 2 : (maxY - minY) * 0.15) + 0.5;
    minY -= pad;
    maxY += pad;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(
              show: true,
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            extraLinesData: targetWeightKg == null
                ? const ExtraLinesData()
                : ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: targetWeightKg!,
                        color: c.accentDark.withValues(alpha: 0.6),
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                      ),
                    ],
                  ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => c.surfaceElevated,
                getTooltipItems: (spots) => spots.map((s) {
                  final i = s.x.round().clamp(0, entries.length - 1);
                  return LineTooltipItem(
                    '${entries[i].weightKg.toStringAsFixed(1)} kg\n${entries[i].date}',
                    AppText.caption.copyWith(color: c.text),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < weights.length; i++) FlSpot(i.toDouble(), weights[i]),
                ],
                isCurved: true,
                color: c.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.primary.withValues(alpha: 0.22), c.primary.withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightHistoryRow extends StatelessWidget {
  const _WeightHistoryRow({required this.entry, required this.onDelete});

  final WeightEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = () {
      try {
        return DateFormat('EEE, MMM d').format(DateTime.parse(entry.date));
      } catch (_) {
        return entry.date;
      }
    }();
    return GestureDetector(
      onLongPress: onDelete,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            Icon(Icons.monitor_weight_outlined, size: 18, color: c.textSubtle),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(label, style: AppText.bodySm.copyWith(color: c.text)),
            ),
            Text(
              '${entry.weightKg.toStringAsFixed(1)} kg',
              style: AppText.bodySm.copyWith(color: c.text, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
