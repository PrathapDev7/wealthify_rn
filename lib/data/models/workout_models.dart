/// Models for the Fitness → Workout surfaces.
///
/// Plans, routines and exercises are one nested document on the backend, so
/// they are one nested object here too: `get-workout-plan` returns the whole
/// tree and every screen below the plan reads from that single fetch rather
/// than fetching its own slice.
///
/// Sessions carry a *copy* of the routine rather than a reference to it, which
/// is why [SessionExercise] repeats [RoutineExercise]'s fields instead of
/// reusing it — a session is a record of what happened, and the two drift
/// apart the moment the plan is edited.
library;

/// Ids come back as `_id` from Mongo and are echoed as `id` by nothing in this
/// API — but the fallback costs one `??` and removes a whole class of empty-id
/// bug if that ever changes.
String _id(Map<String, dynamic> j) =>
    (j['_id'] ?? j['id'] ?? '').toString();

int _int(dynamic v, [int fallback = 0]) =>
    (v is num) ? v.toInt() : (int.tryParse('$v') ?? fallback);

double? _double(dynamic v) =>
    (v is num) ? v.toDouble() : double.tryParse('$v');

List<String> _strings(dynamic v) => ((v as List?) ?? const [])
    .map((e) => e.toString())
    .where((e) => e.isNotEmpty)
    .toList();

List<Map<String, dynamic>> _maps(dynamic v) => ((v as List?) ?? const [])
    .whereType<Map>()
    .map((e) => e.cast<String, dynamic>())
    .toList();

DateTime? _date(dynamic v) =>
    (v == null) ? null : DateTime.tryParse(v.toString())?.toLocal();

/* ------------------------------------------------------------------ sets -- */

/// How an exercise is measured. `weights` logs reps × weight; `time` logs a
/// duration and an optional distance. The backend stores both shapes in the
/// same subdocument and lets the mode decide which fields mean anything.
enum ExerciseMode { weights, time }

ExerciseMode _mode(dynamic v) =>
    '$v' == 'time' ? ExerciseMode.time : ExerciseMode.weights;

String modeToApi(ExerciseMode m) =>
    m == ExerciseMode.time ? 'time' : 'weights';

/// One row of an exercise's set table.
///
/// Every value is nullable because a planned set is allowed to be blank — the
/// reference shows a fresh set as `-`, meaning "however much you can", and a
/// zero would be a different (and wrong) statement.
class WorkoutSet {
  const WorkoutSet({
    this.id = '',
    this.reps,
    this.weight,
    this.durationSec,
    this.distance,
    this.completed = false,
    this.completedAt,
  });

  final String id;
  final int? reps;
  final double? weight;
  final int? durationSec;
  final double? distance;

  /// Only meaningful inside a session; a planned set is never "completed".
  final bool completed;
  final DateTime? completedAt;

  factory WorkoutSet.fromJson(Map<String, dynamic> j) => WorkoutSet(
    id: _id(j),
    reps: j['reps'] == null ? null : _int(j['reps']),
    weight: _double(j['weight']),
    durationSec: j['durationSec'] == null ? null : _int(j['durationSec']),
    distance: _double(j['distance']),
    completed: j['completed'] == true,
    completedAt: _date(j['completedAt']),
  );

  /// Only the planning fields — `completed` is set by ticking a set off during
  /// a workout, never by sending a set body.
  Map<String, dynamic> toJson() => {
    'reps': reps,
    'weight': weight,
    'durationSec': durationSec,
    'distance': distance,
  };

  WorkoutSet copyWith({
    Object? reps = _keep,
    Object? weight = _keep,
    Object? durationSec = _keep,
    Object? distance = _keep,
    bool? completed,
  }) => WorkoutSet(
    id: id,
    reps: reps == _keep ? this.reps : reps as int?,
    weight: weight == _keep ? this.weight : weight as double?,
    durationSec:
        durationSec == _keep ? this.durationSec : durationSec as int?,
    distance: distance == _keep ? this.distance : distance as double?,
    completed: completed ?? this.completed,
    completedAt: completedAt,
  );
}

