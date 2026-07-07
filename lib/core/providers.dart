import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'network/api_client.dart';
import 'storage/prefs.dart';
import 'storage/secure_store.dart';

/// Overridden in `main()` after async initialization.
final prefsProvider = Provider<Prefs>(
  (ref) => throw UnimplementedError('prefsProvider must be overridden in main()'),
);

final secureStoreProvider = Provider<SecureStore>(
  (ref) => SecureStore(const FlutterSecureStorage()),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.read(secureStoreProvider)),
);

/// Monotonic counter bumped whenever transaction data is mutated (add / edit /
/// delete). The always-alive shell tabs (Home, Transactions, Analytics) live in
/// an `IndexedStack`, so their `autoDispose` data providers stay cached across
/// tab switches and would otherwise show stale data until a manual pull-to-
/// refresh. Those providers `ref.watch(dataRefreshProvider)` so a bump forces a
/// refetch; mutations bump it via [DataRefreshNotifier.bump] (see
/// `TransactionsRepository`).
final dataRefreshProvider =
    NotifierProvider<DataRefreshNotifier, int>(DataRefreshNotifier.new);

class DataRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Signals that shared data changed; watchers refetch.
  void bump() => state++;
}
