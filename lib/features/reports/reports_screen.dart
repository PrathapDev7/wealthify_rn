import 'dart:io';

import 'package:excel/excel.dart' as xlsx;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transactions_repository.dart';
import '../auth/auth_screen.dart' show errorMessage;
import '../preferences/preferences_controller.dart';

/// Aggregated result for a date range: every transaction plus computed totals
/// and the expense-by-category breakdown (sorted desc).
typedef ReportData = ({
  List<TransactionModel> all,
  num income,
  num expense,
  num net,
  List<({String category, num amount})> categories,
});

final _df = DateFormat('yyyy-MM-dd');

/// Loads expenses + incomes for [(start, end)] and folds them into [ReportData].
final reportProvider = FutureProvider.autoDispose
    .family<ReportData, (DateTime, DateTime)>((ref, range) async {
  final repo = ref.read(transactionsRepositoryProvider);
  final query = {
    'start_date': _df.format(range.$1),
    'end_date': _df.format(range.$2),
  };
  final results = await Future.wait([
    repo.getExpenses(query),
    repo.getIncomes(query),
  ]);
  final expenseRes = results[0] as ExpenseResult;
  final incomes = results[1] as List<TransactionModel>;

  final expenses = expenseRes.items;
  final expenseTotal = expenseRes.total;
  final incomeTotal = incomes.fold<num>(0, (sum, i) => sum + i.amount);

  final byCategory = <String, num>{};
  for (final e in expenses) {
    final key = e.category.isEmpty ? 'Other' : e.category;
    byCategory[key] = (byCategory[key] ?? 0) + e.amount;
  }
  final categories = byCategory.entries
      .map((e) => (category: e.key, amount: e.value))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  return (
    all: [...expenses, ...incomes],
    income: incomeTotal,
    expense: expenseTotal,
    net: incomeTotal - expenseTotal,
    categories: categories,
  );
});

