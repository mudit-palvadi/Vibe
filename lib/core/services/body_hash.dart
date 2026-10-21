import 'dart:convert';

import 'package:crypto/crypto.dart';

/// cloudfront signs the request it sends to the lambda, so a request that has
/// a body needs the hash of that body
String sha256Hex(String body) => sha256.convert(utf8.encode(body)).toString();

/// the headers every request with a body needs
Map<String, String> bodyHeaders(String body, {String? sessionToken}) {
  return {
    'Content-Type': 'application/json',
    'x-amz-content-sha256': sha256Hex(body),
    'x-vibe-auth': ?sessionToken,
  };
}
