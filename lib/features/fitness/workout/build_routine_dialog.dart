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

/// "Build me a routine": a whole training week written from a four-tap brief,
/// revised in conversation, and only then written over the plan.
///
/// Centred rather than a bottom sheet, and non-dismissible by tapping outside:
/// this is a several-step flow that ends in a destructive write, so it holds
/// the screen until the user leaves it deliberately.
///
/// Resolves to the rebuilt [WorkoutPlan] when the draft was accepted, and to
/// null when the user backed out — nothing is written in that case.
Future<WorkoutPlan?> showBuildRoutineDialog(
  BuildContext context, {
  required WorkoutPlan plan,
}) {
  // Carried across explicitly: the dialog's route is a sibling overlay entry,
  // not a descendant of FitnessTheme, so the palette has to travel with it.
  final theme = Theme.of(context);
  return showDialog<WorkoutPlan>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Theme(
      data: theme,
      child: _BuildRoutineDialog(plan: plan),
    ),
  );
}

/// Where the flow is. Each step owns the whole dialog body, so there is only
/// ever one thing on screen to read and one thing to do.
enum _Step { brief, working, preview, confirm }

class _BuildRoutineDialog extends ConsumerStatefulWidget {
  const _BuildRoutineDialog({required this.plan});

  final WorkoutPlan plan;

  @override
  ConsumerState<_BuildRoutineDialog> createState() => _BuildRoutineDialogState();
}

class _BuildRoutineDialogState extends ConsumerState<_BuildRoutineDialog> {
  _Step _step = _Step.brief;

  // The brief. Defaults are the most common answer to each question, so the
  // fastest path through is one tap on "Build my week".
  int _days = 3;
  String _goal = 'Build muscle';
  String _level = 'Beginner';
  String _place = 'Full gym';
  int _minutes = 45;
  final _notes = TextEditingController();

  final _change = TextEditingController();

  BuiltPlan? _draft;
  int _routineIndex = 0;
  String? _error;
  bool _applying = false;

  /// What the "working" step says while it waits. Cycled rather than a bare
  /// spinner because writing a week takes long enough to feel stuck.
  static const _progressLines = [
    'Reading your brief…',
    'Picking a split for your week…',
    'Choosing the lifts…',
    'Balancing sets and rest…',
    'Almost there…',
  ];
  int _progressIndex = 0;
  Timer? _progressTimer;

  @override
  void dispose() {
    _progressTimer?.cancel();
    _notes.dispose();
    _change.dispose();
    super.dispose();
  }

  WorkoutRepository get _repo => ref.read(workoutRepositoryProvider);

  Map<String, dynamic> get _brief => {
    'days': _days,
    'goal': _goal,
    'level': _level,
    'equipment': _place,
    'minutes': _minutes,
    if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
  };

  /* ---------------------------------------------------------- generating -- */

  Future<void> _generate({String? request}) async {
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
      final draft = await _repo.buildRoutines(
        brief: _brief,
        current: request == null ? null : _draft,
        request: request,
      );
      if (!mounted) return;
      setState(() {
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
        // one, the brief if the very first attempt failed.
        _step = _draft == null ? _Step.brief : _Step.preview;
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
      final plan = await _repo.applyBuiltRoutines(widget.plan.id, draft);
      if (mounted) Navigator.of(context).pop(plan);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _error = 'Could not save the plan. Try again.';
      });
    }
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
      _Step.brief => 'Build me a routine',
      _Step.working => 'Building your week',
      _Step.preview => 'Your week',
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
          // Never while a write is in flight — closing then would leave the
          // plan half-replaced with nothing on screen to say so.
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
      _Step.brief => _briefStep(c),
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

  Widget _briefStep(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Five quick answers and I will write the week for you. You can ask '
          'for changes before anything is saved.',
          style: AppText.bodySm.copyWith(color: c.textSubtle),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChipGroup(
          label: 'Days a week',
          options: const ['2', '3', '4', '5', '6'],
          value: '$_days',
          onChanged: (value) => setState(() => _days = int.parse(value)),
        ),
        _ChipGroup(
          label: 'Goal',
          options: const [
            'Build muscle',
            'Get stronger',
            'Lose fat',
            'Stay fit',
          ],
          value: _goal,
          onChanged: (value) => setState(() => _goal = value),
        ),
        _ChipGroup(
          label: 'Experience',
          options: const ['Beginner', 'Intermediate', 'Advanced'],
          value: _level,
          onChanged: (value) => setState(() => _level = value),
        ),
        _ChipGroup(
          label: 'Equipment',
          options: const ['Full gym', 'Home weights', 'Bodyweight'],
          value: _place,
          onChanged: (value) => setState(() => _place = value),
        ),
        _ChipGroup(
          label: 'Session length',
          options: const ['30 min', '45 min', '60 min', '75 min'],
          value: '$_minutes min',
          onChanged: (value) =>
              setState(() => _minutes = int.parse(value.split(' ').first)),
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _notes,
          minLines: 2,
          maxLines: 3,
          style: AppText.body.copyWith(color: c.text),
          cursorColor: c.primary,
          decoration: InputDecoration(
            hintText: 'Anything else? Sore knees, no deadlifts, love rowing…',
            hintStyle: AppText.bodySm.copyWith(color: c.textPlaceholder),
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide.none,
            ),
          ),
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
        // One chip per day. Tapping shows that day's exercises underneath
        // rather than stacking every routine into one long scroll.
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
        // The conversational half: the draft is never final until it is saved,
        // so changing it is a sentence rather than a form.
        TextField(
          controller: _change,
          textInputAction: TextInputAction.send,
          onSubmitted: (_) => _askForChange(),
          style: AppText.body.copyWith(color: c.text),
          cursorColor: c.primary,
          decoration: InputDecoration(
            hintText: 'Ask for a change — "swap the squats"',
            hintStyle: AppText.bodySm.copyWith(color: c.textPlaceholder),
            filled: true,
            fillColor: c.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide.none,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.arrow_upward_rounded, size: 18, color: c.primary),
              onPressed: _askForChange,
            ),
          ),
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
          routines == 0
              ? 'This writes the new week into ${widget.plan.name}.'
              : 'The ${routines == 1 ? 'routine' : '$routines routines'} in '
                    '${widget.plan.name}'
                    '${exercises > 0 ? ' and their $exercises '
                          '${exercises == 1 ? 'exercise' : 'exercises'}' : ''} '
                    'will be deleted and replaced by this week.',
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
      _Step.brief => Padding(
        padding: padding,
        child: PillButton(
          label: 'Build my week',
          radius: AppRadius.sm,
          height: 46,
          labelStyle: AppText.body,
          onPressed: _generate,
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
                onPressed: () => setState(() => _step = _Step.brief),
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

/// One question in the brief: a label and a row of single-choice chips.
class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.bodySm.copyWith(color: c.textSubtle)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in options)
                _Chip(
                  label: option,
                  selected: option == value,
                  onTap: () => onChanged(option),
                ),
            ],
          ),
        ],
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
            // The catalog match is worth showing: a filled dot has an
            // animation behind it, a hollow one is a name we could not place.
            color: exercise.catalogId == null ? Colors.transparent : c.primary,
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
