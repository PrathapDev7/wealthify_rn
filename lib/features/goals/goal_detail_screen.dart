import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/widgets.dart';
import '../../data/models/goal_model.dart';
import '../../data/repositories/goals_repository.dart';
import '../auth/auth_screen.dart';
import '../preferences/preferences_controller.dart';

String _formatDate(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final d = DateTime.tryParse(iso);
  if (d == null) return '';
  return DateFormat('d MMM yyyy').format(d);
}

/// Fetches the single goal by id (mirrors the detail-mode `load()` in
/// `legacy_rn/app/goal-detail.tsx`, which re-pulls the goals list and finds
/// the one being viewed). Lets contribute / mark-complete / save-edit refresh
/// the detail view in place instead of leaving the screen.
final _goalDetailProvider =
    FutureProvider.autoDispose.family<GoalModel?, String>((ref, id) async {
  final goals = await ref.read(goalsRepositoryProvider).getGoals();
  for (final g in goals) {
    if (g.id == id) return g;
  }
  return null;
});

class GoalDetailScreen extends ConsumerStatefulWidget {
  const GoalDetailScreen({super.key, this.goal});

  final GoalModel? goal;

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  // Form fields (create mode + inline edit in detail mode).
  late final TextEditingController _name;
  late final TextEditingController _targetAmount;
  late final TextEditingController _note;
  final _contribAmount = TextEditingController();

  String? _targetDate; // ISO yyyy-MM-dd
  bool _editing = false;
  bool _saving = false;
  bool _contributing = false;
  bool _completing = false;

