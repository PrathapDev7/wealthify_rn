import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/stats_model.dart';
import '../../data/repositories/budgets_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../auth/auth_screen.dart';
import '../preferences/preferences_controller.dart';

/// Quick-set preset limits, mirroring RN `PRESET_AMOUNTS`.
const _presets = [5000, 10000, 25000, 50000];

class SetBudgetScreen extends ConsumerStatefulWidget {
  const SetBudgetScreen({super.key, this.category});

  final String? category;

  @override
  ConsumerState<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends ConsumerState<SetBudgetScreen> {
  String _amount = ''; // raw digits (no decimal — RN budgets are whole numbers)

  BudgetModel _current = const BudgetModel();
  num _totalIncome = 0;
  num _totalExpenses = 0;
  num _totalBalance = 0;
  bool _loading = true;
  bool _saving = false;

  String get _budgetKey => widget.category ?? 'Overall';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final budgetsRepo = ref.read(budgetsRepositoryProvider);
      final txnRepo = ref.read(transactionsRepositoryProvider);
      final results =
          await Future.wait([budgetsRepo.getBudgets(), txnRepo.getStats()]);
      if (!mounted) return;
      final budget = results[0] as BudgetModel;
      final stats = results[1] as StatsModel;
      final existing = budget.budgets[_budgetKey];
      setState(() {
        _current = budget;
        _totalIncome = stats.totalIncomes;
        _totalExpenses = stats.totalExpenses;
        _totalBalance = stats.balance;
        _amount = (existing != null && existing > 0) ? existing.toString() : '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Saved budgets (value > 0), current key first, then Overall, then A–Z;
  /// capped at 4 — mirrors RN `existingBudgetEntries`.
  List<MapEntry<String, num>> get _savedEntries {
    final entries = _current.budgets.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) {
        if (a.key == _budgetKey) return -1;
        if (b.key == _budgetKey) return 1;
        if (a.key == 'Overall') return -1;
        if (b.key == 'Overall') return 1;
        return a.key.compareTo(b.key);
      });
    return entries.take(4).toList();
  }

  bool get _hasSavedForKey =>
      (_current.budgets[_budgetKey] ?? 0) > 0;

  void _onDigit(String digit) {
    if (digit == '.') return; // budgets are whole numbers
    setState(() {
      var next = '$_amount$digit'.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      if (next.length > 9) return;
      _amount = next;
    });
  }

  void _onBackspace() {
    if (_amount.isEmpty) return;
    setState(() => _amount = _amount.substring(0, _amount.length - 1));
  }

  Future<void> _pickCategory() async {
    final picked = await context
        .push<String>('${Routes.selectCategory}?type=expense');
    if (picked == null || !mounted) return;
    if (picked == _budgetKey) return;
    // Re-open this screen scoped to the chosen category, preserving stack depth.
    context.replace(picked == 'Overall'
        ? Routes.setBudget
        : '${Routes.setBudget}?category=${Uri.encodeComponent(picked)}');
  }

  void _selectExisting(String name, num value) {
    if (name == _budgetKey) {
      setState(() => _amount = value.toString());
      return;
    }
    context.replace(name == 'Overall'
        ? Routes.setBudget
        : '${Routes.setBudget}?category=${Uri.encodeComponent(name)}');
  }

  Future<void> _save() async {
    final parsed = num.tryParse(_amount.trim());
    if (parsed == null || parsed <= 0) {
      showAppSnack(context, 'Enter an amount', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final merged = {..._current.budgets, _budgetKey: parsed};
      await ref.read(budgetsRepositoryProvider).save(_current, merged);
      if (!mounted) return;
      setState(() => _current = BudgetModel(id: _current.id, budgets: merged));
      showAppSnack(context, 'Budget saved');
      if (context.mounted) context.pop();
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final money = ref.read(preferencesProvider.notifier).money;
    final symbol = ref.read(preferencesProvider).currencySymbol;
    final saved = _savedEntries;

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Set Budget'),
          Expanded(
            child: _loading
                ? const LoadingView()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
                    children: [
                      // Balance / scope summary card.
                      AppCard(
                        child: Row(
                          children: [
                            WealthifyIcon('total_balance', size: 44),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.category != null
                                        ? '${widget.category} budget'
                                        : 'Overall budget',
                                    style: AppText.label
                                        .copyWith(color: c.textSubtle),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(money(_totalBalance),
                                      style: AppText.subtitle
                                          .copyWith(color: c.text)),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Spent',
                                    style: AppText.caption
                                        .copyWith(color: c.textSubtle)),
                                const SizedBox(height: 2),
                                Text(money(_totalExpenses),
                                    style: AppText.moneySm
                                        .copyWith(color: c.text)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Amount entry card: scope picker + big amount + presets.
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Budget For',
                                    style: AppText.label
                                        .copyWith(color: c.textSubtle)),
                                GestureDetector(
                                  onTap: _pickCategory,
                                  child: Container(
                                    constraints:
                                        const BoxConstraints(maxWidth: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: c.primarySoft,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.pill),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _budgetKey,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppText.bodyStrong.copyWith(
                                                color: c.primary, fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(Icons.keyboard_arrow_down,
                                            size: 16, color: c.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(symbol,
                                    style: AppText.title
                                        .copyWith(color: c.textSubtle)),
                                const SizedBox(width: 4),
                                Text(
                                  _formatGrouped(_amount),
                                  style: AppText.displayLg
                                      .copyWith(color: c.text, fontSize: 42),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Enter Amount',
                                style: AppText.bodySm
                                    .copyWith(color: c.textSubtle)),
                            const SizedBox(height: AppSpacing.xl),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Quick Set',
                                  style: AppText.label
                                      .copyWith(color: c.textSubtle)),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                for (final preset in _presets)
                                  _PresetChip(
                                    label: '$symbol${_group(preset)}',
                                    active: num.tryParse(_amount) == preset,
                                    onTap: () => setState(
                                        () => _amount = preset.toString()),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Income / Balance tiles.
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              label: 'Income',
                              value: money(_totalIncome),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _StatTile(
                              label: 'Balance',
                              value: money(_totalBalance),
                              negative: _totalBalance < 0,
                            ),
                          ),
                        ],
                      ),

                      // Saved budgets (tap to switch scope).
                      if (saved.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Saved Budgets',
                                      style: AppText.subtitle
                                          .copyWith(color: c.text)),
                                  Text('${saved.length}',
                                      style: AppText.caption
                                          .copyWith(color: c.primary)),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ...saved.map((e) {
                                final active = e.key == _budgetKey;
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: GestureDetector(
                                    onTap: () => _selectExisting(e.key, e.value),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.md,
                                          vertical: AppSpacing.md),
                                      decoration: BoxDecoration(
                                        color: active
                                            ? c.primarySoft
                                            : c.surfaceSoft,
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.sm),
                                        border: Border.all(
                                            color: active
                                                ? c.primarySoftStrong
                                                : c.border),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              e.key,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppText.bodyMedium.copyWith(
                                                  color: active
                                                      ? c.primary
                                                      : c.textBody),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.md),
                                          Text(
                                            money(e.value),
                                            style: AppText.moneySm.copyWith(
                                                color: active
                                                    ? c.primary
                                                    : c.text),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      PillButton(
                        label:
                            '${_hasSavedForKey ? 'Update' : 'Save'} $_budgetKey Budget',
                        loading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ],
                  ),
          ),
          NumericKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
        ],
      ),
    );
  }

  /// Groups a raw integer-amount string with thousand separators (or '0').
  String _formatGrouped(String raw) {
    if (raw.isEmpty) return '0';
    return raw.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  }

  String _group(int value) => value.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

class _PresetChip extends StatelessWidget {
  const _PresetChip(
      {required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 78),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: active ? c.primary : c.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: active ? c.primary : c.border),
        ),
        child: Text(
          label,
          style: AppText.bodyStrong.copyWith(
              fontSize: 12, color: active ? c.textInverse : c.text),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(
      {required this.label, required this.value, this.negative = false});

  final String label;
  final String value;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceLifted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: c.divider),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption.copyWith(color: c.textSubtle)),
          const SizedBox(height: 4),
          Text(value,
              style: AppText.moneySm
                  .copyWith(color: negative ? c.negative : c.text)),
        ],
      ),
    );
  }
}
