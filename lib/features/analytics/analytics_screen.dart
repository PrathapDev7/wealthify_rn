import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/category_icon.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/wealthify_icon.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../data/repositories/wallets_repository.dart';
import '../preferences/preferences_controller.dart';
import '../wallets/wallet_ui.dart';

// ── Range model ─────────────────────────────────────────────────────────────

enum AnalyticsRange { today, yesterday, last3Days, thisWeek, thisMonth, thisYear }

extension on AnalyticsRange {
  String get label => switch (this) {
        AnalyticsRange.today => 'Today',
        AnalyticsRange.yesterday => 'Yesterday',
        AnalyticsRange.last3Days => 'Last 3 days',
        AnalyticsRange.thisWeek => 'This week',
        AnalyticsRange.thisMonth => 'This month',
        AnalyticsRange.thisYear => 'This year',
      };

  /// Lowercased label used in empty-state copy ("Last 3 days" → "the last 3 days").
  String get emptyLabel =>
      this == AnalyticsRange.last3Days ? 'the last 3 days' : label.toLowerCase();
}

/// Inclusive [start, end] day window for a range, mirroring the RN
/// `buildDateRange` helper (weeks start on Monday / isoWeek).
({DateTime start, DateTime end}) _dateRange(AnalyticsRange range) {
  final now = DateTime.now();
  DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  switch (range) {
    case AnalyticsRange.today:
      return (start: startOfDay(now), end: endOfDay(now));
    case AnalyticsRange.yesterday:
      final y = now.subtract(const Duration(days: 1));
      return (start: startOfDay(y), end: endOfDay(y));
    case AnalyticsRange.last3Days:
      return (start: startOfDay(now.subtract(const Duration(days: 2))), end: endOfDay(now));
    case AnalyticsRange.thisWeek:
      final monday = startOfDay(now.subtract(Duration(days: now.weekday - 1)));
      return (start: monday, end: endOfDay(monday.add(const Duration(days: 6))));
    case AnalyticsRange.thisMonth:
      final first = DateTime(now.year, now.month, 1);
      final last = DateTime(now.year, now.month + 1, 0);
      return (start: first, end: endOfDay(last));
    case AnalyticsRange.thisYear:
      return (start: DateTime(now.year, 1, 1), end: endOfDay(DateTime(now.year, 12, 31)));
  }
}

// ── Aggregated data + provider ───────────────────────────────────────────────

/// A single time bucket (a day or a month) over the selected range.
class AnalyticsBucket {
  const AnalyticsBucket(this.key, this.label, this.longLabel, this.income, this.expense);
  final String key;
  final String label; // short axis label
  final String longLabel; // tooltip / detail-row label
  final num income;
  final num expense;
  num get net => income - expense;
}

/// A category slice of expenses for the History breakdown.
class CategorySlice {
  const CategorySlice(this.category, this.amount);
  final String category;
  final num amount;
}

/// Everything the screen renders for one range, computed in Dart.
class AnalyticsData {
  const AnalyticsData({
    required this.income,
    required this.expense,
    required this.buckets,
    required this.categories,
    required this.byAccount,
  });

  final num income;
  final num expense;
  final List<AnalyticsBucket> buckets;
  final List<CategorySlice> categories;

  /// Per-wallet (account id → income/expense) within the range. '' = unassigned.
  final Map<String, ({num income, num expense})> byAccount;

  num get balance => income - expense;
  bool get hasData => income > 0 || expense > 0;
}

final _bucketKeyFmt = DateFormat('yyyy-MM');
final _dayKeyFmt = DateFormat('yyyy-MM-dd');

