import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/transaction_row.dart';
import '../../data/models/stats_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transactions_repository.dart';
import '../preferences/preferences_controller.dart';

/// Stats provider consumed by the Analytics tab (income/expense totals for its
/// bar chart). Kept independent of the filterable list below so analytics is
/// untouched by the Transactions filters.
final transactionsListProvider =
    FutureProvider.autoDispose<StatsModel>((ref) async {
  return ref.read(transactionsRepositoryProvider).getStats();
});

// ───────────────────────── Filter / range state ─────────────────────────

enum RangeKey { today, yesterday, last3Days, thisWeek, thisMonth, thisYear }

enum TypeFilter { all, expense, income }

const _rangeLabels = {
  RangeKey.today: 'Today',
  RangeKey.yesterday: 'Yesterday',
  RangeKey.last3Days: 'Last 3 days',
  RangeKey.thisWeek: 'This week',
  RangeKey.thisMonth: 'This month',
  RangeKey.thisYear: 'This year',
};

const _typeLabels = {
  TypeFilter.all: 'All',
  TypeFilter.expense: 'Expense',
  TypeFilter.income: 'Income',
};

/// Immutable filter state driving the data fetch.
class TxnFilters {
  const TxnFilters({
    this.range = RangeKey.thisMonth,
    this.keyword = '',
    this.typeFilter = TypeFilter.all,
    this.category = '',
    this.minAmount = '',
    this.maxAmount = '',
    this.startDate = '',
    this.endDate = '',
  });

  final RangeKey range;
  final String keyword;
  final TypeFilter typeFilter;
  final String category;
  final String minAmount;
  final String maxAmount;
  final String startDate; // YYYY-MM-DD, overrides range when set
  final String endDate;

  bool get hasActiveFilters =>
      typeFilter != TypeFilter.all ||
      category.trim().isNotEmpty ||
      minAmount.trim().isNotEmpty ||
      maxAmount.trim().isNotEmpty ||
      startDate.isNotEmpty ||
      endDate.isNotEmpty ||
      keyword.trim().isNotEmpty;

  TxnFilters copyWith({
    RangeKey? range,
    String? keyword,
    TypeFilter? typeFilter,
    String? category,
    String? minAmount,
    String? maxAmount,
    String? startDate,
    String? endDate,
  }) =>
      TxnFilters(
        range: range ?? this.range,
        keyword: keyword ?? this.keyword,
        typeFilter: typeFilter ?? this.typeFilter,
        category: category ?? this.category,
        minAmount: minAmount ?? this.minAmount,
        maxAmount: maxAmount ?? this.maxAmount,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
      );

  /// Equality drives provider de-duping / refetch.
  @override
  bool operator ==(Object other) =>
      other is TxnFilters &&
      other.range == range &&
      other.keyword == keyword &&
      other.typeFilter == typeFilter &&
      other.category == category &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(range, keyword, typeFilter, category,
      minAmount, maxAmount, startDate, endDate);
}

/// Holds the active filter state for the Transactions tab.
class TxnFiltersController extends Notifier<TxnFilters> {
  @override
  TxnFilters build() => const TxnFilters();

  void setRange(RangeKey range) => state = state.copyWith(range: range);
  void setKeyword(String keyword) => state = state.copyWith(keyword: keyword);
  void apply(TxnFilters next) => state = next;

  void clear() => state = TxnFilters(range: state.range);
}

final txnFiltersProvider =
    NotifierProvider<TxnFiltersController, TxnFilters>(TxnFiltersController.new);

/// Result of a transactions fetch: merged list + income/expense totals.
typedef TxnFeed = ({
  List<TransactionModel> items,
  num income,
  num expense,
});

