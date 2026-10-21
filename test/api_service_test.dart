import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vibe/core/services/api_service.dart';

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'BACKEND_URL=https://vibe.test');
  });

  test('the login sends the google id token', () async {
    late http.Request sent;

    final service = ApiService(
      client: MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode({'session_token': 'session-1'}), 200);
      }),
    );

    final response = await service.loginWithGoogle('google-id-token');

    expect(response['session_token'], 'session-1');
    expect(sent.url.toString(), 'https://vibe.test/auth/login');
    expect(sent.method, 'POST');
    expect(jsonDecode(sent.body), {'id_token': 'google-id-token'});
  });

  test('the login gives the detail of the error', () async {
    final service = ApiService(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({'detail': 'Invalid google id token'}),
          401,
        ),
      ),
    );

    expect(
      () => service.loginWithGoogle('bad-token'),
      throwsA(
        predicate(
          (error) => error.toString().contains('Invalid google id token'),
        ),
      ),
    );
  });

  test('the refresh sends the session token and the google refresh token', () async {
    late http.Request sent;

    final service = ApiService(
      client: MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode({'session_token': 'session-2'}), 200);
      }),
    );

    final response = await service.refreshSession(
      sessionToken: 'session-1',
      googleRefreshToken: 'google-refresh',
    );

    expect(response['session_token'], 'session-2');
    expect(sent.url.toString(), 'https://vibe.test/auth/refresh');
    expect(sent.headers['Authorization'], 'Bearer session-1');
    expect(jsonDecode(sent.body), {'refresh_token': 'google-refresh'});
  });

  test('the current user comes with the session token', () async {
    late http.Request sent;

    final service = ApiService(
      client: MockClient((request) async {
        sent = request;
        return http.Response(jsonEncode({'id': 'user-1'}), 200);
      }),
    );

    final response = await service.getCurrentUserData('session-1');

    expect(response['id'], 'user-1');
    expect(sent.url.toString(), 'https://vibe.test/auth/');
    expect(sent.headers['Authorization'], 'Bearer session-1');
  });

  test('a body that is not json gives the status code', () {
    expect(
      ApiService.detailOf(http.Response('not json', 500)),
      'The request failed with 500',
    );
  });
}
