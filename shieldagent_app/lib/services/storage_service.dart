import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage so the rest of the app never touches
/// raw storage keys directly.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _kToken = "shieldagent_jwt";
  static const _kApiKey = "shieldagent_api_key";
  static const _kRole = "shieldagent_role"; // "buyer-agent" | "vendor-agent"
  static const _kEmail = "shieldagent_email";
  static const _kAgentId = "shieldagent_agent_id";

  Future<void> saveSession({
    required String token,
    required String apiKey,
    required String role,
    required String email,
    String? agentId,
  }) async {
    await _storage.write(key: _kToken, value: token);
    await _storage.write(key: _kApiKey, value: apiKey);
    await _storage.write(key: _kRole, value: role);
    await _storage.write(key: _kEmail, value: email);
    if (agentId != null) {
      await _storage.write(key: _kAgentId, value: agentId);
    }
  }

  Future<String?> getToken() => _storage.read(key: _kToken);
  Future<String?> getApiKey() => _storage.read(key: _kApiKey);
  Future<String?> getRole() => _storage.read(key: _kRole);
  Future<String?> getEmail() => _storage.read(key: _kEmail);
  Future<String?> getAgentId() => _storage.read(key: _kAgentId);

  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
