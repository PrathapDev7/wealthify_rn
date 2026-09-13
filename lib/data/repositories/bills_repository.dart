import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../models/recurring_model.dart';
import '../models/wallet_model.dart';

class BillsRepository {
  BillsRepository(this._api);
  final ApiClient _api;

  Future<List<RecurringModel>> getUpcomingBills() async {
    final res = await _api.dio.get('get-upcoming-bills');
    final raw = (res.data['data'] as List?) ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => RecurringModel.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> markBill(String id, String status, {String? date}) {
    final data = <String, dynamic>{'status': status};
    if (date != null) data['date'] = date;
    return _api.dio.post('mark-bill/$id', data: data);
  }
}

final billsRepositoryProvider = Provider<BillsRepository>(
  (ref) => BillsRepository(ref.read(apiClientProvider)),
);

final upcomingBillsProvider = FutureProvider.autoDispose<List<RecurringModel>>(
  (ref) => ref.read(billsRepositoryProvider).getUpcomingBills(),
);

class DebtsRepository {
  DebtsRepository(this._api);
  final ApiClient _api;

  Future<({List<WalletModel> debts, num totalOwed})> getDebts() async {
    final res = await _api.dio.get('get-debts');
    final raw = (res.data['data'] as List?) ?? const [];
    final debts = raw
        .whereType<Map>()
        .map((e) => WalletModel.fromJson(e.cast<String, dynamic>()))
        .toList();
    return (debts: debts, totalOwed: (res.data['totalOwed'] ?? 0) as num);
  }
}

final debtsRepositoryProvider = Provider<DebtsRepository>(
  (ref) => DebtsRepository(ref.read(apiClientProvider)),
);

final debtsProvider =
    FutureProvider.autoDispose<({List<WalletModel> debts, num totalOwed})>(
  (ref) => ref.read(debtsRepositoryProvider).getDebts(),
);

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    this.body,
    this.read = false,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String? body;
  final bool read;
  final String? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        type: (j['type'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        body: j['body']?.toString(),
        read: j['read'] == true,
        createdAt: j['createdAt']?.toString(),
      );
}

class NotificationsRepository {
  NotificationsRepository(this._api);
  final ApiClient _api;

  Future<({List<AppNotification> items, int unread})> getNotifications() async {
    final res = await _api.dio.get('get-notifications');
    final raw = (res.data['data'] as List?) ?? const [];
    final items = raw
        .whereType<Map>()
        .map((e) => AppNotification.fromJson(e.cast<String, dynamic>()))
        .toList();
    return (items: items, unread: (res.data['unread'] ?? 0) as int);
  }

  Future<void> markRead(String id) =>
      _api.dio.put('read-notification/$id');
  Future<void> markAllRead() => _api.dio.put('read-notification/all');
  Future<void> registerPushToken(String token) =>
      _api.dio.post('register-push-token', data: {'token': token});
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(ref.read(apiClientProvider)),
);

final notificationsProvider = FutureProvider.autoDispose<
    ({List<AppNotification> items, int unread})>(
  (ref) => ref.read(notificationsRepositoryProvider).getNotifications(),
);
