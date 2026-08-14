import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/weight_entry.dart';

String _errorMessage(Object e) => e.toString();

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key, this.embedded = false});

  /// When true, renders without the outer [GradientScaffold]/[ScreenHeader]
  /// chrome so it can be dropped in as a Healthify sub-tab.
  final bool embedded;

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  final TextEditingController _weightController = TextEditingController();
  bool _loading = false;
  bool _saving = false;
  List<WeightEntry> _entries = [];
  double? _targetWeightKg;
  double? _currentWeightKg;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    final repo = ref.read(caloriesRepositoryProvider);
    try {
      final res = await repo.getWeightHistory();
      if (!mounted) return;
      setState(() {
        _entries = (res['entries'] as List? ?? [])
            .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        _targetWeightKg = (res['targetWeightKg'] as num?)?.toDouble();
        _currentWeightKg = (res['currentWeightKg'] as num?)?.toDouble();
      });
    } catch (e) {
      if (mounted) showAppSnack(context, _errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? get _latestWeightKg =>
      _entries.isNotEmpty ? _entries.last.weightKg : _currentWeightKg;

  Future<void> _logWeight() async {
    final value = double.tryParse(_weightController.text.trim());
    if (value == null || value <= 0) {
      showAppSnack(context, 'Enter a valid weight', error: true);
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(caloriesRepositoryProvider);
    try {
      await repo.addWeightEntry(weightKg: value);
      _weightController.clear();
      await _fetch();
      if (mounted) showAppSnack(context, 'Weight logged');
    } catch (e) {
      if (mounted) showAppSnack(context, _errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteEntry(WeightEntry entry) async {
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
      await _fetch();
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
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            bottom + AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
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
        );
      },
    );
    if (result == null || result <= 0 || !mounted) return;
    final repo = ref.read(caloriesRepositoryProvider);
    try {
      await repo.updateTargetWeight(result);
      await _fetch();
      if (mounted) showAppSnack(context, 'Goal weight updated');
    } catch (e) {
      if (mounted) showAppSnack(context, _errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading && _entries.isEmpty
        ? const LoadingView()
        : Expanded(
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
                  _WeightHeroCard(
                    currentWeightKg: _latestWeightKg,
                    targetWeightKg: _targetWeightKg,
                    onEditTarget: _editTarget,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_entries.length >= 2) ...[
                    _WeightChartCard(
                      entries: _entries,
                      targetWeightKg: _targetWeightKg,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                  _LogWeightCard(
                    controller: _weightController,
                    saving: _saving,
                    onSubmit: _saving ? null : _logWeight,
                  ),
                  const SizedBox(height: AppSpacing.xl2),
                  const SectionHeader('History'),
                  const SizedBox(height: AppSpacing.md),
                  if (_entries.isEmpty && !_loading)
                    const EmptyState(
                      icon: Icons.monitor_weight_outlined,
                      title: 'No weight logged yet',
                      message: 'Log your weight above to start tracking progress.',
                    )
                  else
                    ...[for (final e in _entries.reversed) e].map(
                      (e) => _WeightHistoryRow(
                        entry: e,
                        onDelete: () => _deleteEntry(e),
                      ),
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
        children: [const ScreenHeader(title: 'Weight Tracker'), content],
      ),
    );
  }
}

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

class _LogWeightCard extends StatelessWidget {
  const _LogWeightCard({required this.controller, required this.saving, required this.onSubmit});

  final TextEditingController controller;
  final bool saving;
  final VoidCallback? onSubmit;

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
              Icon(Icons.monitor_weight_rounded, size: 18, color: c.primary),
              const SizedBox(width: AppSpacing.xs),
              Text("Today's weight", style: AppText.label.copyWith(color: c.textSubtle)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: controller,
                  hint: 'e.g. 72.5',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  fillColor: c.surfaceMuted,
                  borderColor: c.primary.withValues(alpha: 0.28),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              PillButton(
                label: 'Log',
                loading: saving,
                expand: false,
                onPressed: onSubmit,
              ),
            ],
          ),
        ],
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
