import 'package:hive_flutter/hive_flutter.dart';

/// keeps the session token and the google refresh token on the device
class SessionStorage {
  static const String _boxName = 'session_box';
  static const String _sessionTokenKey = 'session_token';
  static const String _refreshTokenKey = 'google_refresh_token';

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  static String? get sessionToken => Hive.box(_boxName).get(_sessionTokenKey);

  static String? get googleRefreshToken =>
      Hive.box(_boxName).get(_refreshTokenKey);

  static Future<void> save({
    required String sessionToken,
    String? googleRefreshToken,
  }) async {
    final box = Hive.box(_boxName);

    await box.put(_sessionTokenKey, sessionToken);

    if (googleRefreshToken != null) {
      await box.put(_refreshTokenKey, googleRefreshToken);
    }
  }

  static Future<void> clear() async {
    await Hive.box(_boxName).clear();
  }
}