DateTime? _parseDate(String raw) {
  if (raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// Self-contained loader: fetches expenses + incomes for the range straight from
/// the repository (no coupling to the transactions screen), then folds them into
/// totals, per-period buckets and the expense-by-category breakdown.
final analyticsDataProvider =
    FutureProvider.autoDispose.family<AnalyticsData, AnalyticsRange>((ref, range) async {
  final repo = ref.read(transactionsRepositoryProvider);
  final window = _dateRange(range);
  final query = {
    'start_date': _dayKeyFmt.format(window.start),
    'end_date': _dayKeyFmt.format(window.end),
  };

  final results = await Future.wait([
    repo.getExpenses(query),
    repo.getIncomes(query),
  ]);
  final expenseRes = results[0] as ExpenseResult;
  final incomes = results[1] as List<TransactionModel>;
  final expenses = expenseRes.items;

  bool inWindow(TransactionModel t) {
    final d = _parseDate(t.date);
    if (d == null) return false;
    return !d.isBefore(window.start) && !d.isAfter(window.end);
  }

  final rangeIncomes = incomes.where(inWindow).toList();
  final rangeExpenses = expenses.where(inWindow).toList();

  final byMonth = range == AnalyticsRange.thisYear;
  String? bucketKey(TransactionModel t) {
    final d = _parseDate(t.date);
    if (d == null) return null;
    return byMonth ? _bucketKeyFmt.format(d) : _dayKeyFmt.format(d);
  }

  Map<String, num> sumByBucket(List<TransactionModel> list) {
    final acc = <String, num>{};
    for (final t in list) {
      final k = bucketKey(t);
      if (k == null) continue;
      acc[k] = (acc[k] ?? 0) + t.amount;
    }
    return acc;
  }

  final incByBucket = sumByBucket(rangeIncomes);
  final expByBucket = sumByBucket(rangeExpenses);

  // Build the ordered list of period buckets spanning the window.
  final buckets = <AnalyticsBucket>[];
  if (byMonth) {
    final now = DateTime.now();
    var cursor = DateTime(window.start.year, window.start.month, 1);
    while (!cursor.isAfter(DateTime(now.year, now.month, 1))) {
      final key = _bucketKeyFmt.format(cursor);
      final mon = DateFormat('MMM').format(cursor);
      buckets.add(AnalyticsBucket(key, mon, mon, incByBucket[key] ?? 0, expByBucket[key] ?? 0));
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
  } else {
    var cursor = DateTime(window.start.year, window.start.month, window.start.day);
    final lastDay = DateTime(window.end.year, window.end.month, window.end.day);
    while (!cursor.isAfter(lastDay)) {
      final key = _dayKeyFmt.format(cursor);
      final String short;
      final String long;
      switch (range) {
        case AnalyticsRange.thisWeek:
          short = DateFormat('EEE').format(cursor);
          long = DateFormat('d MMM').format(cursor);
        case AnalyticsRange.thisMonth:
          short = DateFormat('MMM d').format(cursor);
          long = DateFormat('MMM d').format(cursor);
        case AnalyticsRange.today:
          short = DateFormat('d MMM').format(cursor);
          long = 'Today';
        case AnalyticsRange.yesterday:
          short = DateFormat('d MMM').format(cursor);
          long = 'Yesterday';
        default:
          short = DateFormat('d MMM').format(cursor);
          long = DateFormat('d MMM').format(cursor);
      }
      buckets.add(AnalyticsBucket(key, short, long, incByBucket[key] ?? 0, expByBucket[key] ?? 0));
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  // Expense-by-category breakdown, sorted desc.
  final catTotals = <String, num>{};
  for (final e in rangeExpenses) {
    final key = e.category.trim().isEmpty ? 'Other' : e.category;
    catTotals[key] = (catTotals[key] ?? 0) + e.amount;
  }
  final categories = catTotals.entries
      .map((e) => CategorySlice(e.key, e.value))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  // Per-wallet (account) income/expense within the range.
  final byAccount = <String, ({num income, num expense})>{};
  void addAccount(String? acc, {num inc = 0, num exp = 0}) {
    final key = (acc == null || acc.trim().isEmpty) ? '' : acc.trim();
    final cur = byAccount[key] ?? (income: 0, expense: 0);
    byAccount[key] = (income: cur.income + inc, expense: cur.expense + exp);
  }

  for (final e in rangeExpenses) {
    addAccount(e.account, exp: e.amount);
  }
  for (final i in rangeIncomes) {
    addAccount(i.account, inc: i.amount);
  }

  return AnalyticsData(
    income: rangeIncomes.fold<num>(0, (s, t) => s + t.amount),
    expense: rangeExpenses.fold<num>(0, (s, t) => s + t.amount),
    buckets: buckets,
    categories: categories,
    byAccount: byAccount,
  );
});

// ── Screen ───────────────────────────────────────────────────────────────────

enum _Tab { overview, trends }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _Tab _tab = _Tab.overview;
  AnalyticsRange _range = AnalyticsRange.thisYear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final async = ref.watch(analyticsDataProvider(_range));
    final wallets = ref.watch(walletsListProvider).asData?.value ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 120),
      children: [
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Text('Analytics',
              style: AppText.screenTitle.copyWith(color: c.text)),
        ),
        const SizedBox(height: AppSpacing.lg),
        _SegmentedTabs(
          tab: _tab,
          onChanged: (t) => setState(() => _tab = t),
        ),
        const SizedBox(height: AppSpacing.md),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: AppSpacing.xl6),
            child: LoadingView(),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl5),
            child: EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load analytics',
              message: 'Pull to retry in a moment.',
            ),
          ),
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ChartCard(
                range: _range,
                data: data,
                money: money,
                onRangeSelected: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_tab == _Tab.overview)
                _OverviewSection(
                    range: _range,
                    data: data,
                    money: money,
                    wallets: wallets)
              else
                _TrendsSection(range: _range, data: data, money: money),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Segmented control (Overview / Trends) ────────────────────────────────────

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.tab, required this.onChanged});

  final _Tab tab;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget seg(String label, _Tab value) {
      final active = tab == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? c.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              label,
              style: AppText.bodySm.copyWith(
                color: active ? c.textInverse : c.textMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: c.border, width: 0.5)
            : null,
      ),
      child: Row(children: [
        seg('Overview', _Tab.overview),
        const SizedBox(width: 4),
        seg('Trends', _Tab.trends),
      ]),
    );
  }
}

