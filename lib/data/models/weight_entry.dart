class WeightEntry {
  final String id;
  final String date; // yyyy-MM-dd
  final double weightKg;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        id: json['_id'] as String? ?? '',
        date: json['date'] as String? ?? '',
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.0,
      );
}

/// One day's calorie/macro totals, used by the history/trends view.
class DailyCalorieSummary {
  final String date; // yyyy-MM-dd
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double sugar;
  final int? calorieTarget;

  const DailyCalorieSummary({
    required this.date,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.sugar,
    this.calorieTarget,
  });

  factory DailyCalorieSummary.fromJson(Map<String, dynamic> json) =>
      DailyCalorieSummary(
        date: json['date'] as String? ?? '',
        calories: (json['calories'] as num?)?.toInt() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0.0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
        sugar: (json['sugar'] as num?)?.toDouble() ?? 0.0,
        calorieTarget: (json['calorieTarget'] as num?)?.toInt(),
      );
}