/// Sentinel for `copyWith` on nullable fields: `null` is a value a caller
/// legitimately wants to write (clearing a weight back to `-`), so it cannot
/// double as "leave this alone".
const Object _keep = Object();

/* ------------------------------------------------------------- exercises -- */

/// One exercise inside a routine.
class RoutineExercise {
  const RoutineExercise({
    required this.id,
    required this.name,
    this.catalogId,
    this.customExercise,
    this.muscle,
    this.primaryMuscle,
    this.equipment,
    this.mode = ExerciseMode.weights,
    this.weightUnit = 'kg',
    this.sets = const [],
    this.restBetweenSetsSec = 0,
    this.color,
    this.notes,
    this.order = 0,
  });

  final String id;
  final String name;

  /// The animation catalog path this came from, when it came from the catalog.
  final String? catalogId;

  /// The custom-exercise document this came from, when the user made it up.
  final String? customExercise;

  /// The coarse catalog muscle (`BACK`), kept because it still drives the
  /// animation filters.
  final String? muscle;

  /// The derived fine muscle (`Lats`) — what the cards and the summary pie
  /// actually show.
  final String? primaryMuscle;
  final String? equipment;
  final ExerciseMode mode;
  final String weightUnit;
  final List<WorkoutSet> sets;
  final int restBetweenSetsSec;

  /// The optional swatch from the config screen, as `#RRGGBB`.
  final String? color;
  final String? notes;
  final int order;

  /// What the exercise card shows under the name. Falls back through the
  /// coarse muscle so a custom exercise with no derived data still says
  /// something.
  String get muscleLabel => (primaryMuscle?.isNotEmpty ?? false)
      ? primaryMuscle!
      : (muscle ?? '');

  factory RoutineExercise.fromJson(Map<String, dynamic> j) => RoutineExercise(
    id: _id(j),
    name: (j['name'] ?? '').toString(),
    catalogId: j['catalogId']?.toString(),
    customExercise: j['customExercise']?.toString(),
    muscle: j['muscle']?.toString(),
    primaryMuscle: j['primaryMuscle']?.toString(),
    equipment: j['equipment']?.toString(),
    mode: _mode(j['mode']),
    weightUnit: (j['weightUnit'] ?? 'kg').toString(),
    sets: _maps(j['sets']).map(WorkoutSet.fromJson).toList(),
    restBetweenSetsSec: _int(j['restBetweenSetsSec']),
    color: j['color']?.toString(),
    notes: j['notes']?.toString(),
    order: _int(j['order']),
  );

  /// The add/update body. Mirrors the controller's `EXERCISE_FIELDS`
  /// whitelist — anything outside it is dropped server-side anyway.
  Map<String, dynamic> toJson() => {
    'name': name,
    if (catalogId != null) 'catalogId': catalogId,
    if (customExercise != null) 'customExercise': customExercise,
    if (muscle != null) 'muscle': muscle,
    if (primaryMuscle != null) 'primaryMuscle': primaryMuscle,
    if (equipment != null) 'equipment': equipment,
    'mode': modeToApi(mode),
    'weightUnit': weightUnit,
    'sets': sets.map((s) => s.toJson()).toList(),
    'restBetweenSetsSec': restBetweenSetsSec,
    'color': color,
    'notes': notes,
  };

  RoutineExercise copyWith({
    String? name,
    String? muscle,
    Object? primaryMuscle = _keep,
    String? equipment,
    ExerciseMode? mode,
    String? weightUnit,
    List<WorkoutSet>? sets,
    int? restBetweenSetsSec,
    Object? color = _keep,
    Object? notes = _keep,
  }) => RoutineExercise(
    id: id,
    name: name ?? this.name,
    catalogId: catalogId,
    customExercise: customExercise,
    muscle: muscle ?? this.muscle,
    primaryMuscle:
        primaryMuscle == _keep ? this.primaryMuscle : primaryMuscle as String?,
    equipment: equipment ?? this.equipment,
    mode: mode ?? this.mode,
    weightUnit: weightUnit ?? this.weightUnit,
    sets: sets ?? this.sets,
    restBetweenSetsSec: restBetweenSetsSec ?? this.restBetweenSetsSec,
    color: color == _keep ? this.color : color as String?,
    notes: notes == _keep ? this.notes : notes as String?,
    order: order,
  );
}

