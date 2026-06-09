import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../models/budget_model.dart';

class BudgetsRepository {
  BudgetsRepository(this._api);
  final ApiClient _api;

  Future<BudgetModel> getBudgets() async {
    final res = await _api.dio.get('get-budgets');
    return BudgetModel.fromResponse(res.data['response']);
  }

  Future<void> addBudgets(Map<String, num> budgets) =>
      _api.dio.post('add-budgets', data: {'budgets': budgets});

  Future<void> updateBudgets(String id, Map<String, num> budgets) =>
      _api.dio.put('update-budgets/$id', data: {'budgets': budgets});

  /// Upsert: update the existing budget doc, or create one if none exists.
  Future<void> save(BudgetModel current, Map<String, num> merged) {
    final id = current.id;
    return id != null ? updateBudgets(id, merged) : addBudgets(merged);
  }
}

final budgetsRepositoryProvider = Provider<BudgetsRepository>(
  (ref) => BudgetsRepository(ref.read(apiClientProvider)),
);
