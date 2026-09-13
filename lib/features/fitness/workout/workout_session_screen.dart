import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/workout_sounds.dart';
import '../../../core/constants/env.dart';
import '../../../core/notifications/local_notifications.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/workout_models.dart';
import '../../../data/repositories/workout_repository.dart';
import 'workout_summary_screen.dart';
import 'workout_widgets.dart';

/// The live workout: one exercise at a time, its sets underneath, and the
/// clock at the bottom.
///
/// The session document is the source of truth and every tick of progress is
/// written through immediately — a workout that survives the app being killed
/// is the whole point of storing sessions server-side.
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({super.key, required this.session});

  final WorkoutSession session;

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen>
    with WidgetsBindingObserver {
  late WorkoutSession _session = widget.session;

  /// Wall-clock anchors so the timers keep running while the app is
  /// backgrounded: the OS suspends [Timer] callbacks while the app is away,
  /// so every tick recomputes from these instead of counting ticks.
  late int _elapsedBase;
  late DateTime _bootedAt;
  late DateTime _setStartedAt;
  DateTime? _restEndsAt;

  /// Whole-workout clock: base plus wall-clock time since this screen booted.
  int get _elapsed =>
      (_elapsedBase + DateTime.now().difference(_bootedAt).inSeconds)
          .clamp(0, 86400);

  /// Set clock: wall-clock time since the current set started, held at zero
  /// through the rest gap (the bottom bar shows the countdown instead).
  int get _setElapsed {
    if (_restEndsAt != null) return 0;
    return DateTime.now().difference(_setStartedAt).inSeconds.clamp(0, 86400);
  }

  /// Rest countdown, non-null only while it is running. Ceiled so the last
  /// visible second is 1, then 0 means it just ended.
  int? get _restRemaining {
    final endsAt = _restEndsAt;
    if (endsAt == null) return null;
    final ms = endsAt.difference(DateTime.now()).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / 1000).ceil();
  }

  Timer? _ticker;

  /// The exercise the set clock, rest gap, and Done button belong to.
  int _activeIndex = 0;

  /// The exercise on screen. The step rail only previews — it never touches
  /// the timer. The timer moves over only when the user starts the previewed
  /// exercise (Start) or the flow advances past a completed set (Done).
  int _viewIndex = 0;

  /// True while previewing an exercise that isn't the running one: the bottom
  /// bar then offers Start instead of Done.
  bool get _previewing => _viewIndex != _activeIndex;

  bool _notesOpen = false;
  bool _finishing = false;

  int _initialElapsed() {
    final started = widget.session.startedAt;
    if (started == null) return widget.session.durationSec;
    return DateTime.now().difference(started).inSeconds.clamp(0, 86400);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeIndex = _viewIndex = _firstUnfinishedExercise();
    final now = DateTime.now();
    _bootedAt = now;
    _setStartedAt = now;
    _elapsedBase = _initialElapsed();
    _ticker = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  WorkoutSounds get _sounds => ref.read(workoutSoundsProvider);

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    unawaited(LocalNotifications.instance.cancelRestOver());
    super.dispose();
  }

  /// Recomputed on every resume: the wall-clock getters already hold the
  /// right values, this just repaints with them.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) setState(() {});
  }

  void _tick(Timer _) {
    if (!mounted) return;
    final rest = _restRemaining;
    if (rest != null && rest <= 0) {
      // The one cue the user is most likely to be looking away for — and it
      // still fires if the rest ended while the app was backgrounded, on the
      // first tick after coming back.
      _endRest();
    }
    // The clocks read off the wall clock, so a tick only repaints — even a
    // long background gap lands on the right values on the first tick back.
    setState(() {});
  }

  /// Rest finished: clear the countdown, restart the set clock, beep, and
  /// drop the OS-level backup alert (it just fired, or is no longer needed).
  void _endRest() {
    _restEndsAt = null;
    _setStartedAt = DateTime.now();
    _sounds.playRestOver();
    unawaited(LocalNotifications.instance.cancelRestOver());
  }

  /// Starts a rest of [seconds], arming the OS-level backup alert so the user
  /// is still cued if the app is backgrounded; null/zero means no rest.
  void _startRest(int seconds) {
    if (seconds <= 0) {
      _restEndsAt = null;
      return;
    }
    final endsAt = DateTime.now().add(Duration(seconds: seconds));
    _restEndsAt = endsAt;
    unawaited(LocalNotifications.instance.scheduleRestOver(endsAt));
  }

  /// Rest cut short (skipped, or Start pressed on another exercise): clear the
  /// countdown and drop the backup alert so it cannot fire late.
  void _clearRest() {
    _restEndsAt = null;
    _setStartedAt = DateTime.now();
    unawaited(LocalNotifications.instance.cancelRestOver());
  }

  WorkoutRepository get _repo => ref.read(workoutRepositoryProvider);

  int _firstUnfinishedExercise() {
    for (var i = 0; i < widget.session.exercises.length; i++) {
      if (!widget.session.exercises[i].isDone) return i;
    }
    return 0;
  }

  SessionExercise? get _exercise => _session.exercises.isEmpty
      ? null
      : _session.exercises[_viewIndex.clamp(
          0,
          _session.exercises.length - 1,
        )];

  SessionExercise? _exerciseAt(int index) => _session.exercises.isEmpty
      ? null
      : _session.exercises[index.clamp(0, _session.exercises.length - 1)];

  /// The first set not yet ticked off in [exercise]: the one Start/Done acts on.
  int _firstOpenSet(SessionExercise? exercise) {
    final sets = exercise?.sets ?? const <WorkoutSet>[];
    for (var i = 0; i < sets.length; i++) {
      if (!sets[i].completed) return i;
    }
    return sets.length - 1;
  }

  /// The set highlighted in the on-screen (viewed) exercise.
  int get _currentSetIndex => _firstOpenSet(_exercise);

  /* ------------------------------------------------------ local writes -- */

  /// Rebuilds the session with one set replaced. The API answers with the
  /// whole session on some calls and nothing on others, so the screen keeps
  /// its own copy rather than depending on which.
  void _replaceSet(int exerciseIndex, int setIndex, WorkoutSet set) {
    final exercises = [..._session.exercises];
    final exercise = exercises[exerciseIndex];
    final sets = [...exercise.sets]..[setIndex] = set;
    exercises[exerciseIndex] = SessionExercise(
      id: exercise.id,
      name: exercise.name,
      catalogId: exercise.catalogId,
      gif: exercise.gif,
      customExercise: exercise.customExercise,
      muscle: exercise.muscle,
      primaryMuscle: exercise.primaryMuscle,
      equipment: exercise.equipment,
      mode: exercise.mode,
      weightUnit: exercise.weightUnit,
      color: exercise.color,
      notes: exercise.notes,
      restBetweenSetsSec: exercise.restBetweenSetsSec,
      sets: sets,
      order: exercise.order,
    );
    setState(() => _session = _copyWithExercises(exercises));
  }

  WorkoutSession _copyWithExercises(List<SessionExercise> exercises) =>
      WorkoutSession(
        id: _session.id,
        planId: _session.planId,
        routineId: _session.routineId,
        planName: _session.planName,
        routineName: _session.routineName,
        status: _session.status,
        startedAt: _session.startedAt,
        finishedAt: _session.finishedAt,
        durationSec: _session.durationSec,
        restBetweenExercisesSec: _session.restBetweenExercisesSec,
        exercises: exercises,
      );

  /* ---------------------------------------------------------- mutation -- */

  Future<void> _editValue(int setIndex, {required bool firstField}) async {
    final exercise = _exercise;
    if (exercise == null) return;
    final viewed = _viewIndex.clamp(0, _session.exercises.length - 1);
    final set = exercise.sets[setIndex];
    final timed = exercise.mode == ExerciseMode.time;

    final label = firstField
        ? (timed ? 'Seconds' : 'Reps')
        : (timed ? 'Distance' : exercise.weightUnit.toUpperCase());
    final current = firstField
        ? (timed ? set.durationSec : set.reps)
        : (timed ? set.distance : set.weight);

    final value = await _promptNumber(
      label: label,
      initial: current == null ? '' : formatValue(current),
    );
    if (value == null || !mounted) return;

    final parsed = value.isEmpty ? null : double.tryParse(value);
    final updated = firstField
        ? (timed
              ? set.copyWith(durationSec: parsed?.round())
              : set.copyWith(reps: parsed?.round()))
        : (timed
              ? set.copyWith(distance: parsed)
              : set.copyWith(weight: parsed));

    _replaceSet(viewed, setIndex, updated);

    try {
      await _repo.updateSessionSet(
        _session.id,
        exercise.id,
        set.id,
        // Only the edited field is sent; the rest keep the sentinel so the
        // sparse body leaves them alone.
        reps: firstField && !timed ? parsed?.round() : kUnsetSetValue,
        durationSec: firstField && timed ? parsed?.round() : kUnsetSetValue,
        weight: !firstField && !timed ? parsed : kUnsetSetValue,
        distance: !firstField && timed ? parsed : kUnsetSetValue,
      );
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    }
  }

  Future<String?> _promptNumber({
    required String label,
    required String initial,
  }) async {
    final c = context.colors;
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text(
          label,
          style: AppText.bodyLargeRegular.copyWith(color: c.text),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: AppText.bodyLargeRegular.copyWith(color: c.text),
          cursorColor: c.primary,
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
          decoration: InputDecoration(
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: c.primary, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppText.button.copyWith(color: c.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(
              'OK',
              style: AppText.button.copyWith(color: c.primary),
            ),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _completeSet() async {
    // Acts on the RUNNING exercise, not the viewed one: previewing never
    // moves the timer, so Done always belongs to the active set.
    final active = _activeIndex.clamp(0, _session.exercises.length - 1);
    final exercise = _exerciseAt(active);
    if (exercise == null || exercise.sets.isEmpty) return;

    final index = _firstOpenSet(exercise);
    final set = exercise.sets[index];
    _replaceSet(active, index, set.copyWith(completed: true));

    try {
      await _repo.updateSessionSet(
        _session.id,
        exercise.id,
        set.id,
        completed: true,
      );
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    }
    if (!mounted) return;

    // Done starts playing here: the timer (and the view) move with it.
    final wasLastSet = index >= exercise.sets.length - 1;
    final isLastExercise = active >= _session.exercises.length - 1;

    if (wasLastSet && isLastExercise) {
      await _finish();
      return;
    }

    setState(() {
      _activeIndex = wasLastSet ? active + 1 : active;
      _viewIndex = _activeIndex;
      _setStartedAt = DateTime.now();
      if (wasLastSet) {
        _startRest(_session.restBetweenExercisesSec);
        _notesOpen = false;
      } else {
        _startRest(exercise.restBetweenSetsSec);
      }
    });
  }

  /// The user pressed Start on a previewed exercise: the running timer moves
  /// over to it. Previewing alone (step-rail taps) never calls this.
  void _startExercise() {
    setState(() {
      _activeIndex = _viewIndex.clamp(0, _session.exercises.length - 1);
      _clearRest();
      _notesOpen = false;
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      final result = await _repo.finishSession(
        _session.id,
        durationSec: _elapsed,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              FitnessTheme(child: WorkoutSummaryScreen(result: result)),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _finishing = false);
        showAppSnack(context, e.toString(), error: true);
      }
    }
  }

  Future<void> _abandon() async {
    // Ended from inside the confirm dialog, which sits on "Ending…" until the
    // API answers — the old flow closed the dialog, then left the workout
    // screen up while the call was still running, and popped it either way.
    final ok = await confirmDestructive(
      context,
      title: 'End workout',
      message:
          'The sets you have already ticked off are kept, but the workout '
          'will be marked as abandoned.',
      confirmLabel: 'End',
      pendingLabel: 'Ending…',
      onConfirm: () => _repo.finishSession(
        _session.id,
        durationSec: _elapsed,
        abandoned: true,
      ),
    );
    if (!ok || !mounted) return;
    Navigator.of(context).pop(true);
  }

  /* ------------------------------------------------------------- build -- */

  /// What sits under the exercise name: how to do it where the movement came
  /// with instructions, and the muscle it works where it did not.
  String _blurb(SessionExercise exercise) {
    final notes = (exercise.notes ?? '').trim();
    return notes.isEmpty ? exercise.muscleLabel : notes;
  }

  /// The exercise's demo gif URL: the stored path when it has one.
  String? _exerciseGif(SessionExercise exercise) {
    final path = exercise.gif;
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    final base = Env.serverRoot;
    return '$base${path.startsWith('/') ? path.substring(1) : path}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final exercise = _exercise;
    // Global rest state: belongs to the RUNNING exercise and keeps counting
    // while the user previews another one.
    final resting = _restRemaining != null;
    // Row highlight only follows the rest when viewing the running exercise.
    final viewingRunning = !_previewing;

    return PopScope(
      // Backing out mid-workout would silently leave an active session behind,
      // so the ✗ button (which asks) is the only way out.
      canPop: false,
      child: Scaffold(
        backgroundColor: c.background,
        body: SafeArea(
          child: exercise == null
              ? const Center(child: Text('This workout has no exercises.'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          FitnessIconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            iconSize: 16,
                            background: Colors.transparent,
                            // Leaves the workout running rather than ending
                            // it — ▶ on the plan screen then offers to carry
                            // on with it. Ending is the ✗ below.
                            onTap: () => Navigator.of(context).pop(true),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                formatClock(_elapsed),
                                style: AppText.screenTitle.copyWith(
                                  color: c.text,
                                ),
                              ),
                            ),
                          ),
                          // Balances the back button so the clock stays on the
                          // screen's centre line, not the row's.
                          const SizedBox(width: 44),
                        ],
                      ),
                    ),
                    _stepRail(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.xl2,
                        ),
                        children: [
                          ExerciseAnimationView(
                            gifUrl: _exerciseGif(exercise),
                            // Landscape rather than the default square: the
                            // figures are drawn wide, so a square panel was
                            // mostly empty white and pushed the sets off the
                            // first screen.
                            aspectRatio: 16 / 9,
                            radius: AppRadius.md,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            exercise.name,
                            style: AppText.subtitle.copyWith(color: c.text),
                          ),
                          if (_blurb(exercise).isNotEmpty)
                            _ExerciseNote(
                              text: _blurb(exercise),
                              expanded: _notesOpen,
                              onToggle: () =>
                                  setState(() => _notesOpen = !_notesOpen),
                            ),
                          const SizedBox(height: AppSpacing.lg),
                          for (var i = 0; i < exercise.sets.length; i++)
                            _SessionSetRow(
                              index: i,
                              set: exercise.sets[i],
                              exercise: exercise,
                              isCurrent: i == _currentSetIndex,
                              // Amber rest state only on the running exercise —
                              // a preview must not inherit its highlight.
                              resting: resting && viewingRunning,
                              onEditFirst: () =>
                                  _editValue(i, firstField: true),
                              onEditSecond: () =>
                                  _editValue(i, firstField: false),
                            ),
                        ],
                      ),
                    ),
                    _bottomBar(resting),
                  ],
                ),
        ),
      ),
    );
  }

  /// One step per exercise, spread across the full width while they fit and
  /// scrolling horizontally once they no longer do.
  Widget _stepRail() {
    const size = 32.0;
    const minGap = 6.0;
    const railPadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

    return SizedBox(
      height: 44,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = _session.exercises.length;
          final room = constraints.maxWidth - railPadding.horizontal;
          // Even spacing is the point, so the whole rail switches to scrolling
          // the moment one gap would have to go under 6.
          final fits =
              count < 2 || (room - size * count) / (count - 1) >= minGap;

          if (fits) {
            return Padding(
              padding: railPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < count; i++) _stepChip(i, size),
                ],
              ),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: railPadding,
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(width: minGap),
            itemBuilder: (context, index) =>
                Center(child: _stepChip(index, size)),
          );
        },
      ),
    );
  }

  Widget _stepChip(int index, double size) {
    final c = context.colors;
    final isCurrent = index == _viewIndex;
    final running = index == _activeIndex;
    final done = _session.exercises[index].isDone;

    return GestureDetector(
      // Preview only: shows the exercise without touching the running timer.
      // The timer moves over on Start (_startExercise) or Done (_completeSet).
      onTap: () => setState(() {
        _viewIndex = index;
        _notesOpen = false;
      }),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isCurrent
              ? c.primary
              : (running ? c.primarySoftStrong : c.surface),
          // Ring around the exercise the timer belongs to while previewing
          // another one, so the running set stays visible on the rail.
          border: (!isCurrent && running)
              ? Border.all(color: c.primary, width: 1.5)
              : null,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${index + 1}',
          style: AppText.caption.copyWith(
            color: isCurrent
                ? c.textOnPrimary
                : (done ? c.text : c.textSecondary),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(bool resting) {
    final c = context.colors;
    // Previewing: the bar stays neutral and offers Start — the running timer
    // (and its rest gap) is untouched until the user starts this exercise.
    if (_previewing) {
      return Container(
        color: c.surface,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            FitnessIconButton(
              icon: Icons.close_rounded,
              size: 40,
              iconSize: 18,
              background: c.surfaceElevated,
              onTap: _abandon,
            ),
            Expanded(
              child: Center(
                child: Text(
                  'Previewing',
                  style: AppText.caption.copyWith(color: c.textSecondary),
                ),
              ),
            ),
            FitnessPill(
              onTap: _finishing ? null : _startExercise,
              background: c.primary,
              radius: AppRadius.sm,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 16,
                    color: c.textOnPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Start',
                    style: AppText.body.copyWith(color: c.textOnPrimary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final tint = resting ? c.warning : c.primary;
    // c.textOnPrimary is tuned for the blue Done pill; the amber Skip pill
    // needs a dark label instead to stay readable against that lighter tint.
    final tintText = resting ? const Color(0xFF06131F) : c.textOnPrimary;

    return Container(
      // A band of its own, so the controls read as a bar rather than as more
      // of the list that scrolls above them.
      color: c.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          FitnessIconButton(
            icon: Icons.close_rounded,
            size: 40,
            iconSize: 18,
            // The bar is c.surface now, so the button needs the next step up
            // to stay visible against it.
            background: c.surfaceElevated,
            onTap: _abandon,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (resting)
                    Text(
                      'Rest',
                      style: AppText.caption.copyWith(color: c.warning),
                    ),
                  Text(
                    resting
                        ? formatClock(_restRemaining ?? 0)
                        : formatClock(_setElapsed),
                    style: AppText.titleRegular.copyWith(
                      color: resting ? c.warning : c.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          FitnessPill(
            onTap: _finishing
                ? null
                : (resting
                      ? () => setState(_clearRest)
                      : _completeSet),
            background: tint,
            radius: AppRadius.sm,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: 10,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  resting ? Icons.skip_next_rounded : Icons.check_rounded,
                  size: 16,
                  color: tintText,
                ),
                const SizedBox(width: 6),
                Text(
                  _finishing ? 'Finishing…' : (resting ? 'Skip' : 'Done'),
                  style: AppText.body.copyWith(color: tintText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------------------------------------------- bits -- */

/// The line under the exercise name — its instructions, or the muscle it works
/// when there are none.
///
/// Long text is cut at three lines with a chevron under it to open the rest.
/// The chevron only appears when there is something behind it, so a two-word
/// muscle label does not get a control that does nothing.
class _ExerciseNote extends StatelessWidget {
  const _ExerciseNote({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  static const _maxLines = 3;

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = AppText.bodySm.copyWith(color: c.textSubtle);

    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: _maxLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final clipped = painter.didExceedMaxLines;
        painter.dispose();

        return GestureDetector(
          onTap: clipped ? onToggle : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                maxLines: expanded && clipped ? null : _maxLines,
                overflow: expanded && clipped
                    ? TextOverflow.clip
                    : TextOverflow.ellipsis,
                style: style,
              ),
              if (clipped)
                Center(
                  child: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: c.textSecondary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SessionSetRow extends StatelessWidget {
  const _SessionSetRow({
    required this.index,
    required this.set,
    required this.exercise,
    required this.isCurrent,
    required this.resting,
    required this.onEditFirst,
    required this.onEditSecond,
  });

  final int index;
  final WorkoutSet set;
  final SessionExercise exercise;
  final bool isCurrent;
  final bool resting;
  final VoidCallback onEditFirst;
  final VoidCallback onEditSecond;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final timed = exercise.mode == ExerciseMode.time;
    // The current row owns the accent: green while working, amber while the
    // rest clock is running.
    final accent = isCurrent ? (resting ? c.warning : c.primary) : null;

    Widget box(String value, String label, VoidCallback onTap) => GestureDetector(
      onTap: isCurrent ? onTap : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 40,
            margin: const EdgeInsets.only(left: AppSpacing.sm),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isCurrent ? c.surfaceElevated : c.surface,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(
              value,
              style: AppText.bodyLargeRegular.copyWith(color: c.text),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(label, style: AppText.body.copyWith(color: c.textSubtle)),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: accent ?? Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: set.completed ? c.primary : c.surface,
                shape: BoxShape.circle,
              ),
              child: set.completed
                  ? Icon(Icons.check_rounded, size: 14, color: c.textOnPrimary)
                  : Text(
                      '${index + 1}',
                      style: AppText.bodySm.copyWith(color: c.textSecondary),
                    ),
            ),
            box(
              timed
                  ? formatValue(set.durationSec)
                  : formatValue(set.reps),
              timed ? 'Sec' : 'Reps',
              onEditFirst,
            ),
            const SizedBox(width: AppSpacing.lg),
            box(
              timed ? formatValue(set.distance) : formatValue(set.weight),
              timed ? 'Dist' : exercise.weightUnit.toUpperCase(),
              onEditSecond,
            ),
            if (resting && isCurrent)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: Icon(Icons.timer_rounded, size: 18, color: c.warning),
              ),
          ],
        ),
      ),
    );
  }
}