/* -------------------------------------------------------------- routines -- */

class Routine {
  const Routine({
    required this.id,
    required this.name,
    this.order = 0,
    this.restBetweenExercisesSec = 0,
    this.exercises = const [],
  });

  final String id;
  final String name;
  final int order;
  final int restBetweenExercisesSec;
  final List<RoutineExercise> exercises;

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
    id: _id(j),
    name: (j['name'] ?? '').toString(),
    order: _int(j['order']),
    restBetweenExercisesSec: _int(j['restBetweenExercisesSec']),
    exercises: _maps(j['exercises']).map(RoutineExercise.fromJson).toList(),
  );

  /// For painting an accepted write before the refetch lands — the screen
  /// already knows what it asked for, so it does not have to wait to show it.
  Routine copyWith({
    String? name,
    int? restBetweenExercisesSec,
    List<RoutineExercise>? exercises,
  }) => Routine(
    id: id,
    name: name ?? this.name,
    order: order,
    restBetweenExercisesSec:
        restBetweenExercisesSec ?? this.restBetweenExercisesSec,
    exercises: exercises ?? this.exercises,
  );
}

/* ----------------------------------------------------------- plans -------- */

class WorkoutReminder {
  const WorkoutReminder({
    required this.id,
    required this.dayOfWeek,
    required this.time,
  });

  final String id;

  /// 0 = Sunday, matching `DateTime.weekday % 7`.
  final int dayOfWeek;

  /// `HH:mm`, 24-hour.
  final String time;

  factory WorkoutReminder.fromJson(Map<String, dynamic> j) => WorkoutReminder(
    id: _id(j),
    dayOfWeek: _int(j['dayOfWeek']),
    time: (j['time'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {'dayOfWeek': dayOfWeek, 'time': time};
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    this.order = 0,
    this.isActive = false,
    this.remindersEnabled = false,
    this.reminders = const [],
    this.routines = const [],
  });

  final String id;
  final String name;
  final int order;
  final bool isActive;
  final bool remindersEnabled;
  final List<WorkoutReminder> reminders;
  final List<Routine> routines;

  factory WorkoutPlan.fromJson(Map<String, dynamic> j) => WorkoutPlan(
    id: _id(j),
    name: (j['name'] ?? '').toString(),
    order: _int(j['order']),
    isActive: j['isActive'] == true,
    remindersEnabled: j['remindersEnabled'] == true,
    reminders: _maps(j['reminders']).map(WorkoutReminder.fromJson).toList(),
    routines: _maps(j['routines']).map(Routine.fromJson).toList(),
  );

  /// See [Routine.copyWith] — the same idea one level up.
  WorkoutPlan copyWith({
    String? name,
    bool? isActive,
    List<Routine>? routines,
  }) => WorkoutPlan(
    id: id,
    name: name ?? this.name,
    order: order,
    isActive: isActive ?? this.isActive,
    remindersEnabled: remindersEnabled,
    reminders: reminders,
    routines: routines ?? this.routines,
  );

  /// The plan with one of its routines swapped for an edited copy — see
  /// [Routine.copyWith]. Unknown ids are left alone rather than appended: the
  /// caller is replacing something it read out of this plan.
  WorkoutPlan withRoutine(Routine routine) => WorkoutPlan(
    id: id,
    name: name,
    order: order,
    isActive: isActive,
    remindersEnabled: remindersEnabled,
    reminders: reminders,
    routines: [
      for (final r in routines) r.id == routine.id ? routine : r,
    ],
  );
}

/* --------------------------------------------------------------- catalog -- */

/// One gendered animation behind a catalog entry.
class CatalogVariant {
  const CatalogVariant({required this.gender, required this.catalogId});

