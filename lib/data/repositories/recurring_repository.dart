import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../models/recurring_model.dart';

class RecurringRepository {
  RecurringRepository(this._api);
  final ApiClient _api;

  Future<List<RecurringModel>> getRecurring() async {
    final res = await _api.dio.get('get-recurring');
    final raw = (res.data['data'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => RecurringModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> addRecurring(Map<String, dynamic> data) =>
      _api.dio.post('add-recurring', data: data);
  Future<void> updateRecurring(String id, Map<String, dynamic> data) =>
      _api.dio.put('update-recurring/$id', data: data);
  Future<void> deleteRecurring(String id) =>
      _api.dio.delete('delete-recurring/$id');
}

final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => RecurringRepository(ref.read(apiClientProvider)),
);
