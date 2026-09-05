import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../models/workout_models.dart';

final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => WorkoutRepository(ref.read(apiClientProvider)),
);

/// The Fitness → Workout API surface: plans and their nested routines and
/// exercises, the exercise catalog behind the picker, and live sessions.
///
/// Plan mutations all answer with the piece that changed rather than the whole
/// plan. The plan screen patches that piece into its copy and repaints at
/// once, then refetches quietly behind the user — waiting on the read before
/// showing a write the server already took is a pause with nothing in it.
class WorkoutRepository {
  WorkoutRepository(this._api);

  final ApiClient _api;

  /* ------------------------------------------------------------- plans -- */

  Future<List<WorkoutPlan>> plans() async {
    final res = await _api.dio.get('get-workout-plans');
    return _list(res.data).map(WorkoutPlan.fromJson).toList();
  }

  /// The plan the user last had open. Null before they have made one.
  Future<WorkoutPlan?> activePlan() async {
    final res = await _api.dio.get('get-active-workout-plan');
    final data = res.data['data'];
    if (data is! Map) return null;
    return WorkoutPlan.fromJson(data.cast<String, dynamic>());
  }

  Future<WorkoutPlan> plan(String id) async {
    final res = await _api.dio.get('get-workout-plan/$id');
    return WorkoutPlan.fromJson(
      (res.data['data'] as Map).cast<String, dynamic>(),
    );
  }

  Future<WorkoutPlan> addPlan(String name) async {
    final res = await _api.dio.post('add-workout-plan', data: {'name': name});
    return WorkoutPlan.fromJson(
      (res.data['data'] as Map).cast<String, dynamic>(),
    );
  }

  /// Also the "make this the open plan" call: the switcher sends
  /// `isActive: true` and the backend clears the flag on the others.
  Future<void> updatePlan(
    String id, {
    String? name,
    bool? isActive,
    bool? remindersEnabled,
    List<WorkoutReminder>? reminders,
  }) => _api.dio.put('update-workout-plan/$id', data: {
    if (name != null) 'name': name,
    if (isActive != null) 'isActive': isActive,
    if (remindersEnabled != null) 'remindersEnabled': remindersEnabled,
    if (reminders != null)
      'reminders': reminders.map((r) => r.toJson()).toList(),
  });

