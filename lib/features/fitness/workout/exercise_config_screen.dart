import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/workout_models.dart';
import '../../../data/repositories/exercise_catalog_cache.dart';
import '../../../data/repositories/workout_repository.dart';
import 'exercise_history_sheet.dart';
import 'workout_widgets.dart';

/// What the config screen wrote, handed back so the list behind it can repaint
/// straight away instead of waiting on a refetch.
class ExerciseEdit {
  const ExerciseEdit(this.exercise, {this.deleted = false});

  /// The exercise as the API returned it — or, for a delete, the one that is
  /// now gone (only its id is read in that case).
  final RoutineExercise exercise;
  final bool deleted;
}

/// Add or edit one exercise inside a routine: its name, muscle, how it is
/// measured, its planned sets, rest, colour and notes.
///
/// Pops an [ExerciseEdit] when something was written; pops nothing on a plain
/// back.
class ExerciseConfigScreen extends ConsumerStatefulWidget {
  const ExerciseConfigScreen({
    super.key,
    required this.planId,
    required this.routineId,
    required this.exercise,
    this.catalogItem,
    this.isNew = false,
  });

  final String planId;
  final String routineId;
  final RoutineExercise exercise;

  /// Only present when the exercise was just picked from the catalog — it
  /// carries the animation's aspect ratio and the derived instructions.
  final ExerciseCatalogItem? catalogItem;
  final bool isNew;

  @override
  ConsumerState<ExerciseConfigScreen> createState() =>
      _ExerciseConfigScreenState();
}

/// The controllers behind one set row. Held per row rather than rebuilt from
/// the model each frame, so the caret does not jump while typing.
class _SetRow {
  _SetRow({String? first, String? second})
    : firstCtrl = TextEditingController(text: first ?? ''),
      secondCtrl = TextEditingController(text: second ?? '');

  final TextEditingController firstCtrl;
  final TextEditingController secondCtrl;

  void dispose() {
    firstCtrl.dispose();
    secondCtrl.dispose();
  }
}