({String start, String end}) _dateRangeFor(RangeKey key) {
  final fmt = DateFormat('yyyy-MM-dd');
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  DateTime start;
  DateTime end;

  switch (key) {
    case RangeKey.today:
      start = today;
      end = today;
    case RangeKey.yesterday:
      start = today.subtract(const Duration(days: 1));
      end = start;
    case RangeKey.last3Days:
      start = today.subtract(const Duration(days: 2));
      end = today;
    case RangeKey.thisWeek:
      // ISO week: Monday → Sunday.
      start = today.subtract(Duration(days: today.weekday - 1));
      end = start.add(const Duration(days: 6));
    case RangeKey.thisMonth:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0);
    case RangeKey.thisYear:
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year, 12, 31);
  }
  return (start: fmt.format(start), end: fmt.format(end));
}

DateTime _sortDate(TransactionModel t) =>
    DateTime.tryParse(t.date) ?? DateTime.fromMillisecondsSinceEpoch(0);

/// Fetches incomes and/or expenses for the active filters, merges and sorts
/// them (date desc), and returns the income/expense totals.
final txnFeedProvider = FutureProvider.autoDispose<TxnFeed>((ref) async {
  final f = ref.watch(txnFiltersProvider);
  final repo = ref.read(transactionsRepositoryProvider);

  // Explicit date filters override the quick range selector.
  final range = _dateRangeFor(f.range);
  final startDate = f.startDate.isNotEmpty ? f.startDate : range.start;
  final endDate = f.endDate.isNotEmpty ? f.endDate : range.end;

  final query = <String, dynamic>{
    'start_date': startDate,
    'end_date': endDate,
  };
  if (f.keyword.trim().isNotEmpty) query['keyword'] = f.keyword.trim();
  if (f.category.trim().isNotEmpty) query['category'] = f.category.trim();
  if (f.minAmount.trim().isNotEmpty) query['min_amount'] = f.minAmount.trim();
  if (f.maxAmount.trim().isNotEmpty) query['max_amount'] = f.maxAmount.trim();

  final wantIncomes = f.typeFilter != TypeFilter.expense;
  final wantExpenses = f.typeFilter != TypeFilter.income;

  // NOTE: don't pass `type: 'expense'` to getExpenses — the Expense model's
  // `type` field defaults to 'self', so that filter would exclude normal
  // expenses. wantExpenses controls whether we call the endpoint at all.
  final incomesF = wantIncomes
      ? repo.getIncomes(Map<String, dynamic>.from(query))
      : Future.value(<TransactionModel>[]);
  final expensesF = wantExpenses
      ? repo.getExpenses(Map<String, dynamic>.from(query))
      : Future.value((items: <TransactionModel>[], total: 0 as num));

  final results = await Future.wait([incomesF, expensesF]);
  final incomes = results[0] as List<TransactionModel>;
  final expenseResult = results[1] as ExpenseResult;
  final expenses = expenseResult.items;

  num sum(Iterable<TransactionModel> list) =>
      list.fold<num>(0, (a, b) => a + b.amount);

  final merged = [...incomes, ...expenses]
    ..sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));

  return (
    items: merged.take(30).toList(),
    income: sum(incomes),
    expense: sum(expenses),
  );
});

