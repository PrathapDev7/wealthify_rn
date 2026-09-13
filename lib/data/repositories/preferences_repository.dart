import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';

class PreferencesRepository {
  PreferencesRepository(this._api);
  final ApiClient _api;

  Future<Map<String, dynamic>> getPreferences() async {
    final res = await _api.dio.get('get-preferences');
    final data = res.data['response'];
    if (data is Map) return data.cast<String, dynamic>();
    return const {};
  }

  Future<Map<String, dynamic>> updatePreferences(
      Map<String, dynamic> data) async {
    final res = await _api.dio.put('update-preferences', data: data);
    final updated = res.data['response'];
    if (updated is Map) return updated.cast<String, dynamic>();
    return const {};
  }
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(ref.read(apiClientProvider)),
);
