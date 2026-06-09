import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../models/stats_model.dart';
import '../models/transaction_model.dart';

typedef ExpenseResult = ({List<TransactionModel> items, num total});

class TransactionsRepository {
  TransactionsRepository(this._api);
  final ApiClient _api;

  Future<StatsModel> getStats() async {
    final res = await _api.dio.get('get-stats');
    return StatsModel.fromResponse(res.data['response']);
  }

  Future<ExpenseResult> getExpenses(Map<String, dynamic> query) async {
    final res = await _api.dio.get('get-expenses', queryParameters: query);
    final raw = (res.data['expenses'] as List?) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((e) =>
            TransactionModel.fromJson(e.cast<String, dynamic>(), kind: 'expense'))
        .toList();
    return (items: items, total: (res.data['total_expenses'] ?? 0) as num);
  }

  Future<List<TransactionModel>> getIncomes(Map<String, dynamic> query) async {
    final res = await _api.dio.get('get-incomes', queryParameters: query);
    final data = res.data;
    final raw = data is List ? data : const [];
    return raw
        .whereType<Map>()
        .map((e) =>
            TransactionModel.fromJson(e.cast<String, dynamic>(), kind: 'income'))
        .toList();
  }

  Future<void> addExpense(Map<String, dynamic> data) =>
      _api.dio.post('add-expense', data: data);
  Future<void> updateExpense(String id, Map<String, dynamic> data) =>
      _api.dio.put('update-expense/$id', data: data);
  Future<void> deleteExpense(String id) => _api.dio.delete('delete-expense/$id');

  Future<void> addIncome(Map<String, dynamic> data) =>
      _api.dio.post('add-income', data: data);
  Future<void> updateIncome(String id, Map<String, dynamic> data) =>
      _api.dio.put('update-income/$id', data: data);
  Future<void> deleteIncome(String id) => _api.dio.delete('delete-income/$id');
}

final transactionsRepositoryProvider = Provider<TransactionsRepository>(
  (ref) => TransactionsRepository(ref.read(apiClientProvider)),
);
