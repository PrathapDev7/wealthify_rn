import '../../core/network/api_client.dart';

class CaloriesRepository {
  final ApiClient _api;

  CaloriesRepository(this._api);

  Future<Map<String, dynamic>> addCaloriesEntry({String? date}) async {
    final res = await _api.dio.post('add-calories', data: {'date': date});
    return res.data;
  }

  Future<Map<String, dynamic>> processFoodText(String entryId, String text) async {
    final res = await _api.dio.post('process-food-text', data: {
      'entryId': entryId,
      'text': text,
      'localHour': DateTime.now().hour,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> getDailyCalories({String? date}) async {
    final res = await _api.dio.get('get-daily-calories', queryParameters: {'date': date});
    return res.data;
  }

  Future<void> deleteMealItem(String itemId) async {
    await _api.dio.delete('delete-meal-item/$itemId');
  }

  Future<Map<String, dynamic>> updateCalorieGoals({
    int? calorieTarget,
    int? carbTarget,
    int? fatTarget,
    int? proteinTarget,
    int? sugarTarget,
    String? date,
  }) async {
    final res = await _api.dio.put('update-calorie-goals', data: {
      if (calorieTarget != null) 'calorieTarget': calorieTarget,
      if (carbTarget != null) 'carbTarget': carbTarget,
      if (fatTarget != null) 'fatTarget': fatTarget,
      if (proteinTarget != null) 'proteinTarget': proteinTarget,
      if (sugarTarget != null) 'sugarTarget': sugarTarget,
      if (date != null) 'date': date,
    });
    return res.data;
  }

  Future<Map<String, dynamic>> calculateCalorieGoals({
    required int age,
    required String gender,
    required double heightCm,
    required double weightKg,
    required String activityLevel,
    required String goal,
  }) async {
    final res = await _api.dio.post('calculate-calorie-goals', data: {
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel,
      'goal': goal,
    });
    return res.data;
  }
}
