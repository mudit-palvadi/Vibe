import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vibe/core/providers/current_user_notifier.dart';
import '../../../core/models/user_model.dart';
import '../repositories/auth_repository.dart';
part 'auth_viewmodel.g.dart';

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

@riverpod
class AuthViewModel extends _$AuthViewModel {
  late CurrentUserNotifier _currentUserNotifier;
  @override
  Future<UserModel?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    _currentUserNotifier = ref.watch(currentUserProvider.notifier);

    final isSignedIn = await repository.restoreSession();

    if (!isSignedIn) {
      return null;
    }

    final user = await repository.fetchCurrentUser();

    if (user != null) {
      _currentUserNotifier.addUser(user);
    }

    return user;
  }

  Future<void> loginWithGoogle() async {
    final repository = ref.read(authRepositoryProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await repository.signInWithGoogle();

      final user = await repository.fetchCurrentUser();

      if (user == null) {
        throw Exception('The user could not be loaded');
      }

      _currentUserNotifier.addUser(user);
      return user;
    });
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.signOut();
    state = const AsyncData(null);
  }
}
