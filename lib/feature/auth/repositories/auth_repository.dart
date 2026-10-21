import 'package:vibe/core/models/user_model.dart';
import 'package:vibe/core/services/api_service.dart';
import 'package:vibe/core/services/google_auth_service.dart';
import 'package:vibe/core/services/session_storage.dart';

class AuthRepository {
  AuthRepository({GoogleAuthService? googleAuthService})
    : _googleAuth = googleAuthService ?? GoogleAuthService();

  final GoogleAuthService _googleAuth;

  String? _sessionToken;

  String? get token => _sessionToken;

  bool get isLoggedIn => _sessionToken != null;

  /// brings the session back when the app is opened again
  Future<bool> restoreSession() async {
    _sessionToken = SessionStorage.sessionToken;

    if (_sessionToken == null) {
      return false;
    }

    if (await refreshSession()) {
      return true;
    }

    await signOut();
    return false;
  }

  Future<void> signInWithGoogle() async {
    final credentials = await _googleAuth.signIn();

    if (credentials == null || credentials.idToken == null) {
      throw Exception('The google sign in did not give an id token');
    }

    final response = await ApiService.loginWithGoogle(credentials.idToken!);

    _sessionToken = response['session_token'] as String;

    await SessionStorage.save(
      sessionToken: _sessionToken!,
      googleRefreshToken: credentials.refreshToken,
    );
  }

  Future<UserModel?> fetchCurrentUser() async {
    if (_sessionToken == null) {
      return null;
    }

    final response = await ApiService.getCurrentUserData(_sessionToken!);

    return UserModel.fromJson(response);
  }

  /// asks the backend for a new session token, the google refresh token is
  /// what proves that the user is still there
  Future<bool> refreshSession() async {
    final googleRefreshToken = SessionStorage.googleRefreshToken;

    if (_sessionToken == null || googleRefreshToken == null) {
      return false;
    }

    try {
      final response = await ApiService.refreshSession(
        sessionToken: _sessionToken!,
        googleRefreshToken: googleRefreshToken,
      );

      _sessionToken = response['session_token'] as String;
      await SessionStorage.save(sessionToken: _sessionToken!);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    _sessionToken = null;

    await SessionStorage.clear();
    await _googleAuth.signOut();
  }
}
