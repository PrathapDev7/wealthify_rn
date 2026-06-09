import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../models/insights_model.dart';

class InsightsRepository {
  InsightsRepository(this._api);
  final ApiClient _api;

  Future<InsightsModel> getInsights() async {
    final res = await _api.dio.get('get-insights');
    return InsightsModel.fromData(res.data['data']);
  }
}

final insightsRepositoryProvider = Provider<InsightsRepository>(
  (ref) => InsightsRepository(ref.read(apiClientProvider)),
);
