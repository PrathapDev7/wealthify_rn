import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/workout_models.dart';
import '../../../data/repositories/workout_repository.dart';
import 'workout_widgets.dart';

/// "Update with AI": refines the week a plan already has, in conversation.
///
/// The stored "Build me a routine" conversation (brief + history) travels
/// server-side, so the model remembers the injuries and dislikes from the
/// original build. Like the builder, nothing is written until the user
/// confirms — the draft is previewed, revised, and only then applied.
///
/// Resolves to the refined [WorkoutPlan] when the draft was accepted, and to
/// null when the user backed out.
Future<WorkoutPlan?> showUpdateRoutineDialog(
  BuildContext context, {
  required WorkoutPlan plan,
}) {
  final theme = Theme.of(context);
  return showDialog<WorkoutPlan>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Theme(
      data: theme,
      child: _UpdateRoutineDialog(plan: plan),
    ),
  );
}

/// Where the flow is. The request step owns the whole dialog first — there is
/// no brief to fill in, the week already exists — then the draft takes over.
enum _Step { request, working, preview, confirm }

class _UpdateRoutineDialog extends ConsumerStatefulWidget {
  const _UpdateRoutineDialog({required this.plan});

  final WorkoutPlan plan;

  @override
  ConsumerState<_UpdateRoutineDialog> createState() =>
      _UpdateRoutineDialogState();
}

class _UpdateRoutineDialogState extends ConsumerState<_UpdateRoutineDialog> {
  _Step _step = _Step.request;

  final _request = TextEditingController();
  final _change = TextEditingController();

  /// Every change asked for in this session, oldest first. Sent back with
  /// every revision so the model keeps the whole thread, not just the latest
  /// sentence — and stored on the plan at apply time.
  final List<String> _history = [];

  BuiltPlan? _draft;
  int _routineIndex = 0;
  String? _error;
  bool _applying = false;

