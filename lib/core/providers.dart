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
