import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/category_icon.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import '../../core/widgets/numeric_keypad.dart';
import '../../core/widgets/wealthify_icon.dart';
import '../../data/models/wallet_model.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/transactions_repository.dart';
import '../../data/repositories/wallets_repository.dart';
import '../auth/auth_screen.dart';
import '../preferences/preferences_controller.dart';

/// Groups the integer part of a raw amount string with thousand separators,
/// preserving a trailing/in-progress decimal. Ported from
/// `legacy_rn/src/utils/amount.ts` `formatAmountInput`.
String _formatAmountInput(String raw) {
  if (raw.isEmpty) return '';
  final parts = raw.split('.');
  final intPart = parts.first;
  final withCommas = intPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  if (raw.contains('.')) {
    final dec = parts.length > 1 ? parts[1] : '';
    return dec.isNotEmpty ? '$withCommas.$dec' : '$withCommas.';
  }
  return withCommas;
}

/// Add Expense / Add Income form. Mirrors `legacy_rn/app/add-transaction.tsx`.
class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key, required this.type});

  /// 'expense' | 'income'
  final String type;

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  bool get income => widget.type == 'income';

  final _description = TextEditingController();
  final _title = TextEditingController();

  String _amount = ''; // raw digits + optional single '.'
  String? _category;
  String? _subCategory;
  List<String> _subCategories = const [];
  String? _account; // selected wallet id
  List<WalletModel> _wallets = const [];
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefilled) return;
    _prefilled = true;
    // Seed the default category/wallet from saved preferences, if any.
    final prefs = ref.read(preferencesProvider);
    final defaultCat = prefs.defaultCategory;
    if (defaultCat != null && defaultCat.isNotEmpty) {
      _category = defaultCat;
      _loadSubCategories(defaultCat);
    }
    final defaultWallet = prefs.defaultWallet;
    if (defaultWallet != null && defaultWallet.isNotEmpty) {
      _account = defaultWallet;
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await ref.read(walletsRepositoryProvider).getWallets();
      if (!mounted) return;
      setState(() {
        _wallets = wallets;
        // Drop a stale default that no longer maps to a wallet.
        if (_account != null && !wallets.any((w) => w.id == _account)) {
          _account = null;
        }
      });
    } catch (_) {
      // Wallets are optional — ignore load failures.
    }
  }

  Future<void> _loadSubCategories(String category) async {
    try {
      final subs =
          await ref.read(categoriesRepositoryProvider).getSubCategories(category);
      if (!mounted) return;
      setState(() {
        _subCategories = subs;
        // Clear a sub-category that doesn't belong to the new category.
        if (_subCategory != null && !subs.contains(_subCategory)) {
          _subCategory = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _subCategories = const []);
    }
  }

  Future<void> _pickCategory() async {
    final picked = await context
        .push<String>('${Routes.selectCategory}?type=${widget.type}');
    if (picked == null || !mounted) return;
    setState(() {
      _category = picked;
      _subCategory = null;
      _subCategories = const [];
    });
    _loadSubCategories(picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _onDigit(String digit) {
    setState(() {
      if (digit == '.') {
        if (_amount.contains('.')) return; // only one decimal point
        _amount = _amount.isEmpty ? '0.' : '$_amount.';
        return;
      }
      var next = '$_amount$digit';
      // Strip leading zeros on the integer part (but keep a lone '0').
      if (!next.contains('.')) {
        next = next.replaceFirst(RegExp(r'^0+(?=\d)'), '');
      }
      // Cap raw length to mirror RN's 9-char guard.
      if (next.length > 9) return;
      _amount = next;
    });
  }

  void _onBackspace() {
    if (_amount.isEmpty) return;
    setState(() => _amount = _amount.substring(0, _amount.length - 1));
  }

  Future<void> _save() async {
    final amount = num.tryParse(_amount);
    if (amount == null || amount <= 0) {
      showAppSnack(context, 'Enter an amount', error: true);
      return;
    }
    if (_category == null || _category!.trim().isEmpty) {
      showAppSnack(context, 'Select a category', error: true);
      return;
    }

    final desc = _description.text.trim();
    final titleText = _title.text.trim();
    final sub = _subCategory?.trim() ?? '';
    final payload = <String, dynamic>{
      'amount': amount,
      'category': _category,
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'description': desc,
      'type': income ? 'income' : 'self',
      'sub_category': sub,
      if (_account != null && _account!.isNotEmpty) 'account': _account,
      'title': titleText.isNotEmpty ? titleText : _category,
    };

    setState(() => _saving = true);
    final repo = ref.read(transactionsRepositoryProvider);
    try {
      if (income) {
        await repo.addIncome(payload);
      } else {
        await repo.addExpense(payload);
      }
      if (!mounted) return;
      showAppSnack(context, income ? 'Income added' : 'Expense added');
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, errorMessage(e), error: true);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final symbol = ref.read(preferencesProvider).currencySymbol;
    final catSpec =
        _category == null ? null : resolveCategoryIcon(_category, income: income, colors: c);

    return GradientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(title: income ? 'Add Income' : 'Add Expense'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
              children: [
                // Amount display (driven by the numeric keypad below).
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(symbol,
                              style:
                                  AppText.title.copyWith(color: c.textSubtle)),
                          const SizedBox(width: 4),
                          Text(
                            _formatAmountInput(_amount).isEmpty
                                ? '0'
                                : _formatAmountInput(_amount),
                            style: AppText.displayLg
                                .copyWith(color: c.text, fontSize: 44),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text('Enter Amount',
                          style:
                              AppText.bodySm.copyWith(color: c.textSubtle)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Category selector → select-category screen.
                Text('Category',
                    style: AppText.label.copyWith(color: c.textSubtle)),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  onTap: _pickCategory,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      if (catSpec != null)
                        WealthifyIcon(catSpec.name, size: 22)
                      else
                        Icon(Icons.category_outlined,
                            size: 18, color: c.textSubtle),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _category ?? 'Select category',
                          style: AppText.body.copyWith(
                              color: _category != null
                                  ? c.text
                                  : c.textPlaceholder),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: c.textSubtle),
                    ],
                  ),
                ),

                // Sub-category (only when the category has any).
                if (_subCategories.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text('Sub-category',
                      style: AppText.label.copyWith(color: c.textSubtle)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final sub in _subCategories)
                        AppChip(
                          label: sub,
                          selected: _subCategory == sub,
                          onTap: () => setState(() => _subCategory =
                              _subCategory == sub ? null : sub),
                        ),
                    ],
                  ),
                ],

                // Wallet / account picker (only when wallets exist).
                if (_wallets.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Text('Wallet',
                      style: AppText.label.copyWith(color: c.textSubtle)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppChip(
                        label: 'None',
                        selected: _account == null,
                        onTap: () => setState(() => _account = null),
                      ),
                      for (final w in _wallets)
                        AppChip(
                          label: w.name,
                          selected: _account == w.id,
                          onTap: () => setState(() => _account = w.id),
                        ),
                    ],
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Date
                Text('Date',
                    style: AppText.label.copyWith(color: c.textSubtle)),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  onTap: _pickDate,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 18, color: c.textSubtle),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(DateFormat('dd MMM yyyy').format(_date),
                            style: AppText.body.copyWith(color: c.text)),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: c.textSubtle),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title (income only)
                if (income) ...[
                  AppTextField(
                    controller: _title,
                    label: 'Title',
                    hint: _category ?? 'Defaults to category',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Description
                AppTextField(
                  controller: _description,
                  label: 'Description (optional)',
                  hint: 'Add a note',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.xl2),

                PillButton(
                  label: income ? 'Save Income' : 'Save Expense',
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
}