  static const _progressLines = [
    'Reading your week…',
    'Remembering the original brief…',
    'Reworking the exercises…',
    'Balancing sets and rest…',
    'Almost there…',
  ];
  int _progressIndex = 0;
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    _request.dispose();
    _change.dispose();
    super.dispose();
  }

  WorkoutRepository get _repo => ref.read(workoutRepositoryProvider);

  /// The week on screen, in the compact shape the refine endpoint speaks.
  /// Rest between exercises is deliberately left out: the model never sees it,
  /// and the apply endpoint carries it over by name and order instead.
  List<Map<String, dynamic>> get _currentRoutines => [
    for (final routine in widget.plan.routines)
      {
        'name': routine.name,
        'exercises': [
          for (final exercise in routine.exercises)
            {
              'name': exercise.name,
              'muscle': exercise.muscleLabel,
              'equipment': exercise.equipment ?? '',
              'sets': exercise.sets.length,
              if (exercise.sets.isNotEmpty &&
                  exercise.sets.first.reps != null)
                'reps': exercise.sets.first.reps,
              if (exercise.sets.isNotEmpty &&
                  exercise.sets.first.durationSec != null)
                'seconds': exercise.sets.first.durationSec,
              'restSec': exercise.restBetweenSetsSec,
            },
        ],
      },
  ];

  /* ---------------------------------------------------------- generating -- */

  Future<void> _generate({required String request}) async {
    final trimmed = request.trim();
    if (trimmed.isEmpty) return;
    final history = [..._history, trimmed];
    setState(() {
      _step = _Step.working;
      _error = null;
      _progressIndex = 0;
    });
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted) return;
      setState(() {
        _progressIndex = (_progressIndex + 1) % _progressLines.length;
      });
    });

    try {
      final draft = await _repo.refineRoutines(
        planId: widget.plan.id,
        request: trimmed,
        routines: _currentRoutines,
      );
      if (!mounted) return;
      setState(() {
        _history
          ..clear()
          ..addAll(history);
        _draft = draft;
        _routineIndex = _routineIndex.clamp(
          0,
          draft.routines.isEmpty ? 0 : draft.routines.length - 1,
        );
        _step = _Step.preview;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'That did not come back cleanly. Try again.';
        // Back to whichever step the user can act on: the draft if there is
        // one, the request field if the very first attempt failed.
        _step = _draft == null ? _Step.request : _Step.preview;
      });
    } finally {
      _progressTimer?.cancel();
    }
  }

  Future<void> _apply() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      final plan = await _repo.applyRefinedRoutines(
        widget.plan.id,
        draft,
        request: _history.isEmpty ? null : _history.last,
      );
      if (mounted) Navigator.of(context).pop(plan);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _error = 'Could not save the plan. Try again.';
      });
    }
  }

  void _askFirst() {
    final request = _request.text.trim();
    if (request.isEmpty) return;
    _request.clear();
    FocusScope.of(context).unfocus();
    _generate(request: request);
  }

  void _askForChange() {
    final request = _change.text.trim();
    if (request.isEmpty) return;
    _change.clear();
    FocusScope.of(context).unfocus();
    _generate(request: request);
  }

  /* --------------------------------------------------------------- build -- */

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: c.surfaceElevated,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl2,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: size.height * 0.82,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(c),
            Flexible(child: _body(c)),
            _footer(c),
          ],
        ),
      ),
    );
  }

  Widget _header(AppColors c) {
    final title = switch (_step) {
      _Step.request => 'Update with AI',
      _Step.working => 'Updating your week',
      _Step.preview => 'Your updated week',
      _Step.confirm => 'Replace what you have?',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppText.bodyLargeRegular.copyWith(color: c.text),
            ),
          ),
          if (_step != _Step.working && !_applying)
            FitnessIconButton(
              icon: Icons.close_rounded,
              size: 36,
              iconSize: 16,
              background: Colors.transparent,
              onTap: () => Navigator.of(context).pop(),
            ),
        ],
      ),
    );
  }

  Widget _body(AppColors c) {
    final body = switch (_step) {
      _Step.request => _requestStep(c),
      _Step.working => _workingStep(c),
      _Step.preview => _previewStep(c),
      _Step.confirm => _confirmStep(c),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          body,
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppText.bodySm.copyWith(color: c.negative),
            ),
          ],
        ],
      ),
    );
  }

  /* ---------------------------------------------------------------- steps -- */

  Widget _requestStep(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell me what to change about ${widget.plan.name}. I remember how '
          'it was built, so injuries and dislikes still apply.',
          style: AppText.bodySm.copyWith(color: c.textSubtle),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChangeField(
          controller: _request,
          hintText: 'What should change? "swap the squats"',
          onSend: _askFirst,
        ),
      ],
    );
  }

  Widget _workingStep(AppColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl4),
      child: Column(
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: c.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _progressLines[_progressIndex],
              key: ValueKey(_progressIndex),
              style: AppText.body.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewStep(AppColors c) {
    final draft = _draft;
    if (draft == null || draft.routines.isEmpty) {
      return Text(
        'Nothing came back. Try again.',
        style: AppText.body.copyWith(color: c.textSubtle),
      );
    }

    final routine = draft.routines[_routineIndex.clamp(
      0,
      draft.routines.length - 1,
    )];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (draft.summary.isNotEmpty)
          Text(
            draft.summary,
            style: AppText.bodySm.copyWith(color: c.textSubtle),
          ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: draft.routines.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final selected = index == _routineIndex;
              return _Chip(
                label: draft.routines[index].name,
                selected: selected,
                onTap: () => setState(() => _routineIndex = index),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        for (final (index, exercise) in routine.exercises.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.sm),
          _ExerciseLine(exercise: exercise),
        ],
        const SizedBox(height: AppSpacing.lg),
        _ChangeField(
          controller: _change,
          hintText: 'Ask for a change — "shorter Fridays"',
          onSend: _askForChange,
        ),
      ],
    );
  }

  Widget _confirmStep(AppColors c) {
    final routines = widget.plan.routines.length;
    final exercises = widget.plan.routines.fold<int>(
      0,
      (total, routine) => total + routine.exercises.length,
    );
    final draft = _draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'The ${routines == 1 ? 'routine' : '$routines routines'} in '
          '${widget.plan.name}'
          '${exercises > 0 ? ' and their $exercises '
                '${exercises == 1 ? 'exercise' : 'exercises'}' : ''} '
          'will be deleted and replaced by this update.',
          style: AppText.body.copyWith(color: c.text),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          draft == null
              ? ''
              : 'New: ${draft.routines.length} '
                    '${draft.routines.length == 1 ? 'routine' : 'routines'}, '
                    '${draft.exerciseCount} exercises.',
          style: AppText.bodySm.copyWith(color: c.textSubtle),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Your workout history is not touched.',
          style: AppText.bodySm.copyWith(color: c.textSubtle),
        ),
      ],
    );
  }

  /* --------------------------------------------------------------- footer -- */

  Widget _footer(AppColors c) {
    final padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
    );

    return switch (_step) {
      _Step.working => const SizedBox(height: AppSpacing.lg),
      _Step.request => Padding(
        padding: padding,
        child: PillButton(
          label: 'Update my week',
          radius: AppRadius.sm,
          height: 46,
          labelStyle: AppText.body,
          onPressed: _askFirst,
        ),
      ),
      _Step.preview => Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'Start over',
                variant: PillVariant.secondary,
                radius: AppRadius.sm,
                height: 46,
                labelStyle: AppText.body,
                onPressed: () => setState(() => _step = _Step.request),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: PillButton(
                label: 'Use this week',
                radius: AppRadius.sm,
                height: 46,
                labelStyle: AppText.body,
                onPressed: () => setState(() => _step = _Step.confirm),
              ),
            ),
          ],
        ),
      ),
      _Step.confirm => Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'Back',
                variant: PillVariant.secondary,
                radius: AppRadius.sm,
                height: 46,
                labelStyle: AppText.body,
                onPressed: _applying
                    ? null
                    : () => setState(() => _step = _Step.preview),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: PillButton(
                label: 'Replace',
                loading: _applying,
                loadingLabel: 'Saving…',
                radius: AppRadius.sm,
                height: 46,
                labelStyle: AppText.body,
                gradientColors: [c.negative, c.negative],
                onPressed: _applying ? null : _apply,
              ),
            ),
          ],
        ),
      ),
    };
  }
}