// ── Chart card (range pill + legend + grouped bar chart) ─────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.range,
    required this.data,
    required this.money,
    required this.onRangeSelected,
  });

  final AnalyticsRange range;
  final AnalyticsData data;
  final String Function(num?) money;
  final ValueChanged<AnalyticsRange> onRangeSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RangePill(range: range, onSelected: onRangeSelected),
              Row(children: [
                _LegendDot(color: c.primary, label: 'Income'),
                const SizedBox(width: AppSpacing.md),
                _LegendDot(color: c.accentDark, label: 'Expense'),
              ]),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 200,
            child: data.hasData
                ? _GroupedBarChart(data: data, money: money)
                : _EmptyChart(range: range),
          ),
        ],
      ),
    );
  }
}

class _RangePill extends StatelessWidget {
  const _RangePill({required this.range, required this.onSelected});

  final AnalyticsRange range;
  final ValueChanged<AnalyticsRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return PopupMenuButton<AnalyticsRange>(
      initialValue: range,
      onSelected: onSelected,
      tooltip: 'Select range',
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: BorderSide(color: c.border),
      ),
      itemBuilder: (context) => [
        for (final r in AnalyticsRange.values)
          PopupMenuItem(
            value: r,
            child: Text(
              r.label,
              style: AppText.bodySm.copyWith(
                color: r == range ? c.primary : c.textBody,
                fontWeight: r == range ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: c.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(range.label,
              style: AppText.bodySm
                  .copyWith(color: c.text, fontWeight: FontWeight.w500)),
          const SizedBox(width: 2),
          Icon(Icons.keyboard_arrow_down, size: 16, color: c.text),
        ]),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: AppText.caption.copyWith(color: c.textSubtle)),
    ]);
  }
}

/// Grouped income/expense bars across the range's buckets, with tap tooltips.
class _GroupedBarChart extends StatelessWidget {
  const _GroupedBarChart({required this.data, required this.money});

  final AnalyticsData data;
  final String Function(num?) money;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final buckets = data.buckets;
    var maxVal = 0.0;
    for (final b in buckets) {
      maxVal = [maxVal, b.income.toDouble(), b.expense.toDouble()]
          .reduce((a, v) => a > v ? a : v);
    }
    final maxY = maxVal <= 0 ? 10.0 : maxVal * 1.25;

