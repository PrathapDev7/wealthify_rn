import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/workout_models.dart';
import '../../../data/repositories/exercise_animation_cache.dart';
import '../../../data/repositories/workout_repository.dart';
import 'build_routine_dialog.dart';
import 'exercise_config_screen.dart';
import 'exercise_picker_screen.dart';
import 'workout_prestart_screen.dart';
import 'workout_session_screen.dart';
import 'workout_sheets.dart';
import 'workout_widgets.dart';

/// The plan `⋮` menu's entries. Each one only reports the choice — the screen
/// owns the mutation, so the menu never has to know how to refresh behind it.
enum _PlanMenuAction { build, rename, duplicate, manageRoutines, delete }

/// The Workouts tab: one plan, its routines across the top, and the exercises
/// of the selected routine below.
///
/// Everything under a plan arrives in a single `get-workout-plan` call, so the
/// routine tabs switch without a round trip. Writes are painted from what the
/// API answered with and reconciled in the background — see [_applyPlan].
class WorkoutPlanScreen extends ConsumerStatefulWidget {
  const WorkoutPlanScreen({super.key});

  @override
  ConsumerState<WorkoutPlanScreen> createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends ConsumerState<WorkoutPlanScreen> {
  List<WorkoutPlan> _plans = const [];
  WorkoutPlan? _plan;
  WorkoutSession? _activeSession;

  String? _planId;
  String? _routineId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  WorkoutRepository get _repo => ref.read(workoutRepositoryProvider);

  Routine? get _routine {
    final routines = _plan?.routines ?? const <Routine>[];
    if (routines.isEmpty) return null;
    for (final r in routines) {
      if (r.id == _routineId) return r;
    }
    return routines.first;
  }

  Future<void> _fetch({String? selectPlanId, String? selectRoutineId}) async {
    setState(() => _loading = true);
    try {
      // The session does not depend on which plan wins below, so it rides
      // along with the plan list rather than costing a round trip of its own.
      final first = await Future.wait([_repo.plans(), _repo.activeSession()]);
      if (!mounted) return;
      var plans = first[0] as List<WorkoutPlan>;
      final session = first[1] as WorkoutSession?;

      // A user should never land on an empty "no plan" screen — give them a
      // plan to start from instead of making plan creation a required first
      // step. It starts empty: naming its first routine is the user's call,
      // not something to guess at with a "Routine 1".
      if (plans.isEmpty) {
        final created = await _repo.addPlan('My workout plan');
        if (!mounted) return;
        plans = [created];
        selectPlanId ??= created.id;
      }

      final wantedId = selectPlanId ?? _planId;
      String? targetId;
      if (plans.isNotEmpty) {
        final match = plans.where((p) => p.id == wantedId);
        final active = plans.where((p) => p.isActive);
        targetId = match.isNotEmpty
            ? match.first.id
            : (active.isNotEmpty ? active.first.id : plans.first.id);
      }

      final full = targetId == null ? null : await _repo.plan(targetId);
      if (!mounted) return;

      setState(() {
        _plans = plans;
        _plan = full;
        _planId = targetId;
        _activeSession = session;
        _selectRoutine(full, selectRoutineId);
      });
      _prefetchAnimations();
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Bumped by every local patch, so a reconcile that was already in the air
  /// when one landed can tell that its answer is a step behind.
  int _revision = 0;

  /// Paints a write the API has already accepted, then reconciles behind it.
  ///
  /// Every mutation answers with the piece it changed, so the screen patches
  /// its copy of the plan and repaints on the spot — sitting through a refetch
  /// to be shown a change the server already confirmed is a wait with nothing
  /// in it. The refetch still runs, quietly, to pick up whatever the patch
  /// could not know (server-side ordering, a routine another device touched).
  void _applyPlan(WorkoutPlan plan, {String? selectRoutineId}) {
    _revision++;
    setState(() {
      _plan = plan;
      _planId = plan.id;
      _plans = _plans.any((p) => p.id == plan.id)
          ? [
              for (final p in _plans)
                p.id == plan.id ? p.copyWith(name: plan.name) : p,
            ]
          : [..._plans, plan];
      _loading = false;
      _selectRoutine(plan, selectRoutineId);
    });
    _prefetchAnimations();
    unawaited(_reconcile());
  }

  /// Refetches the open plan without a loading flag, so the list changes under
  /// the user rather than blinking through a skeleton.
  Future<void> _reconcile() async {
    final planId = _planId;
    if (planId == null) return _fetch();
    final revision = _revision;
    try {
      final full = await _repo.plan(planId);
      // A patch landed while this was in flight, or the user moved on to
      // another plan: what is on screen is newer than this answer.
      if (!mounted || revision != _revision || planId != _planId) return;
      setState(() {
        _plan = full;
        _loading = false;
        _selectRoutine(full, null);
      });
      _prefetchAnimations();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Only worth reporting when it left nothing on screen. After a patch the
      // accepted write is already showing, and an error toast behind it would
      // read as the write having failed.
      if (_plan == null) _reportError(e);
    }
  }

  /// The live copy of a routine, re-read after an `await` — a reconcile may
  /// have swapped [_plan] out while a pushed screen was open.
  (WorkoutPlan, Routine)? _live(String routineId) {
    final plan = _plan;
    if (plan == null) return null;
    for (final r in plan.routines) {
      if (r.id == routineId) return (plan, r);
    }
    return null;
  }

  /// Keeps the open routine open where it survived the write, and falls back
  /// to the first one where it did not. Call inside a [setState].
  void _selectRoutine(WorkoutPlan? plan, String? wanted) {
    final routines = plan?.routines ?? const <Routine>[];
    final id = wanted ?? _routineId;
    _routineId = routines.any((r) => r.id == id)
        ? id
        : (routines.isEmpty ? null : routines.first.id);
  }

  void _prefetchAnimations() {
    final exercises = _routine?.exercises ?? const <RoutineExercise>[];
    ref
        .read(exerciseAnimationCacheProvider)
        .prefetch(exercises.map((e) => e.catalogId));
  }

  /// Surfaces a failure from an action that owns its own progress UI — those
  /// report through here rather than swallowing the error into the sheet or
  /// dialog they came from.
  void _reportError(Object error) {
    if (mounted) showAppSnack(context, error.toString(), error: true);
  }

  /* ------------------------------------------------------------- plans -- */

  Future<void> _createPlan() async {
    // The plan is created from inside the prompt, which holds itself open on
    // "Saving…" until the API answers — so the screen behind it never has to
    // show a half-made plan.
    WorkoutPlan? created;
    final name = await showNamePrompt(
      context,
      title: 'New workout plan',
      hint: 'Plan name',
      initial: _plans.isEmpty ? 'My Workout Plan' : '',
      onConfirm: (value) async {
        created = await _repo.addPlan(value);
      },
    );
    if (name == null || created == null || !mounted) return;
    // A new plan is empty, so there is nothing to fetch before showing it.
    _applyPlan(created!, selectRoutineId: '');
  }

  /// Value the plan switcher's "New Workout Plan" card reports through the
  /// sheet's single `T` type — distinct from any real plan id.
  static const _kAddPlanValue = '__add_workout_plan__';

  Future<void> _selectPlan(String planId) async {
    if (planId == _planId) return;
    // The switcher is also what makes a plan the one the app opens on, so the
    // choice is persisted rather than kept in local state — and the card that
    // fired it is already gone, so the wait gets a dialog of its own.
    final switched = await runWithPendingDialog<bool>(
      context,
      label: 'Switching plan…',
      action: () async {
        await _repo.updatePlan(planId, isActive: true);
        return true;
      },
      onError: _reportError,
    );
    if (switched != true || !mounted) return;
    // The switcher only knows plan names — the routines behind the chosen one
    // still have to be fetched, so this is the one move that keeps a skeleton.
    // It is a single round trip now rather than a full reload.
    _revision++;
    setState(() {
      _plans = [
        for (final p in _plans) p.copyWith(isActive: p.id == planId),
      ];
      _planId = planId;
      _plan = null;
      _routineId = null;
      _loading = true;
    });
    await _reconcile();
  }

  Future<void> _handlePlanMenuAction(_PlanMenuAction action) async {
    final plan = _plan;
    if (plan == null) return;

    switch (action) {
      case _PlanMenuAction.build:
        // The dialog owns the whole flow — brief, draft, revisions, and the
        // confirm — and only answers once the plan has actually been rewritten.
        final built = await showBuildRoutineDialog(context, plan: plan);
        if (built == null || !mounted) return;
        _applyPlan(built, selectRoutineId: '');

      case _PlanMenuAction.rename:
        final name = await showNamePrompt(
          context,
          title: 'Rename plan',
          initial: plan.name,
          onConfirm: (value) => _repo.updatePlan(plan.id, name: value),
        );
        if (name == null || !mounted) return;
        _applyPlan(plan.copyWith(name: name.trim()));

      case _PlanMenuAction.duplicate:
        final copy = await runWithPendingDialog(
          context,
          label: 'Duplicating plan…',
          action: () => _repo.duplicatePlan(plan.id),
          onError: _reportError,
        );
        if (copy == null || !mounted) return;
        // The duplicate comes back whole, routines and all, so it can be
        // opened without a second call.
        _applyPlan(copy, selectRoutineId: '');

      case _PlanMenuAction.delete:
        // Deleted from inside the confirm dialog, which stays up on
        // "Deleting…" until the API answers — see _createPlan.
        final ok = await confirmDestructive(
          context,
          title: 'Delete plan',
          message: '${plan.name} and all of its routines will be removed.',
          onConfirm: () => _repo.deletePlan(plan.id),
        );
        if (!ok || !mounted) return;
        // The plan leaves the switcher at once; the one taking its place is
        // the only thing left to wait for.
        final remaining = [
          for (final p in _plans)
            if (p.id != plan.id) p,
        ];
        _revision++;
        setState(() {
          _plans = remaining;
          _plan = null;
          _planId = remaining.isEmpty ? null : remaining.first.id;
          _routineId = null;
          _loading = true;
        });
        await _reconcile();

      case _PlanMenuAction.manageRoutines:
        final result = await showManageRoutines(
          context,
          routines: plan.routines,
          onSave: (changes) async {
            for (final id in changes.removed) {
              await _repo.deleteRoutine(plan.id, id);
            }
            for (final entry in changes.renamed.entries) {
              if (changes.removed.contains(entry.key)) continue;
              await _repo.updateRoutine(plan.id, entry.key, name: entry.value);
            }
            if (changes.order.isNotEmpty) {
              await _repo.reorderRoutines(plan.id, changes.order);
            }
          },
        );
        if (result == null || !mounted) return;
        _applyPlan(
          plan.copyWith(routines: _replayRoutines(plan.routines, result)),
        );
    }
  }

  /// Replays a "Manage Routines" save against the local list: the same
  /// removals, renames and order the sheet just sent to the API.
  List<Routine> _replayRoutines(
    List<Routine> routines,
    ManageRoutinesResult changes,
  ) {
    final kept = [
      for (final r in routines)
        if (!changes.removed.contains(r.id))
          if (changes.renamed[r.id] case final name?)
            r.copyWith(name: name)
          else
            r,
    ];
    if (changes.order.isEmpty) return kept;
    final rank = {
      for (final (index, id) in changes.order.indexed) id: index,
    };
    kept.sort((a, b) => (rank[a.id] ?? 0).compareTo(rank[b.id] ?? 0));
    return kept;
  }

  /* ------------------------------------------------------- header menus -- */

  /// The plan switcher behind the header pill: every plan, plus the way to
  /// start a new one.
  Future<void> _openPlanSwitcher() async {
    final c = context.colors;
    final value = await showFitnessOptionSheet<String>(
      context: context,
      title: 'Workout Plans',
      options: (sheetContext) => [
        for (final p in _plans)
          SheetActionRow(
            icon: Icons.fitness_center_rounded,
            label: p.name,
            trailing: p.id == _planId
                ? Icon(Icons.check_rounded, size: 18, color: c.primary)
                : null,
            onTap: () => Navigator.of(sheetContext).pop(p.id),
          ),
        SheetActionRow(
          icon: Icons.add_rounded,
          label: 'New Workout Plan',
          onTap: () => Navigator.of(sheetContext).pop(_kAddPlanValue),
        ),
      ],
    );
    if (value == null || !mounted) return;
    HapticFeedback.selectionClick();
    if (value == _kAddPlanValue) {
      await _createPlan();
    } else {
      await _selectPlan(value);
    }
  }

  /// The plan `⋮` menu: the same sheet, acting on the plan that is open.
  Future<void> _openPlanMenu() async {
    final plan = _plan;
    if (plan == null) return;

    final action = await showFitnessOptionSheet<_PlanMenuAction>(
      context: context,
      title: plan.name,
      options: (sheetContext) => [
        _planMenuRow(
          sheetContext,
          action: _PlanMenuAction.build,
          icon: Icons.auto_awesome_rounded,
          label: 'Build me a routine',
        ),
        _planMenuRow(
          sheetContext,
          action: _PlanMenuAction.rename,
          icon: Icons.edit_rounded,
          label: 'Rename',
        ),
        _planMenuRow(
          sheetContext,
          action: _PlanMenuAction.duplicate,
          icon: Icons.copy_all_rounded,
          label: 'Duplicate',
        ),
        _planMenuRow(
          sheetContext,
          action: _PlanMenuAction.manageRoutines,
          icon: Icons.list_alt_rounded,
          label: 'Manage Routines',
        ),
        _planMenuRow(
          sheetContext,
          action: _PlanMenuAction.delete,
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          danger: true,
          // The last plan cannot go: the screen has nothing to show without
          // one, and _fetch would only turn around and create another.
          enabled: _plans.length > 1,
        ),
      ],
    );
    if (action == null || !mounted) return;
    HapticFeedback.selectionClick();
    await _handlePlanMenuAction(action);
  }

  /* ---------------------------------------------------------- routines -- */

  Future<void> _newRoutine() async {
    final plan = _plan;
    if (plan == null) {
      await _createPlan();
      return;
    }
    Routine? created;
    final name = await showNamePrompt(
      context,
      title: 'New Routine',
      hint: 'Routine name',
      onConfirm: (value) async {
        created = await _repo.addRoutine(plan.id, value);
      },
    );
    if (name == null || created == null || !mounted) return;
    _applyPlan(
      plan.copyWith(routines: [...plan.routines, created!]),
      selectRoutineId: created!.id,
    );
  }

  /// The routine `⋯` menu on the action bar — the same sheet as the two in
  /// the header, acting on the routine that is open.
  Future<void> _openRoutineMenu() async {
    final plan = _plan;
    final routine = _routine;
    if (plan == null || routine == null) return;

    final action = await showFitnessOptionSheet<RoutineMenuAction>(
      context: context,
      title: routine.name,
      options: (sheetContext) => [
        SheetActionRow(
          icon: Icons.edit_rounded,
          label: 'Rename routine',
          onTap: () =>
              Navigator.of(sheetContext).pop(RoutineMenuAction.rename),
        ),
        SheetActionRow(
          icon: Icons.swap_vert_rounded,
          label: 'Reorder & remove exercises',
          onTap: () => Navigator.of(
            sheetContext,
          ).pop(RoutineMenuAction.reorderExercises),
        ),
        SheetActionRow(
          icon: Icons.timer_outlined,
          label: 'Rest between exercises',
          onTap: () => Navigator.of(
            sheetContext,
          ).pop(RoutineMenuAction.restBetweenExercises),
        ),
        SheetActionRow(
          icon: Icons.delete_outline_rounded,
          label: 'Delete routine',
          danger: true,
          // A plan needs at least one routine, the same way it needs to keep
          // its last plan.
          enabled: plan.routines.length > 1,
          onTap: () =>
              Navigator.of(sheetContext).pop(RoutineMenuAction.delete),
        ),
      ],
    );
    if (action == null || !mounted) return;
    HapticFeedback.selectionClick();

    switch (action) {
      case RoutineMenuAction.rename:
        final name = await showNamePrompt(
          context,
          title: 'Rename routine',
          initial: routine.name,
          onConfirm: (value) =>
              _repo.updateRoutine(plan.id, routine.id, name: value),
        );
        if (name == null || !mounted) return;
        _applyPlan(plan.withRoutine(routine.copyWith(name: name.trim())));

      case RoutineMenuAction.reorderExercises:
        await _reorderExercises(plan, routine);

      case RoutineMenuAction.restBetweenExercises:
        final seconds = await showDurationSheet(
          context,
          title: 'Rest between exercises',
          initialSeconds: routine.restBetweenExercisesSec,
          onSave: (value) => _repo.updateRoutine(
            plan.id,
            routine.id,
            restBetweenExercisesSec: value,
          ),
        );
        if (seconds == null || !mounted) return;
        _applyPlan(
          plan.withRoutine(routine.copyWith(restBetweenExercisesSec: seconds)),
        );

      case RoutineMenuAction.delete:
        if (plan.routines.length <= 1) {
          showAppSnack(
            context,
            'A plan needs at least one routine',
            error: true,
          );
          return;
        }
        final ok = await confirmDestructive(
          context,
          title: 'Delete routine',
          message: '${routine.name} and its exercises will be removed.',
          onConfirm: () => _repo.deleteRoutine(plan.id, routine.id),
        );
        if (!ok || !mounted) return;
        _applyPlan(
          plan.copyWith(
            routines: [
              for (final r in plan.routines)
                if (r.id != routine.id) r,
            ],
          ),
          selectRoutineId: '',
        );
    }
  }

  /* --------------------------------------------------------- exercises -- */

  Future<void> _addExercise() async {
    final plan = _plan;
    final routine = _routine;
    if (plan == null || routine == null) {
      await _newRoutine();
      return;
    }
    final added = await pushFitness<ExerciseEdit>(
      context,
      ExercisePickerScreen(planId: plan.id, routineId: routine.id),
    );
    if (added == null || !mounted) return;
    if (_live(routine.id) case (final p, final r)) {
      _applyPlan(
        p.withRoutine(r.copyWith(exercises: [...r.exercises, added.exercise])),
      );
    }
  }

  Future<void> _editExercise(RoutineExercise exercise) async {
    final plan = _plan;
    final routine = _routine;
    if (plan == null || routine == null) return;

    final edit = await pushFitness<ExerciseEdit>(
      context,
      ExerciseConfigScreen(
        planId: plan.id,
        routineId: routine.id,
        exercise: exercise,
      ),
    );
    if (edit == null || !mounted) return;
    if (_live(routine.id) case (final p, final r)) {
      _applyPlan(
        p.withRoutine(
          r.copyWith(
            exercises: edit.deleted
                ? [
                    for (final e in r.exercises)
                      if (e.id != edit.exercise.id) e,
                  ]
                : [
                    for (final e in r.exercises)
                      e.id == edit.exercise.id ? edit.exercise : e,
                  ],
          ),
        ),
      );
    }
  }

  /* ---------------------------------------------------------- sessions -- */

  Future<void> _startFlow(WorkoutPlan plan, Routine routine) async {
    if (routine.exercises.isEmpty) {
      showAppSnack(context, 'Add an exercise first', error: true);
      return;
    }

    // A live session is only in the user's way if they are about to start
    // another one, so ▶ is where it gets raised — and starting fresh is a real
    // choice here, since the API abandons whatever was still running.
    //
    // Re-read before asking rather than trusting the copy in state: it may be
    // a workout that has since been finished, and being told to choose about a
    // workout that is already over is worse than the round trip.
    if (_activeSession != null) {
      final active = await _liveSession();
      if (!mounted) return;
      if (active != null) {
        final resume = await _askResume(active);
        if (resume == null || !mounted) return;
        if (resume) return _openSession(active);
      }
    }

    final started = await pushFitness<WorkoutSession>(
      context,
      WorkoutPrestartScreen(planId: plan.id, routine: routine),
    );
    if (started == null || !mounted) return;
    await _openSession(started);
  }

  /// The same screen as the pre-start, opened for the editing half of it. It
  /// hands back the routine it saved, which goes straight onto the list.
  Future<void> _reorderExercises(WorkoutPlan plan, Routine routine) async {
    if (routine.exercises.isEmpty) {
      showAppSnack(context, 'Add an exercise first', error: true);
      return;
    }
    final saved = await pushFitness<Routine>(
      context,
      WorkoutPrestartScreen(
        planId: plan.id,
        routine: routine,
        autoStart: false,
      ),
    );
    if (saved == null || !mounted) return;
    if (_live(routine.id) case (final p, _)) _applyPlan(p.withRoutine(saved));
  }

  /// The session the server still calls active, which is the only one worth
  /// offering to resume. Falls back to the copy in state when the check itself
  /// fails, so being offline does not lose a workout in progress.
  Future<WorkoutSession?> _liveSession() async {
    try {
      final session = await _repo.activeSession();
      if (mounted) setState(() => _activeSession = session);
      return session;
    } catch (_) {
      return _activeSession;
    }
  }

  /// True to pick the running workout back up, false to start a new one, null
  /// if the user backed out of the choice altogether.
  Future<bool?> _askResume(WorkoutSession active) {
    return showFitnessOptionSheet<bool>(
      context: context,
      title: 'Workout in progress · ${active.routineName}',
      options: (sheetContext) => [
        SheetActionRow(
          icon: Icons.play_arrow_rounded,
          label: 'Continue where you left off',
          onTap: () => Navigator.of(sheetContext).pop(true),
        ),
        SheetActionRow(
          icon: Icons.restart_alt_rounded,
          label: 'Start from the beginning',
          onTap: () => Navigator.of(sheetContext).pop(false),
        ),
      ],
    );
  }

  /// Runs a workout and reloads once it is over.
  ///
  /// The session is pushed from here rather than from the pre-start screen so
  /// that this `await` is on the session's own route. It completes when that
  /// route ends — popped, or replaced by the summary, which only happens after
  /// the finish call has come back — so the reload always sees the truth.
  /// Pushed from the pre-start screen instead, the future completed the moment
  /// the workout *started* and nothing reloaded afterwards, which is how the
  /// plan came to keep offering to resume a workout already finished.
  Future<void> _openSession(WorkoutSession session) async {
    await pushFitness<bool>(context, WorkoutSessionScreen(session: session));
    if (mounted) await _fetch();
  }

  /* ------------------------------------------------------------- build -- */

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final plan = _plan;
    final routine = _routine;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: _loading && plan == null
            ? const _PlanScreenSkeleton()
            : Column(
                children: [
                  _header(plan),
                  if (plan != null && plan.routines.isNotEmpty)
                    _routineTabs(plan),
                  Expanded(
                    child: plan == null
                        ? _noPlanState()
                        : plan.routines.isEmpty
                        ? _noRoutineState()
                        : (routine == null || routine.exercises.isEmpty)
                        ? _emptyRoutineState()
                        : _exerciseList(routine),
                  ),
                ],
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: plan == null || routine == null
          ? null
          : Padding(
              // Default centerFloat margin (16) isn't enough to clear the
              // outer AppShell's floating pill nav bar, since this nested
              // Scaffold's body extends behind it (extendBody: true there) —
              // but only just enough to sit above it, not a gap of its own.
              padding: const EdgeInsets.only(
                bottom: AppSpacing.screenBottomInset - 36,
              ),
              child: _BottomActionBar(
                onAdd: _addExercise,
                // Nothing to start until the routine has an exercise in it —
                // the button greys out rather than opening a flow that would
                // only turn the user back.
                onStart: routine.exercises.isEmpty
                    ? null
                    : () => _startFlow(plan, routine),
                onMore: _openRoutineMenu,
              ),
            ),
    );
  }

  Widget _header(WorkoutPlan? plan) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Only when pushed (from the Fitness home); as a tab body this
          // screen is the root and has nothing to go back to.
          if (Navigator.of(context).canPop()) ...[
            FitnessIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              iconSize: 16,
              background: Colors.transparent,
              onTap: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: FitnessPill(
              onTap: _openPlanSwitcher,
              // A rounded box rather than a full pill, to sit with the square
              // `⋮` button beside it.
              radius: AppRadius.sm,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      plan?.name ?? 'My Workout Plan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyLargeRegular.copyWith(color: c.text),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: c.text,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FitnessIconButton(
            icon: Icons.more_vert_rounded,
            onTap: plan == null ? null : _openPlanMenu,
          ),
        ],
      ),
    );
  }

  /// One row of the plan menu sheet, popping its own action.
  Widget _planMenuRow(
    BuildContext sheetContext, {
    required _PlanMenuAction action,
    required IconData icon,
    required String label,
    bool danger = false,
    bool enabled = true,
  }) {
    return SheetActionRow(
      icon: icon,
      label: label,
      danger: danger,
      enabled: enabled,
      onTap: () => Navigator.of(sheetContext).pop(action),
    );
  }

  Widget _routineTabs(WorkoutPlan plan) {
    final c = context.colors;
    return SizedBox(
      height: 52,
      // "New Routine" sits outside the scroller, pinned to the right edge, so
      // it stays reachable however many routines the plan has.
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.sm,
              ),
              children: [
                for (final routine in plan.routines)
                  GestureDetector(
                    onTap: () => setState(() => _routineId = routine.id),
                    child: Container(
                      margin: const EdgeInsets.only(right: AppSpacing.lg),
                      alignment: Alignment.center,
                      // IntrinsicWidth so the underline can stretch to the
                      // label's own width — a horizontal ListView hands its
                      // children unbounded width, which `stretch` alone can't
                      // resolve.
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              routine.name,
                              textAlign: TextAlign.center,
                              // One size for every tab — the colour and the
                              // underline mark the open one, so growing the
                              // label as well only shifts the row about.
                              style: AppText.bodySm.copyWith(
                                color: routine.id == _routine?.id
                                    ? c.text
                                    : c.textSubtle,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 2,
                              color: routine.id == _routine?.id
                                  ? c.text
                                  : Colors.transparent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            color: c.primary,
            // Square against the screen edge it is flush with, rounded on the
            // side the routines scroll past.
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AppRadius.pill),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _newRoutine,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Text(
                  'New Routine',
                  style: AppText.bodySm.copyWith(color: c.textOnPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noPlanState() => EmptyState(
    icon: Icons.fitness_center_rounded,
    title: 'No workout plan yet',
    message: 'Create a plan, add a routine, and start training.',
    action: PillButton(
      label: 'Create plan',
      expand: false,
      radius: AppRadius.sm,
      height: 44,
      labelStyle: AppText.body,
      onPressed: _createPlan,
    ),
  );

  // Where a freshly created plan lands: a plan is created empty, so naming
  // its first routine is the first thing asked of the user.
  Widget _noRoutineState() => Align(
    // A touch above centre — the floating action bar crowds the bottom half,
    // so dead centre reads as low.
    alignment: const Alignment(0, -0.25),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/workout_empty_routines.png',
          // Wider than it is tall, so it is sized by width and left to keep
          // its own aspect ratio rather than being squared off.
          width: 260,
          // A stale asset manifest (new asset added after the app was already
          // running — needs a full restart, not hot reload) must never take
          // the rest of this empty state down with it.
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.checklist_rounded,
            size: 40,
            color: context.colors.textSubtle,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // The illustration and the one button carry this state on their own —
        // there is nothing to explain that "Add your first routine" doesn't.
        PillButton(
          label: 'Add your first routine',
          expand: false,
          radius: AppRadius.sm,
          height: 44,
          labelStyle: AppText.body,
          leading: Icon(
            Icons.add_circle_rounded,
            size: 16,
            color: context.colors.textOnPrimary,
          ),
          onPressed: _newRoutine,
        ),
      ],
    ),
  );

  // No button here, unlike [_noRoutineState]: this state keeps the bottom
  // action bar, whose `+` is already the way to add an exercise.
  Widget _emptyRoutineState() => Align(
    // A touch above centre, matching the no-routine state — the floating
    // action bar crowds the bottom half.
    alignment: const Alignment(0, -0.25),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/workout_empty_exercises.png',
          width: 110,
          // A stale asset manifest (new asset added after the app was already
          // running — needs a full restart, not hot reload) must never take
          // the rest of this empty state down with it.
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.sticky_note_2_outlined,
            size: 40,
            color: context.colors.textSubtle,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Lets add some exercises',
          textAlign: TextAlign.center,
          style: AppText.bodyLargeRegular.copyWith(
            color: context.colors.textSubtle,
          ),
        ),
      ],
    ),
  );

  Widget _exerciseList(Routine routine) {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.screenBottomInset + AppSpacing.xl2,
        ),
        children: [
          for (final exercise in routine.exercises)
            _ExerciseCard(
              exercise: exercise,
              onTap: () => _editExercise(exercise),
            ),
        ],
      ),
    );
  }
}