class _ExerciseConfigScreenState extends ConsumerState<ExerciseConfigScreen> {
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.exercise.name,
  );
  late final TextEditingController _notesCtrl = TextEditingController(
    text: widget.exercise.notes ?? widget.catalogItem?.numberedInstructions ?? '',
  );

  late ExerciseMode _mode = widget.exercise.mode;
  late String _weightUnit = widget.exercise.weightUnit;
  late String? _muscle = widget.exercise.primaryMuscle?.isNotEmpty == true
      ? widget.exercise.primaryMuscle
      : widget.exercise.muscle;
  late String? _color = widget.exercise.color;
  late int _restSec = widget.exercise.restBetweenSetsSec;

  late List<_SetRow> _rows = _buildRows();

  List<MuscleCount> _muscles = const [];
  bool _saving = false;

  List<_SetRow> _buildRows() {
    final sets = widget.exercise.sets.isEmpty
        ? const [WorkoutSet()]
        : widget.exercise.sets;
    return [
      for (final s in sets)
        _SetRow(
          first: _mode == ExerciseMode.weights
              ? (s.reps?.toString() ?? '')
              : (s.durationSec?.toString() ?? ''),
          second: _mode == ExerciseMode.weights
              ? (s.weight == null ? '' : formatValue(s.weight))
              : (s.distance == null ? '' : formatValue(s.distance)),
        ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadMuscles();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// Off the locally cached catalog, warmed at app start — normally already
  /// there, so the dropdown never waits on a request.
  Future<void> _loadMuscles() async {
    final cache = ref.read(exerciseCatalogCacheProvider);
    await cache.ensureLoaded();
    // A failure leaves the list empty and the dropdown degrades to whatever
    // the exercise already carries.
    if (mounted) setState(() => _muscles = cache.muscles);
  }

  List<WorkoutSet> _collectSets() => [
    for (final row in _rows)
      if (_mode == ExerciseMode.weights)
        WorkoutSet(
          reps: int.tryParse(row.firstCtrl.text.trim()),
          weight: double.tryParse(row.secondCtrl.text.trim()),
        )
      else
        WorkoutSet(
          durationSec: int.tryParse(row.firstCtrl.text.trim()),
          distance: double.tryParse(row.secondCtrl.text.trim()),
        ),
  ];

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showAppSnack(context, 'Give the exercise a name', error: true);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(workoutRepositoryProvider);
    final payload = widget.exercise.copyWith(
      name: name,
      primaryMuscle: _muscle,
      mode: _mode,
      weightUnit: _weightUnit,
      sets: _collectSets(),
      restBetweenSetsSec: _restSec,
      color: _color,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    try {
      // The written exercise goes back with the pop: the plan screen puts it
      // straight into its list rather than refetching to find out what it
      // already knows.
      final saved = widget.isNew
          ? await repo.addExercise(widget.planId, widget.routineId, payload)
          : await repo.updateExercise(
              widget.planId,
              widget.routineId,
              widget.exercise.id,
              payload,
            );
      if (mounted) Navigator.of(context).pop(ExerciseEdit(saved));
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showAppSnack(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _delete() async {
    // Deleted from inside the confirm dialog: it holds itself open on
    // "Deleting…" so this screen is not torn down mid-call.
    final ok = await confirmDestructive(
      context,
      title: 'Delete exercise',
      message: '${widget.exercise.name} will be removed from this routine.',
      onConfirm: () => ref
          .read(workoutRepositoryProvider)
          .deleteExercise(widget.planId, widget.routineId, widget.exercise.id),
    );
    if (!ok || !mounted) return;
    Navigator.of(context).pop(ExerciseEdit(widget.exercise, deleted: true));
  }

  void _addSet() {
    setState(() {
      // A new set copies the one above it — the reference's tables repeat the
      // same numbers down the column, so pre-filling saves most of the typing.
      final last = _rows.isEmpty ? null : _rows.last;
      _rows = [
        ..._rows,
        _SetRow(first: last?.firstCtrl.text, second: last?.secondCtrl.text),
      ];
    });
  }

  void _removeSet(int index) {
    if (_rows.length <= 1) return;
    setState(() {
      final row = _rows[index];
      _rows = [..._rows]..removeAt(index);
      row.dispose();
    });
  }

  /// Switching mode re-labels the columns, so the numbers underneath them are
  /// no longer meaningful — the rows are rebuilt empty rather than silently
  /// reinterpreting reps as seconds.
  void _setMode(ExerciseMode mode) {
    if (mode == _mode) return;
    setState(() {
      _mode = mode;
      final count = _rows.length;
      for (final row in _rows) {
        row.dispose();
      }
      _rows = [for (var i = 0; i < count; i++) _SetRow()];
    });
  }

  Future<void> _pickMuscle() async {
    final choice = await showFitnessSheet<String>(
      context: context,
      heightFactor: 0.5,
      builder: (sheetContext) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in _muscles)
              SheetActionRow(
                label: m.muscle,
                onTap: () => Navigator.of(sheetContext).pop(m.muscle),
              ),
          ],
        ),
      ),
    );
    if (choice != null && mounted) setState(() => _muscle = choice);
  }

  Future<void> _pickRest() async {
    final seconds = await showDurationSheet(
      context,
      title: 'Rest between sets',
      initialSeconds: _restSec,
    );
    if (seconds != null && mounted) setState(() => _restSec = seconds);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final aspect = widget.catalogItem?.aspectRatio ?? 1;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  FitnessIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    iconSize: 16,
                    background: Colors.transparent,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  if (!widget.isNew) ...[
                    FitnessPill(
                      onTap: _saving ? null : _delete,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: c.negative,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Delete',
                            style: AppText.button.copyWith(color: c.negative),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  FitnessPill(
                    onTap: _saving ? null : _save,
                    background: c.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_saving)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.textOnPrimary,
                            ),
                          )
                        else
                          Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: c.textOnPrimary,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _saving ? 'Saving…' : 'Done',
                          style: AppText.button.copyWith(color: c.textOnPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl4,
                ),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: ExerciseAnimationView(
                          catalogId: widget.exercise.catalogId,
                          aspectRatio: aspect,
                          radius: AppRadius.sm,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 42,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              // Centered rather than left to fill the box: a
                              // borderless TextField stretches to the height it
                              // is given and lays its text out from the top,
                              // which sat the name high in the pill while the
                              // muscle row beside it (a Row) read centered.
                              child: Center(
                                child: TextField(
                                  controller: _nameCtrl,
                                  style: AppText.body.copyWith(color: c.text),
                                  cursorColor: c.primary,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    hintText: 'Exercise name',
                                    hintStyle: AppText.body.copyWith(
                                      color: c.textPlaceholder,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            InkWell(
                              onTap: _pickMuscle,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: c.surface,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _muscle?.isNotEmpty == true
                                            ? _muscle!
                                            : 'Select muscle',
                                        style: AppText.body.copyWith(
                                          color: _muscle?.isNotEmpty == true
                                              ? c.text
                                              : c.textPlaceholder,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: c.textSubtle,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!widget.isNew)
                        FitnessIconButton(
                          icon: Icons.bar_chart_rounded,
                          onTap: () => showExerciseHistory(
                            context,
                            name: widget.exercise.name,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _ModeToggle(mode: _mode, onChanged: _setMode),
                  const SizedBox(height: AppSpacing.xl),
                  _SetTableHeader(
                    mode: _mode,
                    weightUnit: _weightUnit,
                    onToggleUnit: () => setState(
                      () => _weightUnit = _weightUnit == 'kg' ? 'lb' : 'kg',
                    ),
                  ),
                  for (var i = 0; i < _rows.length; i++)
                    _SetRowFields(
                      index: i,
                      row: _rows[i],
                      canRemove: _rows.length > 1,
                      onRemove: () => _removeSet(i),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      InkWell(
                        onTap: _addSet,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AppRadius.pill,
                            ),
                            border: Border.all(color: c.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_circle_rounded,
                                size: 18,
                                color: c.primary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Add set',
                                style: AppText.button.copyWith(color: c.text),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _pickRest,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 18,
                              color: _restSec > 0 ? c.primary : c.textSecondary,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Rest: ${formatRest(_restSec)}',
                              style: AppText.button.copyWith(
                                color: _restSec > 0
                                    ? c.primary
                                    : c.textSecondary,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: _restSec > 0
                                  ? c.primary
                                  : c.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Exercise color',
                    style: AppText.subtitle.copyWith(
                      color: c.textSubtle,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final swatch in kExerciseColors)
                        _Swatch(
                          hex: swatch,
                          selected: swatch == _color,
                          onTap: () => setState(() => _color = swatch),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Notes',
                    style: AppText.subtitle.copyWith(
                      color: c.textSubtle,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: null,
                    minLines: 4,
                    style: AppText.body.copyWith(color: c.textSecondary),
                    cursorColor: c.primary,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: c.inputBackground,
                      hintText: 'How to perform this exercise',
                      hintStyle: AppText.body.copyWith(color: c.textPlaceholder),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: c.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: c.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        borderSide: BorderSide(color: c.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ----------------------------------------------------------------- bits -- */

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final ExerciseMode mode;
  final ValueChanged<ExerciseMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget segment(String label, ExerciseMode value) {
      final selected = value == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? c.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              label,
              style: AppText.bodySm.copyWith(
                color: selected ? c.textOnPrimary : c.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          segment('Weights / Bodyweight', ExerciseMode.weights),
          segment('Time / Distance', ExerciseMode.time),
        ],
      ),
    );
  }
}

class _SetTableHeader extends StatelessWidget {
  const _SetTableHeader({
    required this.mode,
    required this.weightUnit,
    required this.onToggleUnit,
  });

  final ExerciseMode mode;
  final String weightUnit;
  final VoidCallback onToggleUnit;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = AppText.bodyMedium.copyWith(color: c.text);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('#', style: style)),
          Expanded(
            child: Text(
              mode == ExerciseMode.weights ? 'Reps' : 'Time (s)',
              style: style,
            ),
          ),
          Expanded(
            child: mode == ExerciseMode.weights
                ? InkWell(
                    onTap: onToggleUnit,
                    child: Row(
                      children: [
                        Text(weightUnit.toUpperCase(), style: style),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: c.textSubtle,
                        ),
                      ],
                    ),
                  )
                : Text('Distance', style: style),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _SetRowFields extends StatelessWidget {
  const _SetRowFields({
    required this.index,
    required this.row,
    required this.canRemove,
    required this.onRemove,
  });

  final int index;
  final _SetRow row;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget field(TextEditingController controller) => TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      textAlign: TextAlign.center,
      style: AppText.bodyMedium.copyWith(color: c.text),
      cursorColor: c.primary,
      decoration: InputDecoration(
        isDense: true,
        hintText: '-',
        hintStyle: AppText.bodyMedium.copyWith(color: c.textPlaceholder),
        filled: true,
        fillColor: c.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
          borderSide: BorderSide.none,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              '${index + 1}',
              style: AppText.bodyMedium.copyWith(color: c.textSecondary),
            ),
          ),
          Expanded(child: field(row.firstCtrl)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: field(row.secondCtrl)),
          SizedBox(
            width: 32,
            child: canRemove
                ? IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 18,
                      color: c.textSubtle,
                    ),
                    onPressed: onRemove,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.hex, required this.selected, required this.onTap});

  final String? hex;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = parseSwatch(hex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: color ?? c.surfaceMuted,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? c.text : c.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: color == null
            ? Icon(Icons.check_rounded, size: 18, color: c.textSubtle)
            : null,
      ),
    );
  }
}