  final String gender;
  final String catalogId;

  factory CatalogVariant.fromJson(Map<String, dynamic> j) => CatalogVariant(
    gender: (j['gender'] ?? '').toString(),
    catalogId: (j['catalogId'] ?? '').toString(),
  );

  Map<String, dynamic> toJson() => {'gender': gender, 'catalogId': catalogId};
}

/// A row of the exercise picker's catalog.
///
/// The backend groups the gendered pair into one entry and hands both back in
/// [variants], so the picker shows one card per movement and the player can
/// swap the model without another round trip.
class ExerciseCatalogItem {
  const ExerciseCatalogItem({
    required this.catalogId,
    required this.name,
    this.muscle = '',
    this.equipment = '',
    this.gender = '',
    this.width = 0,
    this.height = 0,
    this.durationMs = 0,
    this.primaryMuscle = '',
    this.secondaryMuscles = const [],
    this.instructions = const [],
    this.variants = const [],
  });

  final String catalogId;
  final String name;
  final String muscle;
  final String equipment;
  final String gender;
  final double width;
  final double height;
  final int durationMs;
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final List<CatalogVariant> variants;

  double get aspectRatio => (width <= 0 || height <= 0) ? 1 : width / height;

  String get muscleLabel => primaryMuscle.isNotEmpty ? primaryMuscle : muscle;

  /// The derived steps, numbered the way the config screen's Notes field and
  /// the session's instruction block show them.
  String get numberedInstructions {
    if (instructions.isEmpty) return '';
    return [
      for (var i = 0; i < instructions.length; i++)
        '${i + 1}. ${instructions[i]}',
    ].join('\n');
  }

  /// The animation for [gender], falling back to whatever the catalog grouped
  /// first so a single-gender movement still plays.
  String animationIdFor(String? gender) {
    if (gender == null || gender.isEmpty) return catalogId;
    for (final v in variants) {
      if (v.gender.toLowerCase() == gender.toLowerCase()) return v.catalogId;
    }
    return catalogId;
  }

