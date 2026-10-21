import 'package:vibe/core/models/user_model.dart';
import 'package:vibe/core/services/api_service.dart';
import 'package:vibe/core/services/google_auth_service.dart';
import 'package:vibe/core/services/session_storage.dart';

class AuthRepository {
  AuthRepository({
    ApiService? apiService,
    GoogleAuth? googleAuth,
  }) : _api = apiService ?? ApiService(),
       _googleAuth = googleAuth ?? GoogleAuthService();

  final ApiService _api;
  final GoogleAuth _googleAuth;

  String? _sessionToken;

  String? get token => _sessionToken;

  bool get isLoggedIn => _sessionToken != null;

  /// brings the session back when the app is opened again
  Future<bool> restoreSession() async {
    _sessionToken = SessionStorage.sessionToken;

    if (_sessionToken == null) {
      return false;
    }

    // the session token works for 30 days, it is checked first
    if (await _sessionTokenWorks()) {
      return true;
    }

    // the google refresh token proves that the user is still there, on the
    // phone google does not hand it over so this does not work there
    if (await refreshSession()) {
      return true;
    }

    // on the phone google can give a new id token without asking the user
    if (await _signInSilently()) {
      return true;
    }

    await signOut();
    return false;
  }

  /// asks the backend if the session token is still good
  Future<bool> _sessionTokenWorks() async {
    try {
      await _api.getCurrentUserData(_sessionToken!);

      return true;
    } catch (_) {
      return false;
    }
  }

  /// signs in again with google without asking the user for anything
  Future<bool> _signInSilently() async {
    try {
      final credentials = await _googleAuth.silentSignIn();
      final idToken = credentials?.idToken;

      if (idToken == null) {
        return false;
      }

      final response = await _api.loginWithGoogle(idToken);

      _sessionToken = response['session_token'] as String;

      await SessionStorage.save(sessionToken: _sessionToken!);

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    final credentials = await _googleAuth.signIn();

    if (credentials == null || credentials.idToken == null) {
      throw Exception('The google sign in did not give an id token');
    }

    final response = await _api.loginWithGoogle(credentials.idToken!);

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

    final response = await _api.getCurrentUserData(_sessionToken!);

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
      final response = await _api.refreshSession(
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