  bool get _isCreate => widget.goal == null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _name = TextEditingController(text: g?.name ?? '');
    _targetAmount =
        TextEditingController(text: g == null ? '' : '${g.targetAmount}');
    _note = TextEditingController(text: g?.note ?? '');
    _targetDate = g?.targetDate != null && g!.targetDate!.length >= 10
        ? g.targetDate!.substring(0, 10)
        : null;
  }

  @override
  void dispose() {
    _name.dispose();
    _targetAmount.dispose();
    _note.dispose();
    _contribAmount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial =
        (_targetDate != null ? DateTime.tryParse(_targetDate!) : null) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 50),
    );
    if (picked != null) {
      setState(() => _targetDate = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  // ---- create mode ----
  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Enter a goal name', error: true);
      return;
    }
    final target = num.tryParse(_targetAmount.text.trim());
    if (target == null || target <= 0) {
      showAppSnack(context, 'Enter a target amount', error: true);
      return;
    }
    final note = _note.text.trim();
    setState(() => _saving = true);
    try {
      await ref.read(goalsRepositoryProvider).addGoal({
        'name': name,
        'targetAmount': target,
        if (_targetDate != null) 'targetDate': _targetDate,
        if (note.isNotEmpty) 'note': note,
      });
      if (!mounted) return;
      showAppSnack(context, 'Goal created');
      context.pop(true);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---- detail mode actions ----
  Future<void> _contribute(String id) async {
    final amount = num.tryParse(_contribAmount.text.trim());
    if (amount == null || amount <= 0) {
      showAppSnack(context, 'Enter an amount', error: true);
      return;
    }
    setState(() => _contributing = true);
    try {
      await ref.read(goalsRepositoryProvider).contributeGoal(id, amount);
      if (!mounted) return;
      _contribAmount.clear();
      showAppSnack(context, 'Contribution added');
      ref.invalidate(_goalDetailProvider(id));
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _contributing = false);
    }
  }

  void _startEditing(GoalModel goal) {
    _name.text = goal.name;
    _targetAmount.text = '${goal.targetAmount}';
    _note.text = goal.note ?? '';
    _targetDate = goal.targetDate != null && goal.targetDate!.length >= 10
        ? goal.targetDate!.substring(0, 10)
        : null;
    setState(() => _editing = true);
  }

  Future<void> _saveEdit(String id) async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Enter a goal name', error: true);
      return;
    }
    final target = num.tryParse(_targetAmount.text.trim());
    if (target == null || target <= 0) {
      showAppSnack(context, 'Enter a target amount', error: true);
      return;
    }
    final note = _note.text.trim();
    final hasDate = _targetDate != null && _targetDate!.isNotEmpty;
    setState(() => _saving = true);
    try {
      await ref.read(goalsRepositoryProvider).updateGoal(id, {
        'name': name,
        'targetAmount': target,
        if (hasDate) 'targetDate': _targetDate,
        if (note.isNotEmpty) 'note': note,
      });
      if (!mounted) return;
      showAppSnack(context, 'Goal updated');
      setState(() => _editing = false);
      ref.invalidate(_goalDetailProvider(id));
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _markComplete(String id) async {
    setState(() => _completing = true);
    try {
      await ref
          .read(goalsRepositoryProvider)
          .updateGoal(id, {'completed': true});
      if (!mounted) return;
      showAppSnack(context, 'Goal marked complete');
      ref.invalidate(_goalDetailProvider(id));
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _delete(String id) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title:
            Text('Delete goal', style: AppText.subtitle.copyWith(color: c.text)),
        content: Text(
          'Delete this savings goal? This cannot be undone.',
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
      await ref.read(goalsRepositoryProvider).deleteGoal(id);
      if (!mounted) return;
      showAppSnack(context, 'Goal deleted');
      context.pop(true);
    } catch (e) {
      if (mounted) showAppSnack(context, errorMessage(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreate) {
      return GradientScaffold(
        child: Column(
          children: [
            const ScreenHeader(title: 'New goal'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
                children: _buildForm('Create goal', _create),
              ),
            ),
          ],
        ),
      );
    }

    // Detail mode: drive the view from the provider so contribute /
    // mark-complete / save-edit refresh in place.
    final id = widget.goal!.id;
    final async = ref.watch(_goalDetailProvider(id));
    final title = _editing ? 'Edit goal' : 'Goal';

    return GradientScaffold(
      child: Column(
        children: [
          ScreenHeader(title: title),
          Expanded(
            child: async.when(
              loading: () => const LoadingView(),
              error: (e, _) => Center(
                child: PillButton(
                  label: 'Retry',
                  expand: false,
                  onPressed: () => ref.invalidate(_goalDetailProvider(id)),
                ),
              ),
              data: (goal) {
                if (goal == null) {
                  return const EmptyState(
                    icon: Icons.error_outline,
                    title: 'Goal not found',
                    message: 'It may have been deleted. Go back and try again.',
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 120),
                  children: _editing
                      ? _buildForm('Save changes', () => _saveEdit(id),
                          showCancel: true)
                      : _buildDetail(goal),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- create / edit form ----
  List<Widget> _buildForm(String submitLabel, Future<void> Function() onSubmit,
      {bool showCancel = false}) {
    final c = context.colors;
    return [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              controller: _name,
              label: 'Name',
              hint: 'e.g. Emergency fund',
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _targetAmount,
              label: 'Target amount',
              hint: '0',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Target date (optional)',
                style: AppText.label.copyWith(color: c.textSubtle)),
            const SizedBox(height: AppSpacing.xs),
            AppTextField(
              readOnly: true,
              onTap: _pickDate,
              hint: 'Select date',
              controller: TextEditingController(
                  text: _targetDate == null ? '' : _formatDate(_targetDate)),
              prefixIcon: Icons.calendar_today_outlined,
              suffix: _targetDate == null
                  ? null
                  : IconButton(
                      icon: Icon(Icons.close, size: 18, color: c.textSubtle),
                      onPressed: () => setState(() => _targetDate = null),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _note,
              label: 'Note (optional)',
              hint: 'Add a note',
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
      PillButton(
        label: submitLabel,
        loading: _saving,
        onPressed: _saving ? null : onSubmit,
      ),
      if (showCancel) ...[
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: 'Cancel',
          variant: PillVariant.secondary,
          onPressed: () => setState(() => _editing = false),
        ),
      ],
    ];
  }

  // ---- detail view ----
  List<Widget> _buildDetail(GoalModel goal) {
    final c = context.colors;
    ref.watch(preferencesProvider);
    final money = ref.read(preferencesProvider.notifier).money;
    final percent = (goal.progress * 100).round();
    final contributions = [...goal.contributions]
      ..sort((a, b) => (b.date ?? '').compareTo(a.date ?? ''));

    return [
      // Progress header.
      AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(goal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title.copyWith(color: c.text)),
                ),
                if (goal.completed) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _CompletedBadge(),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text.rich(
              TextSpan(
                style: AppText.titleLg.copyWith(color: c.text),
                children: [
                  TextSpan(text: money(goal.savedAmount)),
                  TextSpan(
                    text: ' / ${money(goal.targetAmount)}',
                    style: AppText.body.copyWith(color: c.textSubtle),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppProgressBar(value: goal.progress),
            const SizedBox(height: AppSpacing.sm),
            Text('$percent% saved',
                style: AppText.bodySm.copyWith(color: c.textSubtle)),
            if (goal.targetDate != null && goal.targetDate!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text('Target date ${_formatDate(goal.targetDate)}',
                  style: AppText.caption.copyWith(color: c.textSubtle)),
            ],
            if (goal.note != null && goal.note!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(goal.note!,
                  style: AppText.bodySm.copyWith(color: c.textBody)),
            ],
          ],
        ),
      ),

      // Add contribution.
      if (!goal.completed)
        AppCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add contribution',
                  style: AppText.subtitle.copyWith(color: c.text)),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _contribAmount,
                hint: 'Amount',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: AppSpacing.md),
              PillButton(
                label: 'Add contribution',
                loading: _contributing,
                onPressed: _contributing ? null : () => _contribute(goal.id),
              ),
            ],
          ),
        ),

      // Contributions list.
      AppCard(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contributions',
                style: AppText.subtitle.copyWith(color: c.text)),
            const SizedBox(height: AppSpacing.sm),
            if (contributions.isEmpty)
              Text('No contributions yet',
                  style: AppText.bodySm.copyWith(color: c.textSubtle))
            else
              for (var i = 0; i < contributions.length; i++)
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: i == 0
                      ? null
                      : BoxDecoration(
                          border: Border(
                              top: BorderSide(color: c.border, width: 0.5))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(contributions[i].date).isEmpty
                                  ? 'Contribution'
                                  : _formatDate(contributions[i].date),
                              style: AppText.bodyMedium
                                  .copyWith(color: c.text),
                            ),
                            if (contributions[i].note != null &&
                                contributions[i].note!.isNotEmpty)
                              Text(contributions[i].note!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.caption
                                      .copyWith(color: c.textSubtle)),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('+${money(contributions[i].amount)}',
                          style: AppText.moneySm
                              .copyWith(color: c.accentDark)),
                    ],
                  ),
                ),
          ],
        ),
      ),

      // Actions.
      PillButton(
        label: 'Edit goal',
        variant: PillVariant.secondary,
        onPressed: () => _startEditing(goal),
      ),
      if (!goal.completed) ...[
        const SizedBox(height: AppSpacing.md),
        PillButton(
          label: 'Mark complete',
          loading: _completing,
          onPressed: _completing ? null : () => _markComplete(goal.id),
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      TextButton.icon(
        onPressed: () => _delete(goal.id),
        icon: Icon(Icons.delete_outline, color: c.negative, size: 18),
        label: Text('Delete',
            style: AppText.button.copyWith(color: c.negative)),
      ),
    ];
  }
}

class _CompletedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: c.accentDark,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, size: 12, color: c.textInverse),
          const SizedBox(width: 3),
          Text('Completed',
              style: AppText.caption.copyWith(
                  color: c.textInverse, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