/// Quick date-range presets, mirroring the RN reports range selector.
enum _RangeKey { thisMonth, lastMonth, thisYear, custom }

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _start;
  late DateTime _end;
  _RangeKey _range = _RangeKey.thisMonth;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _applyPreset(_RangeKey.thisMonth);
  }

  /// Recomputes [_start]/[_end] for a preset and stores the active key.
  void _applyPreset(_RangeKey key) {
    final now = DateTime.now();
    switch (key) {
      case _RangeKey.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _start = lastMonth;
        _end = DateTime(now.year, now.month, 0); // last day of previous month
      case _RangeKey.thisYear:
        _start = DateTime(now.year, 1, 1);
        _end = DateTime(now.year, 12, 31);
      case _RangeKey.thisMonth:
      case _RangeKey.custom:
        _start = DateTime(now.year, now.month, 1);
        _end = DateTime(now.year, now.month, now.day);
    }
    _range = key;
  }

  void _selectPreset(_RangeKey key) => setState(() => _applyPreset(key));

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: _end,
    );
    if (picked != null) {
      setState(() {
        _start = picked;
        _range = _RangeKey.custom;
      });
    }
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        _end = picked;
        _range = _RangeKey.custom;
      });
    }
  }

  /// Best-available free-text label for a transaction row in exports
  /// (incomes prefer `title`, expenses use `description`).
  static String _describe(TransactionModel t) =>
      (t.isIncome ? (t.title ?? t.description) : t.description) ?? '';

  /// Converts a mixed row to Excel cells: whole numbers → int cells, other
  /// numbers → double cells, everything else → text.
  List<xlsx.CellValue?> _row(List<dynamic> cells) =>
      cells.map<xlsx.CellValue?>((v) {
        if (v is int) return xlsx.IntCellValue(v);
        if (v is num) {
          return v == v.roundToDouble()
              ? xlsx.IntCellValue(v.toInt())
              : xlsx.DoubleCellValue(v.toDouble());
        }
        return xlsx.TextCellValue('$v');
      }).toList();

  /// Excel sheet-name rules: ≤31 chars, none of []\/?*: , and unique.
  String _safeSheetName(String raw) {
    var s = raw.replaceAll(RegExp(r'[\[\]\\/\?\*:]'), ' ').trim();
    if (s.isEmpty) s = 'Sheet';
    if (s.length > 31) s = s.substring(0, 31).trim();
    return s;
  }

  String _uniqueSheetName(String base, Set<String> used) {
    var name = base;
    var n = 2;
    while (used.any((u) => u.toLowerCase() == name.toLowerCase())) {
      final suffix = ' ($n)';
      final maxBase = 31 - suffix.length;
      name =
          (base.length > maxBase ? base.substring(0, maxBase) : base) + suffix;
      n++;
    }
    used.add(name);
    return name;
  }

  /// Builds a multi-sheet workbook mirroring the user's ExpenseSheet layout:
  /// an `MM` summary (Income / Expenses / Savings + per-category totals) plus
  /// one sheet per category filled with its transactions (S.No/Date/Description/
  /// Amount + Total).
  Future<void> _exportXlsx(ReportData data) async {
    setState(() => _exporting = true);
    try {
      final excel = xlsx.Excel.createExcel();
      final first = excel.sheets.keys.first;
      if (first != 'MM') excel.rename(first, 'MM');
      final rangeLabel = '${_df.format(_start)} to ${_df.format(_end)}';

      // ── MM: monthly summary ──
      final mm = excel['MM'];
      mm.appendRow(_row(const ['Monthly Balance Sheet']));
      mm.appendRow(_row(['Range', rangeLabel]));
      mm.appendRow(_row(const ['']));
      mm.appendRow(_row(['Income', data.income]));
      mm.appendRow(_row(['Expenses', data.expense]));
      mm.appendRow(_row(['Savings (Net)', data.net]));
      mm.appendRow(_row(const ['']));
      mm.appendRow(_row(const ['Expenses by category', 'Amount']));
      for (final cat in data.categories) {
        mm.appendRow(_row([cat.category, cat.amount]));
      }
      mm.appendRow(_row(['Total Expenses', data.expense]));

      // ── One sheet per category, filled with its transactions ──
      final byCat = <String, List<TransactionModel>>{};
      for (final t in data.all) {
        final key = t.category.trim().isEmpty ? 'Other' : t.category.trim();
        (byCat[key] ??= []).add(t);
      }
      final totals = {
        for (final e in byCat.entries)
          e.key: e.value.fold<num>(0, (s, t) => s + t.amount)
      };
      final catNames = byCat.keys.toList()
        ..sort((a, b) => totals[b]!.compareTo(totals[a]!));

      final used = <String>{'MM'};
      for (final cat in catNames) {
        final sheet = excel[_uniqueSheetName(_safeSheetName(cat), used)];
        sheet.appendRow(_row(const ['S.No', 'Date', 'Description', 'Amount']));
        final txns = [...byCat[cat]!]..sort((a, b) => a.date.compareTo(b.date));
        var i = 1;
        for (final t in txns) {
          final desc = _describe(t);
          sheet.appendRow(
              _row([i, t.date, desc.isEmpty ? cat : desc, t.amount]));
          i++;
        }
        sheet.appendRow(_row(['', '', 'Total', totals[cat]!]));
      }

      final bytes = excel.encode();
      if (bytes == null) throw Exception('Could not build the workbook');
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/wealthify_report.xlsx';
      await File(path).writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(path,
                mimeType:
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
          ],
          subject: 'Wealthify report',
        ),
      );
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(reportProvider((_start, _end)));

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Reports'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
              children: [
                // Quick range presets
                _RangeSegmented(
                  value: _range,
                  onChanged: _selectPreset,
                ),
                const SizedBox(height: AppSpacing.md),
                // Custom range
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Custom range',
                              style:
                                  AppText.label.copyWith(color: c.textSubtle)),
                          if (_range == _RangeKey.custom)
                            GestureDetector(
                              onTap: () =>
                                  _selectPreset(_RangeKey.thisMonth),
                              child: Text('Clear',
                                  style:
                                      AppText.link.copyWith(color: c.primary)),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DateRow(
                        label: 'Start',
                        value: DateFormat('dd MMM yyyy').format(_start),
                        onTap: _pickStart,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _DateRow(
                        label: 'End',
                        value: DateFormat('dd MMM yyyy').format(_end),
                        onTap: _pickEnd,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                async.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xl4),
                    child: LoadingView(),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl2),
                    child: Column(
                      children: [
                        Text('Could not load report data',
                            style: AppText.bodySm
                                .copyWith(color: c.textSubtle)),
                        const SizedBox(height: AppSpacing.md),
                        PillButton(
                          label: 'Retry',
                          expand: false,
                          onPressed: () =>
                              ref.invalidate(reportProvider((_start, _end))),
                        ),
                      ],
                    ),
                  ),
                  data: (data) => _Report(
                    data: data,
                    money: money,
                    exporting: _exporting,
                    onExport: () => _exportXlsx(data),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented control for the quick range presets (This month / Last month /
/// This year). The active "custom" range is reflected by no preset being lit.
class _RangeSegmented extends StatelessWidget {
  const _RangeSegmented({required this.value, required this.onChanged});

  final _RangeKey value;
  final ValueChanged<_RangeKey> onChanged;

  static const _options = <(_RangeKey, String)>[
    (_RangeKey.thisMonth, 'This month'),
    (_RangeKey.lastMonth, 'Last month'),
    (_RangeKey.thisYear, 'This year'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          for (final opt in _options) ...[
            if (opt != _options.first) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(opt.$1),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: opt.$1 == value ? c.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    opt.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: opt.$1 == value ? c.textInverse : c.textSubtle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: c.inputBackground,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: c.inputBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: c.textSubtle),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppText.bodySm.copyWith(color: c.textSubtle)),
            const Spacer(),
            Text(value, style: AppText.bodyMedium.copyWith(color: c.text)),
          ],
        ),
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({
    required this.data,
    required this.money,
    required this.exporting,
    required this.onExport,
  });

  final ReportData data;
  final String Function(num?) money;
  final bool exporting;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasData = data.all.isNotEmpty;
    final maxCategory =
        data.categories.isEmpty ? 0 : data.categories.first.amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Income / Expense
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    label: 'Income',
                    value: money(data.income),
                    color: c.accentDark)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _StatCard(
                    label: 'Expense',
                    value: money(data.expense),
                    color: c.negative)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _StatCard(
          label: 'Net',
          value: money(data.net),
          color: data.net >= 0 ? c.accentDark : c.negative,
        ),

        // Spending by category
        const SizedBox(height: AppSpacing.xl),
        Text('Spending by category',
            style: AppText.label.copyWith(color: c.textSubtle)),
        const SizedBox(height: AppSpacing.sm),
        if (data.categories.isEmpty)
          AppCard(
            child: Column(
              children: [
                Icon(Icons.bar_chart_outlined, size: 34, color: c.textSubtle),
                const SizedBox(height: AppSpacing.sm),
                Text('No expenses in this range',
                    style: AppText.subtitle.copyWith(color: c.text)),
                const SizedBox(height: AppSpacing.xs),
                Text('Pick a different range to see a breakdown.',
                    textAlign: TextAlign.center,
                    style: AppText.bodySm.copyWith(color: c.textSubtle)),
              ],
            ),
          )
        else
          AppCard(
            child: Column(
              children: [
                for (var i = 0; i < data.categories.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(data.categories[i].category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.bodyMedium
                                    .copyWith(color: c.text)),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(money(data.categories[i].amount),
                              style:
                                  AppText.moneySm.copyWith(color: c.text)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppProgressBar(
                        value: maxCategory == 0
                            ? 0
                            : (data.categories[i].amount / maxCategory)
                                .toDouble(),
                        color: c.accentDark,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

        // Export
        const SizedBox(height: AppSpacing.xl),
        Text('Export', style: AppText.label.copyWith(color: c.textSubtle)),
        const SizedBox(height: AppSpacing.sm),
        PillButton(
          label: 'Export Excel',
          loading: exporting,
          leading:
              Icon(Icons.grid_on_outlined, size: 18, color: c.textOnPrimary),
          onPressed: hasData && !exporting ? onExport : null,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.label.copyWith(color: c.textSubtle)),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.titleLg.copyWith(color: color)),
        ],
      ),
    );
  }
}
