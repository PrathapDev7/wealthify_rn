import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/providers.dart';
import '../../core/storage/secure_store.dart';
import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._api, this._store);

  final ApiClient _api;
  final SecureStore _store;

  Future<UserModel> login({required String mobile, required String password}) async {
    final res = await _api.dio
        .post('login', data: {'mobile': mobile, 'password': password});
    return _persist(res.data);
  }

  Future<UserModel> register({
    required String mobile,
    required String password,
    required String username,
  }) async {
    final res = await _api.dio.post('register', data: {
      'mobile': mobile,
      'password': password,
      'username': username,
    });
    return _persist(res.data);
  }

  Future<UserModel> _persist(dynamic data) async {
    final token = data['token']?.toString();
    final user = UserModel.fromJson((data['data'] as Map).cast<String, dynamic>());
    if (token != null && token.isNotEmpty) await _store.writeToken(token);
    await _store.writeUserJson(jsonEncode(user.toJson()));
    return user;
  }

  Future<bool> hasSession() async =>
      (await _store.readToken())?.isNotEmpty ?? false;

  Future<UserModel?> cachedUser() async {
    final raw = await _store.readUserJson();
    if (raw == null) return null;
    return UserModel.fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
  }

  Future<UserModel> getProfile() async {
    final res = await _api.dio.get('get-profile');
    final user =
        UserModel.fromJson((res.data['data'] as Map).cast<String, dynamic>());
    await _store.writeUserJson(jsonEncode(user.toJson()));
    return user;
  }

  Future<void> updateProfile({required String username}) =>
      _api.dio.post('update-profile', data: {'username': username});

  Future<void> updatePassword(Map<String, dynamic> data) =>
      _api.dio.post('update-password', data: data);

  Future<void> logout() => _store.clearSession();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(apiClientProvider), ref.read(secureStoreProvider)),
);
