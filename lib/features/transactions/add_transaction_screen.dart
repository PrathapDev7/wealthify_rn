import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import '../../data/repositories/transactions_repository.dart';
import '../auth/auth_screen.dart';
import '../preferences/preferences_controller.dart';

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

  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _title = TextEditingController();
  String? _category;
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickCategory() async {
    final picked = await context
        .push<String>('${Routes.selectCategory}?type=${widget.type}');
    if (picked != null) setState(() => _category = picked);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, now.month, now.day),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final amount = num.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      showAppSnack(context, 'Enter an amount', error: true);
      return;
    }
    if (_category == null) {
      showAppSnack(context, 'Select a category', error: true);
      return;
    }

    final desc = _description.text.trim();
    final titleText = _title.text.trim();
    final payload = <String, dynamic>{
      'amount': amount,
      'category': _category,
      'date': DateFormat('yyyy-MM-dd').format(_date),
      'description': desc,
      if (income)
        'title': titleText.isNotEmpty ? titleText : _category
      else
        'type': 'self',
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final symbol = ref.read(preferencesProvider).currencySymbol;

    return GradientScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(title: income ? 'Add Income' : 'Add Expense'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl4),
              children: [
                // Amount
                Text('Amount', style: AppText.label.copyWith(color: c.textSubtle)),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  decoration: BoxDecoration(
                    color: c.inputBackground,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: c.inputBorder),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Text(symbol,
                          style: AppText.title.copyWith(color: c.textSubtle)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextField(
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: AppText.displayLg.copyWith(color: c.text),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: '0',
                            hintStyle: AppText.displayLg
                                .copyWith(color: c.textPlaceholder),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Category
                Text('Category',
                    style: AppText.label.copyWith(color: c.textSubtle)),
                const SizedBox(height: AppSpacing.xs),
                AppCard(
                  onTap: _pickCategory,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      Icon(Icons.category_outlined,
                          size: 18, color: c.textSubtle),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          _category ?? 'Select category',
                          style: AppText.body.copyWith(
                              color:
                                  _category != null ? c.text : c.textPlaceholder),
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 20, color: c.textSubtle),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Date
                Text('Date', style: AppText.label.copyWith(color: c.textSubtle)),
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
        ],
      ),
    );
  }
}
