import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/theme_controller.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../preferences/preferences_controller.dart';

/// App session: null = signed out, value = signed-in user. Loads from storage
/// on boot; the router redirects off this state (mirrors RN `index.tsx`).
class SessionController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final repo = ref.read(authRepositoryProvider);
    if (await repo.hasSession()) {
      final user = await repo.cachedUser();
      if (user != null) {
        Future.microtask(() => _refreshRemotePrefs());
      }
      return user;
    }
    return null;
  }

  Future<void> _refreshRemotePrefs() async {
    await ref.read(preferencesProvider.notifier).refreshFromServer();
    await ref.read(themeControllerProvider.notifier).refreshFromServer();
  }

  Future<void> login({required String mobile, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(mobile: mobile, password: password),
    );
    if (state.asData?.value != null) await _refreshRemotePrefs();
  }

  Future<void> register({
    required String mobile,
    required String password,
    required String username,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            mobile: mobile,
            password: password,
            username: username,
          ),
    );
    if (state.asData?.value != null) await _refreshRemotePrefs();
  }

  Future<void> refreshProfile() async {
    final user = await ref.read(authRepositoryProvider).getProfile();
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }

  /// Clears the session when the API rejects the stored token (401). Storage
  /// is already wiped by the ApiClient interceptor; this flips the state so
  /// the router redirect sends the user to the auth screen.
  Future<void> markUnauthenticated() async {
    state = const AsyncData(null);
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionController, UserModel?>(SessionController.new);
