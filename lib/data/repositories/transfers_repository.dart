import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';

class TransferModel {
  const TransferModel({
    required this.id,
    required this.fromWallet,
    required this.toWallet,
    required this.amount,
    required this.date,
    this.note,
  });

  final String id;
  final String fromWallet;
  final String toWallet;
  final num amount;
  final String date;
  final String? note;

  factory TransferModel.fromJson(Map<String, dynamic> j) => TransferModel(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        fromWallet: (j['fromWallet'] ?? '').toString(),
        toWallet: (j['toWallet'] ?? '').toString(),
        amount: (j['amount'] ?? 0) as num,
        date: (j['date'] ?? '').toString(),
        note: j['note']?.toString(),
      );
}

class TransfersRepository {
  TransfersRepository(this._api);
  final ApiClient _api;

  Future<List<TransferModel>> getTransfers() async {
    final res = await _api.dio.get('get-transfers');
    final raw = (res.data['data'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => TransferModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> addTransfer(Map<String, dynamic> data) =>
      _api.dio.post('add-transfer', data: data);
  Future<void> deleteTransfer(String id) =>
      _api.dio.delete('delete-transfer/$id');
}

final transfersRepositoryProvider = Provider<TransfersRepository>(
  (ref) => TransfersRepository(ref.read(apiClientProvider)),
);

final transfersListProvider = FutureProvider.autoDispose<List<TransferModel>>(
  (ref) => ref.read(transfersRepositoryProvider).getTransfers(),
);