  factory ExerciseCatalogItem.fromJson(Map<String, dynamic> j) =>
      ExerciseCatalogItem(
        catalogId: (j['catalogId'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        muscle: (j['muscle'] ?? '').toString(),
        equipment: (j['equipment'] ?? '').toString(),
        gender: (j['gender'] ?? '').toString(),
        width: _double(j['width']) ?? 0,
        height: _double(j['height']) ?? 0,
        durationMs: _int(j['durationMs']),
        primaryMuscle: (j['primaryMuscle'] ?? '').toString(),
        secondaryMuscles: _strings(j['secondaryMuscles']),
        instructions: _strings(j['instructions']),
        variants: _maps(j['variants']).map(CatalogVariant.fromJson).toList(),
      );

  /// Round-trips [fromJson], for the on-disk copy of the catalog the picker
  /// filters against — see ExerciseCatalogCache.
  Map<String, dynamic> toJson() => {
    'catalogId': catalogId,
    'name': name,
    'muscle': muscle,
    'equipment': equipment,
    'gender': gender,
    'width': width,
    'height': height,
    'durationMs': durationMs,
    'primaryMuscle': primaryMuscle,
    'secondaryMuscles': secondaryMuscles,
    'instructions': instructions,
    'variants': [for (final v in variants) v.toJson()],
  };
}

/// A `{muscle, count}` pair from the picker's muscle dropdown.
class MuscleCount {
  const MuscleCount({required this.muscle, required this.count});

  final String muscle;
  final int count;

  factory MuscleCount.fromJson(Map<String, dynamic> j) => MuscleCount(
    muscle: (j['muscle'] ?? '').toString(),
    count: _int(j['count']),
  );

  Map<String, dynamic> toJson() => {'muscle': muscle, 'count': count};
}

/// An exercise the user typed in themselves.
class CustomExercise {
  const CustomExercise({
    required this.id,
    required this.name,
    this.muscle,
    this.equipment,
  });

  final String id;
  final String name;
  final String? muscle;
  final String? equipment;

  factory CustomExercise.fromJson(Map<String, dynamic> j) => CustomExercise(
    id: _id(j),
    name: (j['name'] ?? '').toString(),
    muscle: j['muscle']?.toString(),
    equipment: j['equipment']?.toString(),
  );
}

/// A row of the picker's "Previous exercises" section — something the user has
/// actually done before, most recent first.
class PreviousExercise {
  const PreviousExercise({
    required this.name,
    this.catalogId,
    this.customExercise,
    this.muscle,
    this.primaryMuscle,
    this.equipment,
    this.lastPerformedAt,
    this.timesPerformed = 0,
  });

  final String name;
  final String? catalogId;
  final String? customExercise;
  final String? muscle;
  final String? primaryMuscle;
  final String? equipment;
  final DateTime? lastPerformedAt;
  final int timesPerformed;

  String get muscleLabel => (primaryMuscle?.isNotEmpty ?? false)
      ? primaryMuscle!
      : (muscle ?? '');

  factory PreviousExercise.fromJson(Map<String, dynamic> j) => PreviousExercise(
    name: (j['name'] ?? '').toString(),
    catalogId: j['catalogId']?.toString(),
    customExercise: j['customExercise']?.toString(),
    muscle: j['muscle']?.toString(),
    primaryMuscle: j['primaryMuscle']?.toString(),
    equipment: j['equipment']?.toString(),
    lastPerformedAt: _date(j['lastPerformedAt']),
    timesPerformed: _int(j['timesPerformed']),
  );
}

/* -------------------------------------------------------------- sessions -- */

/// An exercise as it exists inside a live or finished session — the routine's
/// copy, with the sets the user actually logged.
class SessionExercise {
  const SessionExercise({
    required this.id,
    required this.name,
    this.catalogId,
    this.customExercise,
    this.muscle,
    this.primaryMuscle,
    this.equipment,
    this.mode = ExerciseMode.weights,
    this.weightUnit = 'kg',
    this.color,
    this.notes,
    this.restBetweenSetsSec = 0,
    this.sets = const [],
    this.order = 0,
  });

  final String id;
  final String name;
  final String? catalogId;
  final String? customExercise;
  final String? muscle;
  final String? primaryMuscle;
  final String? equipment;
  final ExerciseMode mode;
  final String weightUnit;
  final String? color;
  final String? notes;
  final int restBetweenSetsSec;
  final List<WorkoutSet> sets;
  final int order;

  String get muscleLabel => (primaryMuscle?.isNotEmpty ?? false)
      ? primaryMuscle!
      : (muscle ?? '');

  bool get isDone => sets.isNotEmpty && sets.every((s) => s.completed);

  int get completedCount => sets.where((s) => s.completed).length;

  factory SessionExercise.fromJson(Map<String, dynamic> j) => SessionExercise(
    id: _id(j),
    name: (j['name'] ?? '').toString(),
    catalogId: j['catalogId']?.toString(),
    customExercise: j['customExercise']?.toString(),
    muscle: j['muscle']?.toString(),
    primaryMuscle: j['primaryMuscle']?.toString(),
    equipment: j['equipment']?.toString(),
    mode: _mode(j['mode']),
    weightUnit: (j['weightUnit'] ?? 'kg').toString(),
    color: j['color']?.toString(),
    notes: j['notes']?.toString(),
    restBetweenSetsSec: _int(j['restBetweenSetsSec']),
    sets: _maps(j['sets']).map(WorkoutSet.fromJson).toList(),
    order: _int(j['order']),
  );
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.planId,
    required this.routineId,
    required this.planName,
    required this.routineName,
    this.status = 'active',
    this.startedAt,
    this.finishedAt,
    this.durationSec = 0,
    this.restBetweenExercisesSec = 0,
    this.exercises = const [],
  });

  final String id;
  final String planId;
  final String routineId;
  final String planName;
  final String routineName;

