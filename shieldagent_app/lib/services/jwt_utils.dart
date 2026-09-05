import 'dart:convert';

/// Decodes a JWT payload without verifying the signature — fine here
/// because we only ever read back a token our own backend just gave us.
/// Used as a fallback for the agent's Mongo _id when a response (like
/// your register endpoints) doesn't echo it back directly.
class JwtUtils {
  JwtUtils._();

  static Map<String, dynamic>? decodePayload(String token) {
    try {
      final parts = token.split(".");
      if (parts.length != 3) return null;

      String normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static String? userId(String token) {
    final payload = decodePayload(token);
    return payload?["userId"]?.toString();
  }
}
