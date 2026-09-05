import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/workout_models.dart';
import '../../../data/repositories/workout_repository.dart';
import 'workout_widgets.dart';

/// The screen between "▶" and the first set: set the rest between exercises,
/// drop anything you are not doing today, and put the rest in order.
///
/// Both the order and the removals go out in one `reorder-routine-exercises`
/// call — that endpoint deletes by omission, which is exactly the semantics
/// this screen has.
class WorkoutPrestartScreen extends ConsumerStatefulWidget {
  const WorkoutPrestartScreen({
    super.key,
    required this.planId,
    required this.routine,
    this.autoStart = true,
  });

  final String planId;
  final Routine routine;

  /// True when the user pressed ▶ (save, then start), and the started
  /// [WorkoutSession] is what pops. False when they came in from "Reorder &
  /// remove exercises", where saving is the whole errand and the saved
  /// [Routine] pops instead.
  final bool autoStart;

  @override
  ConsumerState<WorkoutPrestartScreen> createState() =>
      _WorkoutPrestartScreenState();
}

class _WorkoutPrestartScreenState extends ConsumerState<WorkoutPrestartScreen> {
  late List<RoutineExercise> _exercises = List.of(widget.routine.exercises);
  late int _restSec = widget.routine.restBetweenExercisesSec;

  /// 0–10 minutes and 0–59 seconds. The wheels scroll past both ends and wrap,
  /// so these are the counts an index is folded back into, not a hard stop.
  static const _minuteCount = 11;
  static const _secondCount = 60;

  late final FixedExtentScrollController _minCtrl = FixedExtentScrollController(
    initialItem: (_restSec ~/ 60).clamp(0, _minuteCount - 1),
  );
  late final FixedExtentScrollController _secCtrl = FixedExtentScrollController(
    initialItem: _restSec % _secondCount,
  );

  bool _busy = false;

  @override
  void dispose() {
    _minCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  void _syncRest() {
    // The wheels loop, so a raw index can be anything, negatives included —
    // Dart's `%` folds it back into range either way.
    final minutes = _minCtrl.selectedItem % _minuteCount;
    final seconds = _secCtrl.selectedItem % _secondCount;
    _restSec = minutes * 60 + seconds;
  }

  Future<void> _submit() async {
    if (_exercises.isEmpty) {
      showAppSnack(context, 'Keep at least one exercise', error: true);
      return;
    }

    _syncRest();
    setState(() => _busy = true);
    final repo = ref.read(workoutRepositoryProvider);

    try {
      await repo.reorderExercises(
        widget.planId,
        widget.routine.id,
        [for (final e in _exercises) e.id],
        restBetweenExercisesSec: _restSec,
      );

      if (!widget.autoStart) {
        // The routine as it now stands goes back with the pop, so the list
        // behind repaints in the new order without a refetch first.
        if (mounted) {
          Navigator.of(context).pop(
            widget.routine.copyWith(
              exercises: _exercises,
              restBetweenExercisesSec: _restSec,
            ),
          );
        }
        return;
      }

      final session = await repo.startSession(
        planId: widget.planId,
        routineId: widget.routine.id,
        restBetweenExercisesSec: _restSec,
      );
      if (!mounted) return;

      // The started session is handed back rather than pushed from here: the
      // plan screen opens the workout itself, so its `await` is still standing
      // when the workout ends — and this screen is gone by then either way, so
      // backing out of a running workout still lands on the plan.
      Navigator.of(context).pop(session);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showAppSnack(context, e.toString(), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

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
                  FitnessPill(
                    onTap: _busy ? null : _submit,
                    background: c.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_busy)
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
                            widget.autoStart
                                ? Icons.play_arrow_rounded
                                : Icons.check_rounded,
                            size: 18,
                            color: c.textOnPrimary,
                          ),
                        const SizedBox(width: 6),
                        Text(
                          _busy
                              ? (widget.autoStart ? 'Starting…' : 'Saving…')
                              : (widget.autoStart ? 'Start' : 'Save'),
                          style: AppText.button.copyWith(
                            color: c.textOnPrimary,
                          ),
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
                  Text(
                    'Rest Between Exercises',
                    // bodyLargeRegular, not subtitle.copyWith(w400) —
                    // google_fonts drops a weight override on a resolved style.
                    style: AppText.bodyLargeRegular.copyWith(
                      color: c.textSubtle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    // Three rows: the selected one and a neighbour either side.
                    // At 36 per item and a 1.1 squeeze, 140 was showing five.
                    height: 3 * 36 / 1.1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IgnorePointer(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: c.surfaceElevated,
                              borderRadius: BorderRadius.circular(
                                AppRadius.sm,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _wheel(
                                controller: _minCtrl,
                                count: _minuteCount,
                                unit: 'min',
                              ),
                            ),
                            Expanded(
                              child: _wheel(
                                controller: _secCtrl,
                                count: _secondCount,
                                unit: 'sec',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Reorder & Remove Exercises',
                    style: AppText.bodyLargeRegular.copyWith(
                      color: c.textSubtle,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: false,
                    itemCount: _exercises.length,
                    onReorder: (oldIndex, newIndex) => setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      _exercises.insert(
                        newIndex,
                        _exercises.removeAt(oldIndex),
                      );
                    }),
                    itemBuilder: (context, index) {
                      final exercise = _exercises[index];
                      return Padding(
                        key: ValueKey(exercise.id),
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.delete_rounded,
                                size: 20,
                                color: c.negative,
                              ),
                              onPressed: () => setState(
                                () => _exercises = [..._exercises]
                                  ..removeAt(index),
                              ),
                            ),
                            Expanded(
                              child: Material(
                                color: c.surface,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    AppSpacing.md,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ExerciseThumb(
                                        catalogId: exercise.catalogId,
                                        size: 72,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppText.bodyMedium
                                                  .copyWith(color: c.text),
                                            ),
                                            if (exercise.muscleLabel
                                                .isNotEmpty)
                                              Text(
                                                exercise.muscleLabel,
                                                style: AppText.bodySm
                                                    .copyWith(
                                                      color: c.textSecondary,
                                                    ),
                                              ),
                                            const SizedBox(
                                              height: AppSpacing.xs,
                                            ),
                                            Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: 'Rest time - ',
                                                    style: AppText.bodySm
                                                        .copyWith(
                                                          color:
                                                              c.textSubtle,
                                                        ),
                                                  ),
                                                  TextSpan(
                                                    text: formatRest(
                                                      exercise
                                                          .restBetweenSetsSec,
                                                    ),
                                                    style: AppText.bodyMedium
                                                        .copyWith(
                                                          color:
                                                              c.textSecondary,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ReorderableDragStartListener(
                              index: index,
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  color: c.textSubtle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// An endless wheel: 10 min rolls on to 0, and 0 sec back to 59, instead of
  /// stopping dead at either end.
  ///
  /// [CupertinoPicker] has no looping mode, so the row count is left open
  /// (`childCount: null`, its default) and the index — which then runs
  /// negative above zero — is folded back into range for the label.
  Widget _wheel({
    required FixedExtentScrollController controller,
    required int count,
    required String unit,
  }) {
    final c = context.colors;
    return CupertinoPicker.builder(
      scrollController: controller,
      itemExtent: 36,
      squeeze: 1.1,
      onSelectedItemChanged: (_) => _syncRest(),
      selectionOverlay: const SizedBox.shrink(),
      itemBuilder: (context, index) => Center(
        child: Text(
          '${index % count} $unit',
          style: AppText.bodyMedium.copyWith(color: c.text),
        ),
      ),
    );
  }
}