  /// `active` | `completed` | `abandoned`.
  final String status;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int durationSec;
  final int restBetweenExercisesSec;
  final List<SessionExercise> exercises;

  bool get isActive => status == 'active';

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
    id: _id(j),
    planId: (j['plan'] ?? '').toString(),
    routineId: (j['routineId'] ?? '').toString(),
    planName: (j['planName'] ?? '').toString(),
    routineName: (j['routineName'] ?? '').toString(),
    status: (j['status'] ?? 'active').toString(),
    startedAt: _date(j['startedAt']),
    finishedAt: _date(j['finishedAt']),
    durationSec: _int(j['durationSec']),
    restBetweenExercisesSec: _int(j['restBetweenExercisesSec']),
    exercises: _maps(j['exercises']).map(SessionExercise.fromJson).toList(),
  );
}

/// The "Nice workout!" numbers, computed server-side so the pie and the totals
/// agree with the history list.
class SessionSummary {
  const SessionSummary({
    this.durationSec = 0,
    this.exerciseCount = 0,
    this.completedSets = 0,
    this.volume = 0,
    this.muscles = const [],
  });

  final int durationSec;
  final int exerciseCount;
  final int completedSets;
  final double volume;

  /// Completed sets per muscle, already sorted largest-first — the pie's
  /// slices in order.
  final List<MuscleCount> muscles;

  factory SessionSummary.fromJson(Map<String, dynamic> j) => SessionSummary(
    durationSec: _int(j['durationSec']),
    exerciseCount: _int(j['exerciseCount']),
    completedSets: _int(j['completedSets']),
    volume: _double(j['volume']) ?? 0,
    muscles: _maps(j['muscles']).map(MuscleCount.fromJson).toList(),
  );
}

/// A session plus its summary, as `finish` and `get-workout-session` return it.
class SessionResult {
  const SessionResult({required this.session, required this.summary});

  final WorkoutSession session;
  final SessionSummary summary;
}

/// A row of the workout history list — totals only, not the sets.
class WorkoutSessionRow {
  const WorkoutSessionRow({
    required this.id,
    required this.planName,
    required this.routineName,
    this.status = 'completed',
    this.startedAt,
    this.durationSec = 0,
    this.exerciseCount = 0,
    this.completedSets = 0,
  });

  final String id;
  final String planName;
  final String routineName;
  final String status;
  final DateTime? startedAt;
  final int durationSec;
  final int exerciseCount;
  final int completedSets;

  factory WorkoutSessionRow.fromJson(Map<String, dynamic> j) =>
      WorkoutSessionRow(
        id: _id(j),
        planName: (j['planName'] ?? '').toString(),
        routineName: (j['routineName'] ?? '').toString(),
        status: (j['status'] ?? 'completed').toString(),
        startedAt: _date(j['startedAt']),
        durationSec: _int(j['durationSec']),
        exerciseCount: _int(j['exerciseCount']),
        completedSets: _int(j['completedSets']),
      );
}

/// One day of an exercise's history, oldest first — the chart behind the icon
/// on each exercise card.
class ExerciseHistoryPoint {
  const ExerciseHistoryPoint({
    required this.sessionId,
    this.date,
    this.sets = 0,
    this.totalReps = 0,
    this.bestWeight = 0,
    this.volume = 0,
    this.totalDurationSec = 0,
  });

  final String sessionId;
  final DateTime? date;
  final int sets;
  final int totalReps;
  final double bestWeight;
  final double volume;
  final int totalDurationSec;

  factory ExerciseHistoryPoint.fromJson(Map<String, dynamic> j) =>
      ExerciseHistoryPoint(
        sessionId: (j['sessionId'] ?? '').toString(),
        date: _date(j['date']),
        sets: _int(j['sets']),
        totalReps: _int(j['totalReps']),
        bestWeight: _double(j['bestWeight']) ?? 0,
        volume: _double(j['volume']) ?? 0,
        totalDurationSec: _int(j['totalDurationSec']),
      );
}

