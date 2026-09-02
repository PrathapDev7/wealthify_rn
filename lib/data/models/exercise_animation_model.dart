/// One row of the exercise animation catalog, without its composition.
///
/// The backend leaves the Lottie document out of list responses (it is
/// `select: false` on the schema), so this carries only what a picker or a
/// player needs to lay the animation out before fetching it.
class ExerciseAnimationModel {
  const ExerciseAnimationModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.muscle,
    required this.equipment,
    required this.width,
    required this.height,
    required this.durationMs,
  });

  /// The catalog path, e.g. `Men/Band/ABS/Resistance Band Cocoons Men.json`.
  /// Doubles as the document `_id` and as the key the composition endpoint takes.
  final String id;
  final String name;
  final String gender;
  final String muscle;
  final String equipment;
  final double width;
  final double height;
  final int durationMs;

  /// Canvas size is not constant across the catalog — 1100x1100, 1300x1100,
  /// 1100x1300 and 1300x1300 all occur — so the box has to follow the document
  /// rather than assuming a square.
  double get aspectRatio => (width <= 0 || height <= 0) ? 1 : width / height;

  factory ExerciseAnimationModel.fromJson(Map<String, dynamic> json) {
    return ExerciseAnimationModel(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      muscle: json['muscle']?.toString() ?? '',
      equipment: json['equipment']?.toString() ?? '',
      width: (json['width'] as num?)?.toDouble() ?? 0,
      height: (json['height'] as num?)?.toDouble() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
    );
  }
}
