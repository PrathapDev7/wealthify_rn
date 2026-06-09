import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../models/wallet_model.dart';

class WalletsRepository {
  WalletsRepository(this._api);
  final ApiClient _api;

  Future<List<WalletModel>> getWallets() async {
    final res = await _api.dio.get('get-wallets');
    final raw = (res.data['data'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => WalletModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> addWallet(Map<String, dynamic> data) =>
      _api.dio.post('add-wallet', data: data);
  Future<void> updateWallet(String id, Map<String, dynamic> data) =>
      _api.dio.put('update-wallet/$id', data: data);
  Future<void> deleteWallet(String id) => _api.dio.delete('delete-wallet/$id');
}

final walletsRepositoryProvider = Provider<WalletsRepository>(
  (ref) => WalletsRepository(ref.read(apiClientProvider)),
);

/// The user's wallets (with server-computed balances). Defined here so any
/// screen — including the editor — can `ref.invalidate` it after a mutation.
final walletsListProvider = FutureProvider.autoDispose<List<WalletModel>>(
  (ref) => ref.read(walletsRepositoryProvider).getWallets(),
);