/// Range totals from `get-workout-stats`.
class WorkoutTotals {
  const WorkoutTotals({
    this.workouts = 0,
    this.durationSec = 0,
    this.completedSets = 0,
    this.volume = 0,
  });

  final int workouts;
  final int durationSec;
  final int completedSets;
  final double volume;

  factory WorkoutTotals.fromJson(Map<String, dynamic> j) => WorkoutTotals(
    workouts: _int(j['workouts']),
    durationSec: _int(j['durationSec']),
    completedSets: _int(j['completedSets']),
    volume: _double(j['volume']) ?? 0,
  );
}

/// Everything the stats page charts for one date range.
///
/// [sessions] carries the raw rows rather than per-day buckets: the server has
/// no idea which timezone the user is in, so the day a workout belongs to is
/// worked out on the phone.
class WorkoutStats {
  const WorkoutStats({
    this.totals = const WorkoutTotals(),
    this.muscles = const [],
    this.sessions = const [],
  });

  final WorkoutTotals totals;
  final List<MuscleCount> muscles;
  final List<WorkoutSessionRow> sessions;

  bool get isEmpty => sessions.isEmpty;

  factory WorkoutStats.fromJson(Map<String, dynamic> j) => WorkoutStats(
    totals: WorkoutTotals.fromJson(
      ((j['totals'] as Map?) ?? const {}).cast<String, dynamic>(),
    ),
    muscles: _maps(j['muscles']).map(MuscleCount.fromJson).toList(),
    sessions: _maps(j['sessions']).map(WorkoutSessionRow.fromJson).toList(),
  );
}

/* ---------------------------------------------------------- built plans -- */

/// A draft week from "Build me a routine", before the user accepts it.
///
/// The server's JSON is kept verbatim in [raw] alongside the typed fields:
/// a revision ("make day two shorter") sends the draft back for the model to
/// edit, and accepting it posts the same exercises on to the plan — so
/// anything this model does not read is still worth carrying unchanged.
class BuiltPlan {
  BuiltPlan.fromJson(this.raw)
    : summary = (raw['summary'] ?? '').toString(),
      routines = _maps(raw['routines']).map(BuiltRoutine.fromJson).toList();

  final Map<String, dynamic> raw;
  final String summary;
  final List<BuiltRoutine> routines;

  int get exerciseCount =>
      routines.fold(0, (total, routine) => total + routine.exercises.length);

  Map<String, dynamic> toJson() => raw;
}

class BuiltRoutine {
  BuiltRoutine.fromJson(this.raw)
    : name = (raw['name'] ?? '').toString(),
      focus = (raw['focus'] ?? '').toString(),
      exercises = _maps(raw['exercises']).map(BuiltExercise.fromJson).toList();

  final Map<String, dynamic> raw;
  final String name;
  final String focus;
  final List<BuiltExercise> exercises;

  Map<String, dynamic> toJson() => raw;
}

class BuiltExercise {
  BuiltExercise.fromJson(this.raw)
    : name = (raw['name'] ?? '').toString(),
      muscleLabel = ((raw['primaryMuscle'] ?? '').toString().isNotEmpty
                ? raw['primaryMuscle']
                : (raw['muscle'] ?? ''))
            .toString(),
      catalogId = (raw['catalogId'] ?? '').toString().isEmpty
          ? null
          : raw['catalogId'].toString(),
      setCount = _int(raw['setCount']),
      reps = raw['reps'] == null ? null : _int(raw['reps']),
      seconds = raw['seconds'] == null ? null : _int(raw['seconds']),
      restBetweenSetsSec = _int(raw['restBetweenSetsSec']);

  final Map<String, dynamic> raw;
  final String name;
  final String muscleLabel;

  /// Null when nothing in the catalog matched the name the model wrote — the
  /// exercise still works, it just has no animation behind it.
  final String? catalogId;

  final int setCount;
  final int? reps;
  final int? seconds;
  final int restBetweenSetsSec;

  Map<String, dynamic> toJson() => raw;
}