/* ----------------------------------------------------------------- bits -- */

/// Loading placeholder mirroring the loaded layout: the header pill, the
/// routine tabs, and a few exercise cards.
class _PlanScreenSkeleton extends StatelessWidget {
  const _PlanScreenSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
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
              const Expanded(
                child: SkeletonBox(
                  width: double.infinity,
                  height: 46,
                  radius: AppRadius.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const SkeletonBox(width: 44, height: 44, radius: AppRadius.sm),
            ],
          ),
        ),
        SizedBox(
          height: 52,
          // Mirrors _routineTabs(): the labels scroll, the "New Routine"
          // button is pinned to the right edge and square against it.
          child: Row(
            children: [
              Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.sm,
                  ),
                  children: const [
                    SkeletonLine(width: 60, height: 16),
                    SizedBox(width: AppSpacing.lg),
                    SkeletonLine(width: 60, height: 16),
                    SizedBox(width: AppSpacing.lg),
                    SkeletonLine(width: 60, height: 16),
                  ],
                ),
              ),
              const SkeletonBox(width: 110, height: 36, radius: AppRadius.pill),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: const [ExerciseCardListSkeleton(count: 3)],
          ),
        ),
      ],
    );
  }
}

/// The two-part exercise card: the movement on top, its planned volume on the
/// strip underneath.
class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.exercise, required this.onTap});

  final RoutineExercise exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isTimed = exercise.mode == ExerciseMode.time;
    final first = exercise.sets.isEmpty ? null : exercise.sets.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExerciseInfoCard(
        catalogId: exercise.catalogId,
        name: exercise.name,
        muscleLabel: exercise.muscleLabel,
        restBetweenSetsSec: exercise.restBetweenSetsSec,
        setCount: exercise.sets.length,
        statValue: isTimed
            ? formatClock(first?.durationSec ?? 0)
            : formatValue(first?.reps),
        statLabel: isTimed ? 'Time' : 'Reps',
        accentColor: parseSwatch(exercise.color),
        onTap: onTap,
      ),
    );
  }
}

