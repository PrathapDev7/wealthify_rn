import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/budget_model.dart';
import '../../data/repositories/budgets_repository.dart';
import '../auth/auth_screen.dart';

class SetBudgetScreen extends ConsumerStatefulWidget {
  const SetBudgetScreen({super.key, this.category});

  final String? category;

  @override
  ConsumerState<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends ConsumerState<SetBudgetScreen> {
  final _amount = TextEditingController();

  BudgetModel _current = const BudgetModel();
  bool _loading = true;
  bool _saving = false;

  String get _budgetKey => widget.category ?? 'Overall';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final budget = await ref.read(budgetsRepositoryProvider).getBudgets();
      if (!mounted) return;
      final existing = budget.budgets[_budgetKey];
      setState(() {
        _current = budget;
        if (existing != null) _amount.text = existing.toString();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final parsed = num.tryParse(_amount.text.trim());
    if (parsed == null || parsed <= 0) {
      showAppSnack(context, 'Enter an amount', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final merged = {..._current.budgets, _budgetKey: parsed};
      await ref.read(budgetsRepositoryProvider).save(_current, merged);
      if (!mounted) return;
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

    return GradientScaffold(
      child: Column(
        children: [
          const ScreenHeader(title: 'Set Budget'),
          Expanded(
            child: _loading
                ? const LoadingView()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
                    children: [
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Budget for',
                                style: AppText.label
                                    .copyWith(color: c.textSubtle)),
                            const SizedBox(height: AppSpacing.xs),
                            Text(_budgetKey,
                                style:
                                    AppText.subtitle.copyWith(color: c.text)),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _amount,
                        label: 'Monthly limit',
                        hint: 'Enter amount',
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PillButton(
                        label: 'Save budget',
                        loading: _saving,
                        onPressed: _save,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
