import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/misc.dart';
import '../../data/models/recurring_model.dart';
import '../../data/repositories/recurring_repository.dart';
import '../auth/auth_screen.dart';

const _kinds = ['expense', 'income'];
const _kindLabels = {'expense': 'Expense', 'income': 'Income'};
const _kindIcons = {
  'expense': Icons.arrow_upward,
  'income': Icons.arrow_downward,
};

const _frequencies = ['daily', 'weekly', 'monthly', 'yearly'];
const _frequencyLabels = {
  'daily': 'Daily',
  'weekly': 'Weekly',
  'monthly': 'Monthly',
  'yearly': 'Yearly',
};

class EditRecurringScreen extends ConsumerStatefulWidget {
  const EditRecurringScreen({super.key, this.rule});

  final RecurringModel? rule;

  @override
  ConsumerState<EditRecurringScreen> createState() =>
      _EditRecurringScreenState();
}

class _EditRecurringScreenState extends ConsumerState<EditRecurringScreen> {
  late final TextEditingController _amount;
  late final TextEditingController _category;
  late final TextEditingController _interval;
  late final TextEditingController _description;
  late String _kind;
  late String _frequency;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  bool get _isEdit => widget.rule != null;

  @override
  void initState() {
    super.initState();
    final r = widget.rule;
    _amount = TextEditingController(text: r == null ? '' : '${r.amount}');
    _category = TextEditingController(text: r?.category ?? '');
    _interval = TextEditingController(text: r == null ? '1' : '${r.interval}');
    _description = TextEditingController(text: r?.description ?? '');
    _kind = r?.kind ?? 'expense';
    _frequency = r?.frequency ?? 'monthly';
    _startDate = _parseDate(r?.startDate);
    _endDate = _parseDate(r?.endDate);
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  @override
  void dispose() {
    _amount.dispose();
    _category.dispose();
    _interval.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickEnd() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 10, now.month, now.day),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _save() async {
    final amount = num.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      showAppSnack(context, 'Enter an amount', error: true);
      return;
    }
    final category = _category.text.trim();
    if (category.isEmpty) {
      showAppSnack(context, 'Enter a category', error: true);
      return;
    }
    if (_startDate == null) {
      showAppSnack(context, 'Pick a start date', error: true);
      return;
    }

    final desc = _description.text.trim();
    final payload = <String, dynamic>{
      'kind': _kind,
      'amount': amount,
      'category': category,
      'frequency': _frequency,
      'interval': int.tryParse(_interval.text.trim()) ?? 1,
      'startDate': DateFormat('yyyy-MM-dd').format(_startDate!),
      'description': desc,
      if (_endDate != null) 'endDate': DateFormat('yyyy-MM-dd').format(_endDate!),
      if (_kind == 'income') 'title': category,
    };

    setState(() => _saving = true);
    final repo = ref.read(recurringRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateRecurring(widget.rule!.id, payload);
      } else {
        await repo.addRecurring(payload);
      }
      if (!mounted) return;
      showAppSnack(context, _isEdit ? 'Recurring updated' : 'Recurring added');
      context.pop(true);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Delete recurring',
            style: AppText.subtitle.copyWith(color: c.text)),
        content: Text(
          'Delete this recurring transaction? Future entries will no longer be created.',
          style: AppText.bodySm.copyWith(color: c.textSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppText.button.copyWith(color: c.textSubtle)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete',
                style: AppText.button.copyWith(color: c.negative)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(recurringRepositoryProvider).deleteRecurring(widget.rule!.id);
      if (!mounted) return;
      showAppSnack(context, 'Recurring deleted');
      context.pop(true);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GradientScaffold(
      child: Column(
        children: [
          ScreenHeader(title: _isEdit ? 'Edit recurring' : 'Add recurring'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type',
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          for (final k in _kinds) ...[
                            AppChip(
                              label: _kindLabels[k]!,
                              icon: _kindIcons[k],
                              selected: _kind == k,
                              onTap: () => setState(() => _kind = k),
                            ),
                            if (k != _kinds.last)
                              const SizedBox(width: AppSpacing.sm),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _amount,
                        label: 'Amount',
                        hint: '0',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _category,
                        label: 'Category',
                        hint: 'e.g. Rent, Salary, Netflix',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _description,
                        label: 'Description (optional)',
                        hint: 'Add a note',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Frequency',
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final f in _frequencies)
                            AppChip(
                              label: _frequencyLabels[f]!,
                              selected: _frequency == f,
                              onTap: () => setState(() => _frequency = f),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _interval,
                        label: 'Repeat every (interval)',
                        hint: '1',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Start date',
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.xs),
                      _DateRow(
                        value: _startDate == null
                            ? 'Select start date'
                            : DateFormat('dd MMM yyyy').format(_startDate!),
                        placeholder: _startDate == null,
                        onTap: _pickStart,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('End date (optional)',
                          style: AppText.label.copyWith(color: c.textSubtle)),
                      const SizedBox(height: AppSpacing.xs),
                      _DateRow(
                        value: _endDate == null
                            ? 'No end date'
                            : DateFormat('dd MMM yyyy').format(_endDate!),
                        placeholder: _endDate == null,
                        onTap: _pickEnd,
                        onClear:
                            _endDate == null ? null : () => setState(() => _endDate = null),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PillButton(
                  label: _isEdit ? 'Save changes' : 'Add recurring',
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
                if (_isEdit) ...[
                  const SizedBox(height: AppSpacing.md),
                  TextButton.icon(
                    onPressed: _delete,
                    icon:
                        Icon(Icons.delete_outline, color: c.negative, size: 18),
                    label: Text('Delete recurring',
                        style: AppText.button.copyWith(color: c.negative)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.onClear,
  });

  final String value;
  final bool placeholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.inputBackground,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: c.inputBorder),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 18, color: c.textSubtle),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                value,
                style: AppText.body.copyWith(
                    color: placeholder ? c.textPlaceholder : c.text),
              ),
            ),
            if (onClear != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close, size: 18, color: c.textSubtle),
              ),
          ],
        ),
      ),
    );
  }
}
