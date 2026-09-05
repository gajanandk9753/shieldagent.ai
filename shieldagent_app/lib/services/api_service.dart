import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

enum AuthMode { none, apiKey, jwt }

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code; // e.g. "AGENT_SUSPENDED"
  final Map<String, dynamic>? body; // full response body, for extra fields
  ApiException(this.message, {this.statusCode, this.code, this.body});

  @override
  String toString() => message;
}

/// Thin wrapper around http calls. Every screen should go through this
/// instead of calling http.* directly, so auth headers stay consistent.
class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  Future<Map<String, String>> _headers(AuthMode mode) async {
    final headers = {"Content-Type": "application/json"};
    if (mode == AuthMode.apiKey) {
      final key = await StorageService.instance.getApiKey();
      if (key != null) headers["x-api-key"] = key;
    } else if (mode == AuthMode.jwt) {
      final token = await StorageService.instance.getToken();
      if (token != null) headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  Uri _uri(String path) => Uri.parse("${ApiConstants.baseUrl}$path");

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = res.body.isEmpty
          ? {}
          : jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      body = {};
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    if (res.statusCode == 423) {
      throw ApiException(
        body["message"]?.toString() ?? "Agent suspended",
        statusCode: 423,
        code: body["code"]?.toString() ?? "AGENT_SUSPENDED",
        body: body,
      );
    }

    throw ApiException(
      body["message"]?.toString() ?? "Something went wrong (${res.statusCode})",
      statusCode: res.statusCode,
      body: body,
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    AuthMode auth = AuthMode.jwt,
  }) async {
    final res = await http.get(_uri(path), headers: await _headers(auth));
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    AuthMode auth = AuthMode.jwt,
  }) async {
    final res = await http.post(
      _uri(path),
      headers: await _headers(auth),
      body: jsonEncode(body ?? {}),
    );
    return _decode(res);
  }

  /// Your report-price-change route is a GET that reads req.body.newAmount.
  /// The plain `http.get()` call has no body parameter, so this builds the
  /// request manually. (Worth changing that route to POST server-side —
  /// a GET that mutates state and needs a body is an easy target to trip
  /// over by accident.)
  Future<Map<String, dynamic>> getWithBody(
    String path, {
    Map<String, dynamic>? body,
    AuthMode auth = AuthMode.jwt,
  }) async {
    final request = http.Request("GET", _uri(path))
      ..headers.addAll(await _headers(auth))
      ..body = jsonEncode(body ?? {});
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res);
  }
}