/* ----------------------------------------------------------------- bits -- */

/// The "ask for a change" field with its filled circular send button.
class _ChangeField extends StatelessWidget {
  const _ChangeField({
    required this.controller,
    required this.hintText,
    required this.onSend,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.send,
      onSubmitted: (_) => onSend(),
      style: AppText.body.copyWith(color: c.text),
      cursorColor: c.primary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppText.bodySm.copyWith(color: c.textPlaceholder),
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.only(
          left: AppSpacing.md,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide.none,
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(6),
          child: _SendButton(onTap: onSend),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 48,
          minHeight: 48,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: selected ? c.primary : c.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: AppText.bodySm.copyWith(
              color: selected ? c.textOnPrimary : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// The filled circular send button inside the change fields.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primary,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            Icons.arrow_upward_rounded,
            size: 20,
            color: c.textOnPrimary,
          ),
        ),
      ),
    );
  }
}

/// One line of the draft: the movement, what it works, and the volume.
class _ExerciseLine extends StatelessWidget {
  const _ExerciseLine({required this.exercise});

  final BuiltExercise exercise;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final volume = exercise.seconds != null
        ? '${exercise.setCount} × ${exercise.seconds}s'
        : '${exercise.setCount} × ${exercise.reps}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: AppSpacing.md),
          decoration: BoxDecoration(
            color: exercise.gif == null ? Colors.transparent : c.primary,
            shape: BoxShape.circle,
            border: Border.all(color: c.primary, width: 1),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(color: c.text),
              ),
              if (exercise.muscleLabel.isNotEmpty)
                Text(
                  exercise.muscleLabel,
                  style: AppText.caption.copyWith(color: c.textSubtle),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(volume, style: AppText.bodySm.copyWith(color: c.textSecondary)),
      ],
    );
  }
}
