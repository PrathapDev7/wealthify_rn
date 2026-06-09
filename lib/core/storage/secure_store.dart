import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Sensitive session storage (token + cached user), mirroring the RN app's
/// `wealthify_token` / `wealthify_user` AsyncStorage keys.
class SecureStore {
  SecureStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kToken = 'wealthify_token';
  static const _kUser = 'wealthify_user';

  Future<String?> readToken() => _storage.read(key: _kToken);
  Future<void> writeToken(String value) =>
      _storage.write(key: _kToken, value: value);

  Future<String?> readUserJson() => _storage.read(key: _kUser);
  Future<void> writeUserJson(String value) =>
      _storage.write(key: _kUser, value: value);

  Future<void> clearSession() async {
    await _storage.delete(key: _kToken);
    await _storage.delete(key: _kUser);
  }
}
