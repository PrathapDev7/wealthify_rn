import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  late DateTime _start;
  late DateTime _end;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month, now.day);
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: _end,
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null) setState(() => _end = picked);
  }

  List<List<String>> _csvRows(ReportData data, String Function(num?) money) {
    return [
      ['Date', 'Type', 'Category', 'Amount'],
      ...data.all.map((t) => [
            t.date,
            t.isIncome ? 'Income' : 'Expense',
            t.category,
            t.amount.toString(),
          ]),
    ];
  }

  Future<void> _exportCsv(ReportData data, String Function(num?) money) async {
    setState(() => _exporting = true);
    try {
      final csv = const CsvEncoder().convert(_csvRows(data, money));
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/wealthify_report.csv';
      await File(path).writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'text/csv')],
          subject: 'Wealthify report',
        ),
      );
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _exportPdf(ReportData data, String Function(num?) money) async {
    setState(() => _exporting = true);
    try {
      final doc = pw.Document();
      final rangeLabel = '${_df.format(_start)} to ${_df.format(_end)}';
      doc.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text('Wealthify report',
                style: pw.TextStyle(
                    fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(rangeLabel,
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            pw.SizedBox(height: 16),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfTotal('Income', money(data.income)),
                _pdfTotal('Expense', money(data.expense)),
                _pdfTotal('Net', money(data.net)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Type', 'Category', 'Amount'],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellAlignments: const {3: pw.Alignment.centerRight},
              cellStyle: const pw.TextStyle(fontSize: 10),
              data: data.all
                  .map((t) => [
                        t.date,
                        t.isIncome ? 'Income' : 'Expense',
                        t.category,
                        money(t.amount),
                      ])
                  .toList(),
            ),
          ],
        ),
      );
      await Printing.sharePdf(
          bytes: await doc.save(), filename: 'wealthify_report.pdf');
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  pw.Widget _pdfTotal(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
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
                // Custom range
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Custom range',
                          style: AppText.label.copyWith(color: c.textSubtle)),
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
                    onCsv: () => _exportCsv(data, money),
                    onPdf: () => _exportPdf(data, money),
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
    required this.onCsv,
    required this.onPdf,
  });

  final ReportData data;
  final String Function(num?) money;
  final bool exporting;
  final VoidCallback onCsv;
  final VoidCallback onPdf;

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
          label: 'Export CSV',
          variant: PillVariant.secondary,
          loading: exporting,
          leading: Icon(Icons.description_outlined, size: 18, color: c.text),
          onPressed: hasData && !exporting ? onCsv : null,
        ),
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: 'Export PDF',
          loading: exporting,
          leading:
              Icon(Icons.ios_share_outlined, size: 18, color: c.textOnPrimary),
          onPressed: hasData && !exporting ? onPdf : null,
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
