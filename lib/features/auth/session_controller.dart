import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// App session: null = signed out, value = signed-in user. Loads from storage
/// on boot; the router redirects off this state (mirrors RN `index.tsx`).
class SessionController extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final repo = ref.read(authRepositoryProvider);
    if (await repo.hasSession()) return repo.cachedUser();
    return null;
  }

  Future<void> login({required String mobile, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(mobile: mobile, password: password),
    );
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
  }

  Future<void> refreshProfile() async {
    final user = await ref.read(authRepositoryProvider).getProfile();
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final sessionProvider =
    AsyncNotifierProvider<SessionController, UserModel?>(SessionController.new);
