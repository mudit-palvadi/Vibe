import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe/core/services/api_service.dart';
import 'package:vibe/core/services/google_auth_service.dart';
import 'package:vibe/core/services/session_storage.dart';
import 'package:vibe/feature/auth/repositories/auth_repository.dart';

class FakeGoogleAuth implements GoogleAuth {
  FakeGoogleAuth({this.credentials});

  GoogleSignInCredentials? credentials;

  bool signedOut = false;

  @override
  Future<GoogleSignInCredentials?> signIn() async => credentials;

  @override
  Future<GoogleSignInCredentials?> silentSignIn() async => credentials;

  @override
  Future<void> signOut() async {
    signedOut = true;
  }
}

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'BACKEND_URL=https://vibe.test');

    final directory = await Directory.systemTemp.createTemp('vibe_session');
    Hive.init(directory.path);
    await SessionStorage.init();
  });

  setUp(() async {
    await SessionStorage.clear();
  });

  test('the sign in stores the session token', () async {
    final google = FakeGoogleAuth(
      credentials: const GoogleSignInCredentials(
        accessToken: 'access',
        refreshToken: 'google-refresh',
        idToken: 'google-id-token',
      ),
    );

    final repository = AuthRepository(
      apiService: ApiService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({'session_token': 'session-1'}),
            200,
          ),
        ),
      ),
      googleAuth: google,
    );

    await repository.signInWithGoogle();

    expect(repository.token, 'session-1');
    expect(repository.isLoggedIn, isTrue);
    expect(SessionStorage.sessionToken, 'session-1');
    expect(SessionStorage.googleRefreshToken, 'google-refresh');
  });

  test('a sign in without an id token is not enough', () async {
    final google = FakeGoogleAuth(
      credentials: const GoogleSignInCredentials(accessToken: 'access'),
    );

    final repository = AuthRepository(
      apiService: ApiService(
        client: MockClient(
          (request) async => http.Response(jsonEncode({}), 200),
        ),
      ),
      googleAuth: google,
    );

    expect(
      repository.signInWithGoogle,
      throwsA(
        predicate(
          (error) => error.toString().contains('did not give an id token'),
        ),
      ),
    );
  });

  test('the session comes back when the app is opened again', () async {
    await SessionStorage.save(
      sessionToken: 'old-session',
      googleRefreshToken: 'google-refresh',
    );

    final repository = AuthRepository(
      apiService: ApiService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({'session_token': 'new-session'}),
            200,
          ),
        ),
      ),
      googleAuth: FakeGoogleAuth(),
    );

    expect(await repository.restoreSession(), isTrue);
    expect(repository.token, 'new-session');
  });

  test('a google session that is gone signs the user out', () async {
    await SessionStorage.save(
      sessionToken: 'old-session',
      googleRefreshToken: 'google-refresh',
    );

    final google = FakeGoogleAuth();

    final repository = AuthRepository(
      apiService: ApiService(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({'detail': 'Google session is not valid anymore'}),
            401,
          ),
        ),
      ),
      googleAuth: google,
    );

    expect(await repository.restoreSession(), isFalse);
    expect(repository.token, isNull);
    expect(SessionStorage.sessionToken, isNull);
    expect(google.signedOut, isTrue);
  });

  test('the sign out clears the session', () async {
    await SessionStorage.save(
      sessionToken: 'session-1',
      googleRefreshToken: 'google-refresh',
    );

    final google = FakeGoogleAuth();

    final repository = AuthRepository(
      apiService: ApiService(
        client: MockClient(
          (request) async => http.Response(jsonEncode({}), 200),
        ),
      ),
      googleAuth: google,
    );

    await repository.signOut();

    expect(repository.token, isNull);
    expect(repository.isLoggedIn, isFalse);
    expect(SessionStorage.sessionToken, isNull);
    expect(google.signedOut, isTrue);
  });
}
