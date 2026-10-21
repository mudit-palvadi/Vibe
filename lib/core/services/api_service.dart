import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vibe/core/constants.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// the backend takes the google id token and gives a session token back
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await _client.post(
      Uri.parse('${ServerConstant.serverURL}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id_token': idToken}),
    );

    if (response.statusCode != 200) {
      throw Exception(detailOf(response));
    }

    return jsonDecode(response.body);
  }

  /// the session token is given back, the google refresh token is the proof
  /// that the user is still signed in with google
  Future<Map<String, dynamic>> refreshSession({
    required String sessionToken,
    required String googleRefreshToken,
  }) async {
    final response = await _client.post(
      Uri.parse('${ServerConstant.serverURL}/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        ServerConstant.sessionHeader: sessionToken,
      },
      body: jsonEncode({'refresh_token': googleRefreshToken}),
    );

    if (response.statusCode != 200) {
      throw Exception(detailOf(response));
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getCurrentUserData(String token) async {
    final response = await _client.get(
      Uri.parse('${ServerConstant.serverURL}/auth'),
      headers: {ServerConstant.sessionHeader: token},
    );

    if (response.statusCode != 200) {
      throw Exception(detailOf(response));
    }

    return jsonDecode(response.body);
  }

  static String detailOf(http.Response response) {
    try {
      final body = jsonDecode(response.body);

      if (body is Map && body['detail'] != null) {
        return body['detail'].toString();
      }
    } catch (_) {
      // the body was not json, the status code is used instead
    }

    return 'The request failed with ${response.statusCode}';
  }
}