  Future<WorkoutPlan> duplicatePlan(String id) async {
    final res = await _api.dio.post('duplicate-workout-plan/$id');
    return WorkoutPlan.fromJson(
      (res.data['data'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> deletePlan(String id) =>
      _api.dio.delete('delete-workout-plan/$id');

  Future<void> reorderPlans(List<String> planIds) =>
      _api.dio.put('reorder-workout-plans', data: {'planIds': planIds});

  /* ---------------------------------------------------------- routines -- */

  Future<Routine> addRoutine(String planId, String name) async {
    final res = await _api.dio.post('add-routine/$planId', data: {'name': name});
    return Routine.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<void> updateRoutine(
    String planId,
    String routineId, {
    String? name,
    int? restBetweenExercisesSec,
  }) => _api.dio.put('update-routine/$planId/$routineId', data: {
    if (name != null) 'name': name,
    if (restBetweenExercisesSec != null)
      'restBetweenExercisesSec': restBetweenExercisesSec,
  });

  Future<void> deleteRoutine(String planId, String routineId) =>
      _api.dio.delete('delete-routine/$planId/$routineId');

  Future<void> reorderRoutines(String planId, List<String> routineIds) =>
      _api.dio.put('reorder-routines/$planId', data: {'routineIds': routineIds});

  /* ------------------------------------------------- routine exercises -- */

  Future<RoutineExercise> addExercise(
    String planId,
    String routineId,
    RoutineExercise exercise,
  ) async {
    final res = await _api.dio.post(
      'add-routine-exercise/$planId/$routineId',
      data: exercise.toJson(),
    );
    return RoutineExercise.fromJson(
      (res.data['data'] as Map).cast<String, dynamic>(),
    );
  }

  Future<RoutineExercise> updateExercise(
    String planId,
    String routineId,
    String exerciseId,
    RoutineExercise exercise,
  ) async {
    final res = await _api.dio.put(
      'update-routine-exercise/$planId/$routineId/$exerciseId',
      data: exercise.toJson(),
    );
    return RoutineExercise.fromJson(
      (res.data['data'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> deleteExercise(
    String planId,
    String routineId,
    String exerciseId,
  ) => _api.dio.delete(
    'delete-routine-exercise/$planId/$routineId/$exerciseId',
  );

  /// The pre-start sheet's single save.
  ///
  /// Removal is by omission: any exercise whose id is left out of
  /// [exerciseIds] is deleted server-side. That is deliberate — the sheet owns
  /// both the order and the removals, and sending them as separate calls would
  /// let a save half-apply — but it does mean a caller must always pass the
  /// *complete* surviving list, never a partial one.
  Future<void> reorderExercises(
    String planId,
    String routineId,
    List<String> exerciseIds, {
    int? restBetweenExercisesSec,
  }) => _api.dio.put(
    'reorder-routine-exercises/$planId/$routineId',
    data: {
      'exerciseIds': exerciseIds,
      if (restBetweenExercisesSec != null)
        'restBetweenExercisesSec': restBetweenExercisesSec,
    },
  );

  /* ---------------------------------------------------- routine builder -- */

  /// Drafts a week from the brief, or redrafts the one on screen from a change
  /// the user asked for. Nothing is written until [applyBuiltRoutines].
  ///
  /// A longer receive timeout than the client default: this waits on a language
  /// model, which is slower than any other call in the app.
  Future<BuiltPlan> buildRoutines({
    Map<String, dynamic>? brief,
    BuiltPlan? current,
    String? request,
  }) async {
    final res = await _api.dio.post(
      'build-routines',
      data: {
        if (brief != null) 'brief': brief,
        if (current != null) 'current': current.toJson(),
        if (request != null && request.trim().isNotEmpty) 'request': request,
      },
      options: Options(receiveTimeout: const Duration(seconds: 90)),
    );
    return BuiltPlan.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  /// Writes an accepted draft over the plan, replacing every routine and
  /// exercise it had. Answers with the plan as it now stands.
  Future<WorkoutPlan> applyBuiltRoutines(String planId, BuiltPlan plan) async {
    final res = await _api.dio.post(
      'apply-built-routines/$planId',
      data: {'routines': plan.raw['routines']},
    );
    return WorkoutPlan.fromJson(
      (res.data['data'] as Map).cast<String, dynamic>(),
    );
  }

  /* ----------------------------------------------------------- catalog -- */

  Future<List<ExerciseCatalogItem>> catalog({
    String? search,
    String? primaryMuscle,
    String? equipment,
    int limit = 60,
    int skip = 0,
  }) async {
    final res = await _api.dio.get(
      'get-exercise-catalog',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (primaryMuscle != null && primaryMuscle.isNotEmpty)
          'primaryMuscle': primaryMuscle,
        if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
        'limit': limit,
        'skip': skip,
      },
    );
    return _list(res.data).map(ExerciseCatalogItem.fromJson).toList();
  }

  /// Every catalog row, paged through at the server's cap.
  ///
  /// ~1,600 rows of metadata — the animations themselves are a separate
  /// endpoint, so this is only a megabyte or so of text and is what
  /// [ExerciseCatalogCache] keeps on disk to filter locally.
  Future<List<ExerciseCatalogItem>> fullCatalog() async {
    // MAX_LIMIT on the server; asking for more is silently clamped to it.
    const pageSize = 500;
    final all = <ExerciseCatalogItem>[];
    while (true) {
      final page = await catalog(limit: pageSize, skip: all.length);
      all.addAll(page);
      if (page.length < pageSize) return all;
    }
  }

  Future<List<MuscleCount>> catalogMuscles() async {
    final res = await _api.dio.get('get-exercise-catalog-muscles');
    return _list(res.data).map(MuscleCount.fromJson).toList();
  }

  /// The equipment dropdown. This endpoint answers with bare strings rather
  /// than the `{data: ...}` envelope the workout routes use.
  Future<List<String>> equipments() async {
    final res = await _api.dio.get('get-exercise-equipments');
    return ((res.data as List?) ?? const [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /* -------------------------------------------------- custom exercises -- */

  Future<List<CustomExercise>> customExercises() async {
    final res = await _api.dio.get('get-custom-exercises');
    return _list(res.data).map(CustomExercise.fromJson).toList();
  }

  /// Throws a `DioException` with status 409 when the user already has an
  /// exercise by that name (the index is case-insensitive).
  Future<CustomExercise> addCustomExercise({
    required String name,
    String? muscle,
    String? equipment,
  }) async {
    final res = await _api.dio.post('add-custom-exercise', data: {
      'name': name,
      if (muscle != null && muscle.isNotEmpty) 'muscle': muscle,
      if (equipment != null && equipment.isNotEmpty) 'equipment': equipment,
    });
    return CustomExercise.fromJson(
      (res.data['data'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> deleteCustomExercise(String id) =>
      _api.dio.delete('delete-custom-exercise/$id');

  /* ---------------------------------------------------------- sessions -- */

  Future<WorkoutSession> startSession({
    required String planId,
    required String routineId,
    int? restBetweenExercisesSec,
  }) async {
    final res = await _api.dio.post('start-workout-session', data: {
      'planId': planId,
      'routineId': routineId,
      if (restBetweenExercisesSec != null)
        'restBetweenExercisesSec': restBetweenExercisesSec,
    });
    return WorkoutSession.fromJson(
      (res.data['data'] as Map).cast<String, dynamic>(),
    );
  }

  /// Lets the app pick a workout back up after being killed mid-session.
  Future<WorkoutSession?> activeSession() async {
    final res = await _api.dio.get('get-active-workout-session');
    final data = res.data['data'];
    if (data is! Map) return null;
    return WorkoutSession.fromJson(data.cast<String, dynamic>());
  }

  Future<void> updateSessionSet(
    String sessionId,
    String exerciseId,
    String setId, {
    Object? reps = kUnsetSetValue,
    Object? weight = kUnsetSetValue,
    Object? durationSec = kUnsetSetValue,
    Object? distance = kUnsetSetValue,
    bool? completed,
  }) => _api.dio.put(
    'update-workout-session-set/$sessionId/$exerciseId/$setId',
    // Sent as a sparse body on purpose: omitting a field leaves it alone,
    // while sending it as null clears it back to "-".
    data: {
      if (reps != kUnsetSetValue) 'reps': reps,
      if (weight != kUnsetSetValue) 'weight': weight,
      if (durationSec != kUnsetSetValue) 'durationSec': durationSec,
      if (distance != kUnsetSetValue) 'distance': distance,
      if (completed != null) 'completed': completed,
    },
  );

  Future<WorkoutSet> addSessionSet(String sessionId, String exerciseId) async {
    final res = await _api.dio.post(
      'add-workout-session-set/$sessionId/$exerciseId',
    );
    return WorkoutSet.fromJson(
      (res.data['data'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> deleteSessionSet(
    String sessionId,
    String exerciseId,
    String setId,
  ) => _api.dio.delete(
    'delete-workout-session-set/$sessionId/$exerciseId/$setId',
  );

  /// [durationSec] is the on-screen timer, which is what the user watched; the
  /// backend only falls back to wall-clock when it is left out.
  Future<SessionResult> finishSession(
    String sessionId, {
    required int durationSec,
    bool abandoned = false,
  }) async {
    final res = await _api.dio.post(
      'finish-workout-session/$sessionId',
      data: {
        'durationSec': durationSec,
        if (abandoned) 'status': 'abandoned',
      },
    );
    return SessionResult(
      session: WorkoutSession.fromJson(
        (res.data['data'] as Map).cast<String, dynamic>(),
      ),
      summary: SessionSummary.fromJson(
        ((res.data['summary'] as Map?) ?? const {}).cast<String, dynamic>(),
      ),
    );
  }

  Future<SessionResult> session(String sessionId) async {
    final res = await _api.dio.get('get-workout-session/$sessionId');
    return SessionResult(
      session: WorkoutSession.fromJson(
        (res.data['data'] as Map).cast<String, dynamic>(),
      ),
      summary: SessionSummary.fromJson(
        ((res.data['summary'] as Map?) ?? const {}).cast<String, dynamic>(),
      ),
    );
  }

  Future<void> deleteSession(String sessionId) =>
      _api.dio.delete('delete-workout-session/$sessionId');

  Future<List<WorkoutSessionRow>> sessions({
    int limit = 30,
    int skip = 0,
    DateTime? from,
    DateTime? to,
  }) async {
    final res = await _api.dio.get(
      'get-workout-sessions',
      queryParameters: {
        'limit': limit,
        'skip': skip,
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    return _list(res.data).map(WorkoutSessionRow.fromJson).toList();
  }

  /// Totals, the muscle split and the session rows for one range, in one call —
  /// the stats page would otherwise have to fetch every session in full just to
  /// draw a chart.
  Future<WorkoutStats> workoutStats({DateTime? from, DateTime? to}) async {
    final res = await _api.dio.get(
      'get-workout-stats',
      queryParameters: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    final data = res.data['data'];
    if (data is! Map) return const WorkoutStats();
    return WorkoutStats.fromJson(data.cast<String, dynamic>());
  }

  Future<List<ExerciseHistoryPoint>> exerciseHistory(String name) async {
    final res = await _api.dio.get(
      'get-exercise-history',
      queryParameters: {'name': name},
    );
    return _list(res.data).map(ExerciseHistoryPoint.fromJson).toList();
  }

  Future<List<PreviousExercise>> previousExercises() async {
    final res = await _api.dio.get('get-previous-exercises');
    return _list(res.data).map(PreviousExercise.fromJson).toList();
  }

  List<Map<String, dynamic>> _list(dynamic body) {
    final raw = (body is Map ? body['data'] : null) as List? ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();
  }
}

/// Distinguishes "don't touch this field" from "set it to null" in
/// [WorkoutRepository.updateSessionSet], where clearing a weight back to `-`
/// is a real edit the user can make.
const Object kUnsetSetValue = Object();
