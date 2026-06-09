import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../models/goal_model.dart';

class GoalsRepository {
  GoalsRepository(this._api);
  final ApiClient _api;

  Future<List<GoalModel>> getGoals() async {
    final res = await _api.dio.get('get-goals');
    final raw = (res.data['data'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => GoalModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> addGoal(Map<String, dynamic> data) =>
      _api.dio.post('add-goal', data: data);
  Future<void> updateGoal(String id, Map<String, dynamic> data) =>
      _api.dio.put('update-goal/$id', data: data);
  Future<void> contributeGoal(String id, num amount, {String? note}) =>
      _api.dio.post('contribute-goal/$id',
          data: {'amount': amount, 'note': ?note});
  Future<void> deleteGoal(String id) => _api.dio.delete('delete-goal/$id');
}

final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => GoalsRepository(ref.read(apiClientProvider)),
);