/// A compact pill of icon buttons, sized to match [AppShell]'s bottom nav
/// bar rather than stretching edge to edge.
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onAdd,
    required this.onStart,
    required this.onMore,
  });

  final VoidCallback onAdd;
  final VoidCallback? onStart;
  final VoidCallback onMore;

  static const _height = 46.0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // Each cell is a wide rectangle, so an InkWell would flash a slab of
    // colour across a third of the bar. InkResponse clipped to a circle keeps
    // the whole cell tappable but rounds the press off around the icon.
    Widget button(IconData icon, VoidCallback? onTap, {double size = 18}) =>
        Expanded(
          child: InkResponse(
            onTap: onTap,
            customBorder: const CircleBorder(),
            radius: _height / 2,
            child: Icon(
              icon,
              size: size,
              color: c.textOnPrimary.withValues(alpha: onTap == null ? 0.4 : 1),
            ),
          ),
        );

    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        // As wide as AppShell's bottom nav bar (5 x navBarHeight-wide items)
        // but shorter, since three icons need less room than five tabs.
        width: AppSpacing.navBarHeight * 5,
        height: _height,
        child: Row(
          // Stretched so each cell is the full bar height and the circular
          // press lands centred in it.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            button(Icons.add_circle_outline_rounded, onAdd),
            button(Icons.play_arrow_rounded, onStart, size: 22),
            button(Icons.more_horiz_rounded, onMore),
          ],
        ),
      ),
    );
  }
}