    // Bars get tight when there are many buckets (month/year); shrink width.
    final barWidth = buckets.length > 12 ? 5.0 : (buckets.length > 6 ? 7.0 : 11.0);

    String shortMoney(double v) {
      if (v >= 1000) return '${(v / 1000).round()}k';
      return v.round().toString();
    }

    final groups = <BarChartGroupData>[];
    for (var i = 0; i < buckets.length; i++) {
      final b = buckets[i];
      groups.add(BarChartGroupData(
        x: i,
        barsSpace: 2,
        barRods: [
          BarChartRodData(
            toY: b.income.toDouble(),
            color: c.primary,
            width: barWidth,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: b.expense.toDouble(),
            color: c.accentDark,
            width: barWidth,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ));
    }

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: c.divider, strokeWidth: 1, dashArray: [6, 6]),
        ),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(shortMoney(value),
                    style: AppText.caption.copyWith(color: c.textSubtle));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= buckets.length) {
                  return const SizedBox.shrink();
                }
                // Thin out labels when crowded to avoid overlap.
                final step = buckets.length > 14 ? 3 : (buckets.length > 7 ? 2 : 1);
                if (i % step != 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(buckets[i].label,
                      style: AppText.caption.copyWith(color: c.textSubtle)),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => c.text,
            tooltipBorderRadius: BorderRadius.circular(AppRadius.xs),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final b = buckets[group.x];
              final isIncome = rodIndex == 0;
              return BarTooltipItem(
                '${isIncome ? 'Income' : 'Expense'} - ${b.longLabel}\n',
                AppText.caption.copyWith(
                    color: c.textInverse, fontWeight: FontWeight.w500),
                children: [
                  TextSpan(
                    text: money(rod.toY),
                    style: AppText.bodySm.copyWith(
                        color: c.textInverse, fontWeight: FontWeight.w600),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.range});
  final AnalyticsRange range;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: c.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bar_chart_rounded, size: 26, color: c.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No analytics yet',
              style: AppText.bodyStrong.copyWith(color: c.text)),
          const SizedBox(height: AppSpacing.xs),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Add income or expenses for ${range.emptyLabel} to see your cash flow here.',
              textAlign: TextAlign.center,
              style: AppText.bodySm.copyWith(color: c.textSubtle),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overview: stat cards + category History ──────────────────────────────────

class _OverviewSection extends StatelessWidget {
  const _OverviewSection(
      {required this.range,
      required this.data,
      required this.money,
      required this.wallets});

  final AnalyticsRange range;
  final AnalyticsData data;
  final String Function(num?) money;
  final List<WalletModel> wallets;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final balance = data.balance;
    final balancePositive = balance >= 0;
    final topCategories = data.categories.take(4).toList();

    final walletById = {for (final w in wallets) w.id: w};
    final walletRows = data.byAccount.entries
        .where((e) => e.key.isNotEmpty && walletById.containsKey(e.key))
        .map((e) => (
              wallet: walletById[e.key]!,
              income: e.value.income,
              expense: e.value.expense,
            ))
        .where((r) => r.income > 0 || r.expense > 0)
        .toList()
      ..sort((a, b) => b.expense.compareTo(a.expense));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatRow(
          icon: 'trending-up',
          iconColor: c.accentDark,
          iconBg: c.accentSoft,
          label: 'Income',
          value: money(data.income),
        ),
        const SizedBox(height: AppSpacing.md),
        _StatRow(
          icon: 'trending-down',
          iconColor: c.negative,
          iconBg: c.negativeSoft,
          label: 'Expense',
          value: money(data.expense),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader('History'),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg,
                    AppSpacing.lg, AppSpacing.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(range.label,
                        style: AppText.bodyStrong.copyWith(color: c.text)),
                    Text(
                      '${balancePositive ? '+' : '-'}${money(balance.abs())}',
                      style: AppText.bodyStrong.copyWith(
                          color: balancePositive ? c.accentDark : c.negative),
                    ),
                  ],
                ),
              ),
              if (topCategories.isEmpty)
                _EmptyInline(
                  icon: Icons.inbox_outlined,
                  title: 'No history yet',
                  subtitle: 'Categories from ${range.emptyLabel} will appear here.',
                )
              else
                for (final slice in topCategories)
                  _CategoryRow(
                    slice: slice,
                    totalExpense: data.expense,
                    money: money,
                  ),
            ],
          ),
        ),
        if (walletRows.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('By wallet'),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < walletRows.length; i++)
                  _WalletSpendRow(
                    wallet: walletRows[i].wallet,
                    income: walletRows[i].income,
                    expense: walletRows[i].expense,
                    totalExpense: data.expense,
                    money: money,
                    first: i == 0,
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One wallet's income/expense within the range, with a spend-share bar.
class _WalletSpendRow extends StatelessWidget {
  const _WalletSpendRow({
    required this.wallet,
    required this.income,
    required this.expense,
    required this.totalExpense,
    required this.money,
    required this.first,
  });

  final WalletModel wallet;
  final num income;
  final num expense;
  final num totalExpense;
  final String Function(num?) money;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final share = totalExpense > 0
        ? (expense / totalExpense).clamp(0.0, 1.0).toDouble()
        : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          walletAvatar(wallet, size: 38),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMedium.copyWith(color: c.text)),
                const SizedBox(height: 6),
                AppProgressBar(value: share, color: c.accentDark, height: 6),
                const SizedBox(height: 4),
                Text('in ${money(income)} · out ${money(expense)}',
                    style: AppText.caption.copyWith(color: c.textSubtle)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
  });

  final String icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AppCard(
      child: Row(
        children: [
          _IconBadge(name: icon, color: iconColor, bg: iconBg, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label,
                style: AppText.bodyMedium.copyWith(color: c.text)),
          ),
          Text(value, style: AppText.subtitle.copyWith(color: c.text)),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.slice,
    required this.totalExpense,
    required this.money,
  });

  final CategorySlice slice;
  final num totalExpense;
  final String Function(num?) money;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final spec = resolveCategoryIcon(slice.category, colors: c);
    final share = totalExpense > 0 ? slice.amount / totalExpense : 0.0;
    final pct = (share * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          _IconBadge(
            name: spec.name,
            color: spec.color,
            bg: spec.color.withValues(alpha: 0.12),
            size: 38,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slice.category,
                    style: AppText.bodyMedium.copyWith(color: c.text)),
                const SizedBox(height: 6),
                AppProgressBar(
                  value: share.toDouble(),
                  color: spec.color,
                  height: 6,
                ),
                const SizedBox(height: 4),
                Text(totalExpense > 0 ? '$pct% of spend' : '',
                    style: AppText.caption.copyWith(color: c.textSubtle)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('-${money(slice.amount)}',
              style: AppText.bodyMedium.copyWith(color: c.text)),
        ],
      ),
    );
  }
}

