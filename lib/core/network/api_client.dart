import 'package:dio/dio.dart';

import '../constants/env.dart';
import '../storage/secure_store.dart';

/// Thin wrapper around [Dio] that injects the bearer token, the
/// ngrok-skip header, and clears the session on 401 — mirroring the RN
/// `request`/`uploadRequest` helpers in `api.service.ts`.
class ApiClient {
  ApiClient(this._store) {
    dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {'ngrok-skip-browser-warning': 'true'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _store.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _store.clearSession();
            _onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final SecureStore _store;
  late final Dio dio;

  void Function()? _onUnauthorized;
  set onUnauthorized(void Function() callback) => _onUnauthorized = callback;

  /// Multipart upload (category icons → S3). Lets Dio set the boundary.
  Future<Response<dynamic>> upload(String path, FormData formData) =>
      dio.post(path, data: formData);
}