// ───────────────────────────── Screen ─────────────────────────────

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final _searchController = TextEditingController();
  bool _rangeMenuOpen = false;
  String? _selectedCashflow; // 'income' | 'expense'

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(txnFiltersProvider).keyword;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() =>
      ref.read(txnFiltersProvider.notifier).setKeyword(_searchController.text);

  void _clearSearch() {
    _searchController.clear();
    ref.read(txnFiltersProvider.notifier).setKeyword('');
  }

  Future<void> _openFilters() async {
    setState(() => _rangeMenuOpen = false);
    final current = ref.read(txnFiltersProvider);
    final result = await showModalBottomSheet<TxnFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltersSheet(initial: current),
    );
    if (result == null || !mounted) return;
    if (result.keyword != current.keyword) {
      _searchController.text = result.keyword;
    }
    ref.read(txnFiltersProvider.notifier).apply(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final filters = ref.watch(txnFiltersProvider);
    final feedAsync = ref.watch(txnFeedProvider);

    final rangeLabel = _rangeLabels[filters.range]!;
    final sectionTitle =
        'All transactions from ${rangeLabel.toLowerCase()}';
    final emptyRangeLabel = filters.range == RangeKey.last3Days
        ? 'the last 3 days'
        : rangeLabel.toLowerCase();

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_rangeMenuOpen || _selectedCashflow != null) {
          setState(() {
            _rangeMenuOpen = false;
            _selectedCashflow = null;
          });
        }
        FocusScope.of(context).unfocus();
      },
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(txnFeedProvider.future),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 120),
          children: [
            const SizedBox(height: AppSpacing.sm),
            Center(
                child: Text('Transactions',
                    style: AppText.screenTitle.copyWith(color: c.text))),
            const SizedBox(height: AppSpacing.lg),
            _SearchRow(
              controller: _searchController,
              hasActiveFilters: filters.hasActiveFilters,
              onSubmit: _submitSearch,
              onClear: _clearSearch,
              onChanged: (_) => setState(() {}), // refresh clear-button visibility
              onFilterTap: _openFilters,
            ),
            const SizedBox(height: AppSpacing.lg),
            feedAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xl5),
                child: LoadingView(),
              ),
              error: (e, _) => const Padding(
                padding: EdgeInsets.only(top: AppSpacing.xl2),
                child: EmptyState(
                    icon: Icons.error_outline,
                    title: 'Could not load transactions',
                    message: 'Pull to refresh and try again.'),
              ),
              data: (feed) {
                final hasCashflow = feed.income > 0 || feed.expense > 0;
                final selectedItem = _selectedCashflow == null
                    ? null
                    : _selectedCashflow == 'income'
                        ? (label: 'Income', value: feed.income)
                        : (label: 'Expense', value: feed.expense);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _RangeSelector(
                              label: rangeLabel,
                              open: _rangeMenuOpen,
                              selected: filters.range,
                              onToggle: () => setState(
                                  () => _rangeMenuOpen = !_rangeMenuOpen),
                              onSelect: (k) {
                                setState(() => _rangeMenuOpen = false);
                                ref
                                    .read(txnFiltersProvider.notifier)
                                    .setRange(k);
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (hasCashflow)
                            _CashflowMeter(
                              income: feed.income,
                              expense: feed.expense,
                              money: money,
                              selectedKey: _selectedCashflow,
                              onSelect: (key) {
                                setState(() {
                                  _rangeMenuOpen = false;
                                  _selectedCashflow =
                                      _selectedCashflow == key ? null : key;
                                });
                              },
                            )
                          else
                            _EmptyCashflow(
                                rangeLabel: emptyRangeLabel, money: money),
                          if (selectedItem != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _CashflowTooltip(
                                label: selectedItem.label,
                                value: money(selectedItem.value)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SectionHeader(sectionTitle),
                    const SizedBox(height: AppSpacing.md),
                    if (feed.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.lg),
                        child: EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'No transactions yet',
                            message:
                                'New entries for this period will show here.'),
                      )
                    else
                      ...feed.items.map((t) => TransactionRow(
                            txn: t,
                            money: money,
                            onTap: () => context.push(
                                Routes.transactionDetail,
                                extra: t),
                          )),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── Search row ─────────────────────────────

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.hasActiveFilters,
    required this.onSubmit,
    required this.onClear,
    required this.onChanged,
    required this.onFilterTap,
  });

  final TextEditingController controller;
  final bool hasActiveFilters;
  final VoidCallback onSubmit;
  final VoidCallback onClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: c.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: c.textSubtle),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    onSubmitted: (_) => onSubmit(),
                    textInputAction: TextInputAction.search,
                    style: AppText.bodySm.copyWith(color: c.text),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: 'Search transactions',
                      hintStyle:
                          AppText.bodySm.copyWith(color: c.textSubtle),
                    ),
                  ),
                ),
                if (controller.text.isNotEmpty)
                  GestureDetector(
                    onTap: onClear,
                    child: Icon(Icons.cancel,
                        size: 18, color: c.textSubtle),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleIconButton(
                icon: Icons.tune, iconSize: 20, onTap: onFilterTap),
            if (hasActiveFilters)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.background, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────────── Range selector ─────────────────────────────

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({
    required this.label,
    required this.open,
    required this.selected,
    required this.onToggle,
    required this.onSelect,
  });

  final String label;
  final bool open;
  final RangeKey selected;
  final VoidCallback onToggle;
  final ValueChanged<RangeKey> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: 6),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: c.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: AppText.bodySm
                        .copyWith(color: c.text, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                Icon(open ? Icons.expand_less : Icons.expand_more,
                    size: 16, color: c.text),
              ],
            ),
          ),
        ),
        if (open)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            width: 164,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: c.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final entry in _rangeLabels.entries)
                  GestureDetector(
                    onTap: () => onSelect(entry.key),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      color: entry.key == selected
                          ? c.primarySoft
                          : Colors.transparent,
                      child: Text(
                        entry.value,
                        style: AppText.bodySm.copyWith(
                          color: entry.key == selected
                              ? c.primary
                              : c.textBody,
                          fontWeight: entry.key == selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ───────────────────────────── Cashflow meter ─────────────────────────────

class _CashflowMeter extends StatelessWidget {
  const _CashflowMeter({
    required this.income,
    required this.expense,
    required this.money,
    required this.selectedKey,
    required this.onSelect,
  });

  final num income;
  final num expense;
  final String Function(num?) money;
  final String? selectedKey;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final balance = income - expense;
    final balanceNegative = balance < 0;
    final safeBalance = balance < 0 ? 0 : balance;
    final savedPercent =
        income > 0 ? ((safeBalance / income) * 100).round() : 0;
    final spentPercent = income > 0
        ? math.min(((expense / income) * 100).round(), 999)
        : 0;
    final signalColor = balanceNegative ? c.negative : c.accentDark;
    final signalBg = balanceNegative ? c.negativeSoft : c.accentSoft;
    final signalLabel = balanceNegative ? 'Over by' : 'Saved';
    final signalValue =
        balanceNegative ? money(balance.abs()) : '$savedPercent%';

    return Column(
      children: [
        SizedBox(
          width: _kArcSize,
          height: _kArcSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size.square(_kArcSize),
                painter: _CashflowArcPainter(
                  income: income.toDouble(),
                  expense: expense.toDouble(),
                  selectedKey: selectedKey,
                  incomeStart: c.primaryGradientStart,
                  incomeEnd: c.primaryDarker,
                  incomeTrack: c.primarySoft,
                  expenseStart: c.accent,
                  expenseEnd: c.accentDark,
                  expenseTrack: c.accentSoft,
                ),
              ),
              // Tap targets over the two arcs.
              Positioned.fill(
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => onSelect('income'),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => onSelect('expense'),
                      ),
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                child: Container(
                  width: 128,
                  constraints: const BoxConstraints(minHeight: 92),
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(64),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Balance',
                          style: AppText.caption.copyWith(
                              color: c.textSubtle,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${balanceNegative ? '-' : ''}${money(balance.abs())}',
                          maxLines: 1,
                          style: AppText.title.copyWith(
                              color:
                                  balanceNegative ? c.negative : c.text),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: signalBg,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text('$signalLabel $signalValue',
                            style: AppText.caption.copyWith(
                                color: signalColor,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _CashflowMetric(
                icon: Icons.south,
                label: 'Income',
                value: money(income),
                color: c.primary,
                active: selectedKey == 'income',
                onTap: () => onSelect('income'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _CashflowMetric(
                icon: Icons.north,
                label: 'Expense',
                value: money(expense),
                color: c.accentDark,
                active: selectedKey == 'expense',
                caption: '$spentPercent% spent',
                onTap: () => onSelect('expense'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CashflowMetric extends StatelessWidget {
  const _CashflowMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.active,
    required this.onTap,
    this.caption,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: active ? c.primarySoft : c.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
              color: active ? c.primarySoftStrong : c.border),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: AppText.caption.copyWith(
                          color: c.textSubtle,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        maxLines: 1,
                        style:
                            AppText.bodyStrong.copyWith(color: c.text)),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 1),
                    Text(caption!,
                        style:
                            AppText.caption.copyWith(color: c.textSubtle)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashflowTooltip extends StatelessWidget {
  const _CashflowTooltip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Container(
        constraints: const BoxConstraints(minWidth: 132),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: c.text,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: AppText.caption.copyWith(
                    color: c.surface, fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(value,
                style: AppText.bodySm.copyWith(
                    color: c.surface, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

const double _kArcSize = 214;
const double _kMeterSweep = 0.76; // fraction of the full circle the gauge spans
const double _kMeterRotation = 132; // degrees

class _CashflowArcPainter extends CustomPainter {
  _CashflowArcPainter({
    required this.income,
    required this.expense,
    required this.selectedKey,
    required this.incomeStart,
    required this.incomeEnd,
    required this.incomeTrack,
    required this.expenseStart,
    required this.expenseEnd,
    required this.expenseTrack,
  });

  final double income;
  final double expense;
  final String? selectedKey;
  final Color incomeStart;
  final Color incomeEnd;
  final Color incomeTrack;
  final Color expenseStart;
  final Color expenseEnd;
  final Color expenseTrack;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxValue = math.max(math.max(income, expense), 1);
    final sweepTotal = _kMeterSweep * 2 * math.pi;
    final startAngle = _kMeterRotation * math.pi / 180;

    void drawArc(
      double radius,
      double stroke,
      double progress,
      Color trackColor,
      Color gradStart,
      Color gradEnd,
      double opacity,
    ) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = trackColor;
      canvas.drawArc(rect, startAngle, sweepTotal, false, track);

      final clamped = progress.clamp(0.0, 1.0);
      if (clamped <= 0) return;
      final fill = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepTotal,
          colors: [gradStart, gradEnd],
          transform: GradientRotation(startAngle),
        ).createShader(rect);
      if (opacity < 1) {
        fill.color = fill.color.withValues(alpha: opacity);
      }
      canvas.drawArc(rect, startAngle, sweepTotal * clamped, false, fill);
    }

    drawArc(88, 18, income / maxValue, incomeTrack, incomeStart, incomeEnd,
        selectedKey == 'expense' ? 0.48 : 1);
    drawArc(66, 16, expense / maxValue, expenseTrack, expenseStart,
        expenseEnd, selectedKey == 'income' ? 0.48 : 1);
  }

  @override
  bool shouldRepaint(_CashflowArcPainter old) =>
      old.income != income ||
      old.expense != expense ||
      old.selectedKey != selectedKey;
}

class _EmptyCashflow extends StatelessWidget {
  const _EmptyCashflow({required this.rangeLabel, required this.money});

  final String rangeLabel;
  final String Function(num?) money;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surface,
              border: Border.all(color: c.primarySoft, width: 12),
            ),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primarySoft,
              ),
              child: Icon(Icons.pie_chart_outline,
                  size: 26, color: c.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Nothing to chart yet',
              textAlign: TextAlign.center,
              style: AppText.bodyStrong.copyWith(color: c.text)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add income or expenses for $rangeLabel and your balance breakdown will appear here.',
            textAlign: TextAlign.center,
            style: AppText.bodySm.copyWith(color: c.textSubtle),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _EmptyMetricPill(
                  color: c.primary, label: 'Income ${money(0)}'),
              _EmptyMetricPill(
                  color: c.accentDark, label: 'Expense ${money(0)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyMetricPill extends StatelessWidget {
  const _EmptyMetricPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: 7),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppText.caption.copyWith(color: c.textBody)),
        ],
      ),
    );
  }
}

// ───────────────────────────── Filters sheet ─────────────────────────────

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet({required this.initial});

  final TxnFilters initial;

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late TxnFilters _draft;
  late final TextEditingController _category;
  late final TextEditingController _min;
  late final TextEditingController _max;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _category = TextEditingController(text: _draft.category);
    _min = TextEditingController(text: _draft.minAmount);
    _max = TextEditingController(text: _draft.maxAmount);
  }

  @override
  void dispose() {
    _category.dispose();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final fmt = DateFormat('yyyy-MM-dd');
    final raw = isStart ? _draft.startDate : _draft.endDate;
    final initial = DateTime.tryParse(raw) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      final formatted = fmt.format(picked);
      _draft = isStart
          ? _draft.copyWith(startDate: formatted)
          : _draft.copyWith(endDate: formatted);
    });
  }

  void _apply() {
    Navigator.of(context).pop(_draft.copyWith(
      category: _category.text.trim(),
      minAmount: _min.text.trim(),
      maxAmount: _max.text.trim(),
    ));
  }

  void _clear() {
    // Reset everything but keep the active quick range.
    Navigator.of(context).pop(TxnFilters(range: widget.initial.range));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final insets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88),
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: c.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filters',
                      style: AppText.subtitle.copyWith(color: c.text)),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, size: 22, color: c.textSubtle),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Type segment
              Text('Type',
                  style: AppText.label.copyWith(color: c.textSubtle)),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    for (final t in TypeFilter.values)
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _draft = _draft.copyWith(typeFilter: t)),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _draft.typeFilter == t
                                  ? c.primary
                                  : Colors.transparent,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              _typeLabels[t]!,
                              style: AppText.bodySm.copyWith(
                                color: _draft.typeFilter == t
                                    ? c.textInverse
                                    : c.textSubtle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Category
              _SheetField(
                label: 'Category',
                controller: _category,
                hint: 'e.g. Groceries',
                icon: Icons.sell_outlined,
                capitalize: true,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Amount
              Text('Amount',
                  style: AppText.label.copyWith(color: c.textSubtle)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _SheetField(
                      controller: _min,
                      hint: 'Min',
                      numeric: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _SheetField(
                      controller: _max,
                      hint: 'Max',
                      numeric: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Date range
              Text('Date range',
                  style: AppText.label.copyWith(color: c.textSubtle)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      value: _draft.startDate,
                      placeholder: 'Start date',
                      onTap: () => _pickDate(isStart: true),
                      onClear: _draft.startDate.isEmpty
                          ? null
                          : () => setState(() =>
                              _draft = _draft.copyWith(startDate: '')),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _DateField(
                      value: _draft.endDate,
                      placeholder: 'End date',
                      onTap: () => _pickDate(isStart: false),
                      onClear: _draft.endDate.isEmpty
                          ? null
                          : () => setState(
                              () => _draft = _draft.copyWith(endDate: '')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      label: 'Clear',
                      variant: PillVariant.secondary,
                      onPressed: _clear,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PillButton(label: 'Apply', onPressed: _apply),
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

/// Lightweight text field used inside the filters sheet (mirrors RN TextField).
class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.numeric = false,
    this.capitalize = false,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final bool numeric;
  final bool capitalize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.label.copyWith(color: c.textSubtle)),
          const SizedBox(height: AppSpacing.xs),
        ],
        Container(
          decoration: BoxDecoration(
            color: c.inputBackground,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: c.inputBorder),
          ),
          child: TextField(
            controller: controller,
            keyboardType: numeric
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            textCapitalization: capitalize
                ? TextCapitalization.words
                : TextCapitalization.none,
            inputFormatters: numeric
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                : null,
            style: AppText.body.copyWith(color: c.text),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: AppText.body.copyWith(color: c.textPlaceholder),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 14),
              prefixIcon: icon != null
                  ? Icon(icon, size: 18, color: c.textSubtle)
                  : null,
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 0),
            ),
          ),
        ),
      ],
    );
  }
}

/// Read-only date display + picker trigger for the filters sheet.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.onClear,
  });

  final String value;
  final String placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final hasValue = value.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        decoration: BoxDecoration(
          color: c.inputBackground,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: c.inputBorder),
        ),
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: 18, color: c.textSubtle),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                hasValue ? value : placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(
                    color: hasValue ? c.text : c.textPlaceholder),
              ),
            ),
            if (hasValue && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 16, color: c.textSubtle),
              ),
          ],
        ),
      ),
    );
  }
}