// ── Trends: net-movement summary + per-period detail ─────────────────────────

class _TrendsSection extends StatelessWidget {
  const _TrendsSection(
      {required this.range, required this.data, required this.money});

  final AnalyticsRange range;
  final AnalyticsData data;
  final String Function(num?) money;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final buckets = data.buckets;
    final activeRows =
        buckets.where((b) => b.income > 0 || b.expense > 0).toList();

    var maxAmount = 1.0;
    for (final b in buckets) {
      maxAmount = [
        maxAmount,
        b.income.toDouble(),
        b.expense.toDouble(),
        b.net.abs().toDouble(),
      ].reduce((a, v) => a > v ? a : v);
    }

    AnalyticsBucket? strongestIncome;
    AnalyticsBucket? highestExpense;
    for (final b in buckets) {
      if (strongestIncome == null || b.income > strongestIncome.income) {
        strongestIncome = b;
      }
      if (highestExpense == null || b.expense > highestExpense.expense) {
        highestExpense = b;
      }
    }

    num netMovement = 0;
    if (activeRows.length >= 2) {
      netMovement = activeRows.last.net - activeRows.first.net;
    }
    final netPositive = netMovement >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!data.hasData)
          AppCard(
            child: Row(children: [
              _IconBadge(
                name: 'trending-up',
                color: c.primary,
                bg: c.primarySoft,
                size: 42,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No movement yet',
                        style: AppText.bodyStrong.copyWith(color: c.text)),
                    const SizedBox(height: 2),
                    Text(
                      'Trends for ${range.emptyLabel} will unlock after your first entry.',
                      style: AppText.bodySm.copyWith(color: c.textSubtle),
                    ),
                  ],
                ),
              ),
            ]),
          )
        else
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _IconBadge(
                    name: netPositive ? 'trending-up' : 'trending-down',
                    color: netPositive ? c.accentDark : c.negative,
                    bg: netPositive ? c.accentSoft : c.negativeSoft,
                    size: 42,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Net movement',
                            style:
                                AppText.caption.copyWith(color: c.textSubtle)),
                        const SizedBox(height: 2),
                        Text(
                          '${netPositive ? '+' : '-'}${money(netMovement.abs())}',
                          style: AppText.title.copyWith(
                              color: netPositive ? c.accentDark : c.negative),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.md),
                _MetricRow(
                  label: 'Strongest income',
                  value:
                      '${strongestIncome?.longLabel ?? range.label} · ${money(strongestIncome?.income ?? 0)}',
                ),
                _MetricRow(
                  label: 'Highest expense',
                  value:
                      '${highestExpense?.longLabel ?? range.label} · ${money(highestExpense?.expense ?? 0)}',
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader('Trend Detail'),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: EdgeInsets.zero,
          child: activeRows.isEmpty
              ? _EmptyInline(
                  icon: Icons.show_chart,
                  title: 'No trend data',
                  subtitle:
                      'There are no income or expense entries for ${range.emptyLabel}.',
                )
              : Column(
                  children: [
                    for (var i = 0; i < activeRows.length; i++)
                      _TrendRow(
                        bucket: activeRows[i],
                        max: maxAmount,
                        money: money,
                        first: i == 0,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(label,
                style: AppText.caption.copyWith(color: c.textSubtle)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppText.bodySm
                  .copyWith(color: c.text, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({
    required this.bucket,
    required this.max,
    required this.money,
    required this.first,
  });

  final AnalyticsBucket bucket;
  final double max;
  final String Function(num?) money;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final netPositive = bucket.net >= 0;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: first ? null : Border(top: BorderSide(color: c.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(bucket.longLabel,
                  style: AppText.bodyMedium.copyWith(color: c.text)),
              Text(
                '${netPositive ? '+' : '-'}${money(bucket.net.abs())}',
                style: AppText.bodyMedium.copyWith(
                    color: netPositive ? c.accentDark : c.negative),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _TrendBar(
              label: 'Income',
              value: bucket.income,
              max: max,
              color: c.primary,
              money: money),
          const SizedBox(height: AppSpacing.sm),
          _TrendBar(
              label: 'Expense',
              value: bucket.expense,
              max: max,
              color: c.accentDark,
              money: money),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    required this.money,
  });

  final String label;
  final num value;
  final double max;
  final Color color;
  final String Function(num?) money;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ratio = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0).toDouble();
    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(label,
              style: AppText.caption.copyWith(color: c.textSubtle)),
        ),
        Expanded(
          child: AppProgressBar(value: ratio, color: color, height: 8),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 72,
          child: Text(money(value),
              textAlign: TextAlign.right,
              style: AppText.caption.copyWith(color: c.textSubtle)),
        ),
      ],
    );
  }
}

// ── Shared little widgets ────────────────────────────────────────────────────

/// Circular tinted badge wrapping a [WealthifyIcon] (RN's `IconBadge`).
class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.name,
    required this.color,
    required this.bg,
    required this.size,
  });

  final String name;
  final Color color;
  final Color bg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: WealthifyIcon(name, size: size * 0.55, color: color),
    );
  }
}

class _EmptyInline extends StatelessWidget {
  const _EmptyInline({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 24, color: c.textSubtle),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.bodyStrong.copyWith(color: c.text)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppText.bodySm.copyWith(color: c.textSubtle)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
