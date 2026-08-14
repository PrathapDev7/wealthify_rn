import 'dart:ui';

enum MealType {
  breakfast('Breakfast', '\u{1F95E}'),
  lunch('Lunch', '\u{1F354}'),
  dinner('Dinner', '\u{1F37D}');

  const MealType(this.label, this.emoji);

  final String label;
  final String emoji;

  int get targetCalories => switch (this) {
        MealType.breakfast => 300,
        MealType.lunch => 550,
        MealType.dinner => 600,
      };

  static MealType fromString(String? value) {
    for (final e in values) {
      if (e.label.toLowerCase() == value?.toLowerCase()) return e;
    }
    return MealType.dinner;
  }
}

enum MealStatus {
  pending('Pending', const Color(0xFF9E9E9E)),
  inProgress('In Progress', const Color(0xFF2196F3)),
  completed('Completed', const Color(0xFF4CAF50));

  const MealStatus(this.label, this.color);

  final String label;
  final Color color;

  static MealStatus fromString(String? value) {
    for (final e in values) {
      if (e.label.toLowerCase() == value?.toLowerCase()) return e;
    }
    return MealStatus.pending;
  }
}

class MealItem {
  final String id;
  final String originalText;
  final String foodName;
  final String? portion;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final String status;
  final MealType mealType;
  final MealStatus mealStatus;

  MealItem({
    required this.id,
    required this.originalText,
    required this.foodName,
    this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    this.status = 'pending',
    this.mealType = MealType.dinner,
    this.mealStatus = MealStatus.pending,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        id: json['_id'] ?? '',
        originalText: json['originalText'] ?? '',
        foodName: json['foodName'] ?? '',
        portion: json['portion'],
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
        fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
        sugar: (json['sugar'] as num?)?.toDouble() ?? 0.0,
        status: json['status'] ?? 'pending',
        mealType: MealType.fromString(json['mealType'] as String?),
        mealStatus: MealStatus.fromString(json['mealStatus'] as String?),
      );
}

/// Body stats used to auto-calculate calorie/macro goals. Persisted on the
/// user so the "calculate automatically" flow can prefill on repeat visits.
class HealthProfile {
  final int? age;
  final String? gender; // 'male' | 'female' | 'other'
  final double? heightCm;
  final double? weightKg;
  final String activityLevel; // sedentary | light | moderate | active | very_active
  final String goal; // lose | maintain | gain

  const HealthProfile({
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.activityLevel = 'moderate',
    this.goal = 'maintain',
  });

  factory HealthProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HealthProfile();
    return HealthProfile(
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      activityLevel: json['activityLevel'] as String? ?? 'moderate',
      goal: json['goal'] as String? ?? 'maintain',
    );
  }
}

class DailyTotals {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;
  final int? calorieTarget;
  final int? carbTarget;
  final int? proteinTarget;
  final int? fatTarget;
  final int? sugarTarget;

  DailyTotals({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sugar,
    this.calorieTarget,
    this.carbTarget,
    this.proteinTarget,
    this.fatTarget,
    this.sugarTarget,
  });

  int get caloriesLeft => (calorieTarget ?? calories) - calories;
  double get carbProgress =>
      carbTarget == null || carbTarget == 0 ? 100.0 : (carbs / carbTarget! * 100).clamp(0.0, 100.0);
  double get fatProgress =>
      fatTarget == null || fatTarget == 0 ? 100.0 : (fat / fatTarget! * 100).clamp(0.0, 100.0);
  double get proteinProgress =>
      proteinTarget == null || proteinTarget == 0 ? 100.0 : (protein / proteinTarget! * 100).clamp(0.0, 100.0);
  double get sugarProgress =>
      sugarTarget == null || sugarTarget == 0 ? 100.0 : (sugar / sugarTarget! * 100).clamp(0.0, 100.0);

  factory DailyTotals.fromJson(Map<String, dynamic>? json) {
    if (json == null) return DailyTotals(calories: 0, protein: 0, carbs: 0, fat: 0, fiber: 0, sugar: 0);
    return DailyTotals(
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0.0,
      sugar: (json['sugar'] as num?)?.toDouble() ?? 0.0,
      calorieTarget: (json['calorieTarget'] as num?)?.toInt(),
      carbTarget: (json['carbTarget'] as num?)?.toInt(),
      proteinTarget: (json['proteinTarget'] as num?)?.toInt(),
      fatTarget: (json['fatTarget'] as num?)?.toInt(),
      sugarTarget: (json['sugarTarget'] as num?)?.toInt(),
    );
  }
}
