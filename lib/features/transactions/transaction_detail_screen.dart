import 'package:dio/dio.dart';
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
import '../../core/widgets/wealthify_icon.dart';
import '../../data/models/transaction_model.dart';
import '../../data/repositories/transactions_repository.dart';
import '../categories/select_category_screen.dart';
import '../preferences/preferences_controller.dart';

String _errorMessage(Object? error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return error.message ?? 'Network error';
  }
  return 'Something went wrong';
}

class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.txn});

  final TransactionModel txn;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late final TextEditingController _subCategory;
  late String _category;
  late String _date; // YYYY-MM-DD
  bool _saving = false;
  bool _deleting = false;

  TransactionModel get _txn => widget.txn;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: _txn.amount.toString());
    _description = TextEditingController(text: _txn.description ?? '');
    _subCategory = TextEditingController(text: _txn.subCategory ?? '');
    _category = _txn.category;
    _date = _txn.date;
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _subCategory.dispose();
    super.dispose();
  }

  DateTime? get _parsedDate {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(_date);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickCategory() async {
    final picked = await context
        .push<String>('${Routes.selectCategory}?type=${_txn.kind}');
    if (!mounted) return;
    if (picked != null && picked.trim().isNotEmpty) {
      setState(() => _category = picked.trim());
    }
  }

  Future<void> _pickDate() async {
    final initial = _parsedDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() => _date = DateFormat('yyyy-MM-dd').format(picked));
  }

  Future<void> _save() async {
    final parsed = num.tryParse(_amount.text.trim());
    if (parsed == null || parsed <= 0) {
      showAppSnack(context, 'Enter a valid amount', error: true);
      return;
    }
    if (_category.trim().isEmpty) {
      showAppSnack(context, 'Category is required', error: true);
      return;
    }
    if (_parsedDate == null) {
      showAppSnack(context, 'Use date format YYYY-MM-DD', error: true);
      return;
    }

    final isIncome = _txn.isIncome;
    final payload = <String, dynamic>{
      'amount': parsed,
      'category': _category.trim(),
      'date': DateFormat('yyyy-MM-dd').format(_parsedDate!),
      'description': _description.text.trim(),
      if (isIncome)
        'title': _category.trim()
      else ...{
        'sub_category': _subCategory.text.trim(),
        'type': _txn.type ?? 'self',
      },
    };

    setState(() => _saving = true);
    final repo = ref.read(transactionsRepositoryProvider);
    try {
      if (isIncome) {
        await repo.updateIncome(_txn.id, payload);
      } else {
        await repo.updateExpense(_txn.id, payload);
      }
      if (!mounted) return;
      showAppSnack(context,
          '${isIncome ? 'Income' : 'Expense'} updated');
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, _errorMessage(e), error: true);
      setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final isIncome = _txn.isIncome;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${isIncome ? 'income' : 'expense'}?'),
        content: const Text('This transaction will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: TextStyle(color: context.colors.negative)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    final repo = ref.read(transactionsRepositoryProvider);
    try {
      if (isIncome) {
        await repo.deleteIncome(_txn.id);
      } else {
        await repo.deleteExpense(_txn.id);
      }
      if (!mounted) return;
      showAppSnack(context,
          '${isIncome ? 'Income' : 'Expense'} deleted');
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, _errorMessage(e), error: true);
      setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final isIncome = _txn.isIncome;
    final amountColor = isIncome ? c.accentDark : c.negative;
    final iconSpec = resolveCategoryIcon(_category, income: isIncome, colors: c);
    final parsedDate = _parsedDate;
    final busy = _saving || _deleting;

    return GradientScaffold(
      child: Column(
        children: [
          ScreenHeader(title: isIncome ? 'Income Details' : 'Expense Details'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl4),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: iconSpec.color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: WealthifyIcon(iconSpec.name,
                                size: 36, color: iconSpec.color),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    isIncome
                                        ? 'Income received'
                                        : 'Expense paid',
                                    style: AppText.caption
                                        .copyWith(color: c.textSubtle)),
                                const SizedBox(height: 2),
                                Text(
                                  _category.trim().isEmpty
                                      ? (isIncome ? 'Income' : 'Expense')
                                      : _category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.subtitle.copyWith(color: c.text),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${isIncome ? '+' : '-'}${money(_txn.amount)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.display.copyWith(color: amountColor),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          _MetaChip(
                            icon: Icons.calendar_today_outlined,
                            label: parsedDate != null
                                ? DateFormat('dd MMM yyyy').format(parsedDate)
                                : 'No date',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _MetaChip(
                            icon: isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            label: isIncome ? 'Income' : 'Expense',
                            color: amountColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppTextField(
                  controller: _amount,
                  label: 'Amount',
                  hint: '0',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.payments_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Category',
                    style: AppText.label.copyWith(color: c.textSubtle)),
                const SizedBox(height: AppSpacing.sm),
                _CategoryChips(
                  type: _txn.kind,
                  selected: _category,
                  enabled: !busy,
                  onSelect: (v) => setState(() => _category = v),
                  onMore: _pickCategory,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!isIncome) ...[
                  AppTextField(
                    controller: _subCategory,
                    label: 'Sub-category',
                    hint: 'Optional',
                    prefixIcon: Icons.label_outline,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                AppTextField(
                  label: 'Date',
                  hint: 'YYYY-MM-DD',
                  readOnly: true,
                  onTap: busy ? null : _pickDate,
                  controller: TextEditingController(text: _date),
                  prefixIcon: Icons.event_outlined,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: _description,
                  label: 'Description',
                  hint: 'Add notes or details',
                  maxLines: 3,
                  prefixIcon: Icons.notes_outlined,
                ),
                const SizedBox(height: AppSpacing.xl2),
                PillButton(
                  label: 'Save changes',
                  loading: _saving,
                  onPressed: busy ? null : _save,
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  onPressed: busy ? null : _confirmDelete,
                  icon: Icon(Icons.delete_outline, size: 18, color: c.negative),
                  label: Text(_deleting ? 'Deleting...' : 'Delete',
                      style: AppText.bodyMedium.copyWith(color: c.negative)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: c.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? c.textSubtle),
          const SizedBox(width: 6),
          Text(label, style: AppText.caption.copyWith(color: c.textBody)),
        ],
      ),
    );
  }
}

/// Horizontal strip of popular categories (recents + saved + defaults, deduped)
/// plus a "More" chip that opens the full picker. Mirrors the RN
/// `CategorySelector` in `transaction-detail.tsx`.
class _CategoryChips extends ConsumerWidget {
  const _CategoryChips({
    required this.type,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    required this.onMore,
  });

  final String type; // 'income' | 'expense'
  final String selected;
  final bool enabled;
  final ValueChanged<String> onSelect;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final async = ref.watch(categoryOptionsProvider(type));
    final income = type == 'income';

    final options = async.maybeWhen(
      data: (o) => [...o.recent, ...o.grid],
      orElse: () => <String>[],
    );

    // Dedupe, keep current selection in view, cap to 6 like RN.
    final seen = <String>{};
    final popular = <String>[];
    for (final name in [
      if (selected.trim().isNotEmpty) selected.trim(),
      ...options,
    ]) {
      final label = name.trim();
      if (label.isEmpty) continue;
      if (seen.add(label.toLowerCase())) popular.add(label);
    }
    final visible = popular.take(6).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final name in visible) ...[
            Builder(builder: (_) {
              final spec = resolveCategoryIcon(name, income: income, colors: c);
              return AppChip(
                label: name,
                icon: null,
                selected: name.toLowerCase() == selected.toLowerCase(),
                onTap: enabled ? () => onSelect(name) : null,
                // Use the resolved brand glyph for parity with RN chips.
                leading: WealthifyIcon(spec.name, size: 15),
              );
            }),
            const SizedBox(width: AppSpacing.sm),
          ],
          AppChip(
            label: 'More',
            icon: Icons.more_horiz,
            onTap: enabled ? onMore : null,
          ),
        ],
      ),
    );
  }
}
