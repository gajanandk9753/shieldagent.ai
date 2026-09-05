import '../core/constants/api_constants.dart';
import 'api_service.dart';
import 'storage_service.dart';
import 'jwt_utils.dart';

/// "buyer-agent" or "vendor-agent" — mirrors the role strings your
/// backend already uses.
class AgentRole {
  static const buyer = "buyer-agent";
  static const vendor = "vendor-agent";
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// [displayName] is required either way — it's `name` for a buyer
  /// agent and `companyName` for a vendor agent, matching your two
  /// register controllers exactly (they use different field names).
  Future<void> register({
    required String role,
    required String displayName,
    required String email,
    required String password,
    double? budgetLimit, // buyer-agent only, required by your backend
  }) async {
    final isBuyer = role == AgentRole.buyer;
    final path = isBuyer
        ? ApiConstants.registerBuyer
        : ApiConstants.registerVendor;

    final body = <String, dynamic>{
      "email": email,
      "password": password,
      if (isBuyer) "name": displayName,
      if (!isBuyer) "companyName": displayName,
      if (isBuyer) "budgetLimit": budgetLimit ?? 0,
    };

    final res = await ApiService.instance
        .post(path, body: body, auth: AuthMode.none);
    await _persist(res, role, email);
  }

  Future<void> login({
    required String role,
    required String email,
    required String password,
  }) async {
    final path =
        role == AgentRole.buyer ? ApiConstants.loginBuyer : ApiConstants.loginVendor;

    final res = await ApiService.instance.post(
      path,
      body: {"email": email, "password": password},
      auth: AuthMode.none,
    );
    await _persist(res, role, email);
  }

  Future<void> _persist(
      Map<String, dynamic> res, String role, String email) async {
    final token = res["token"]?.toString() ?? "";
    final agent = res["agent"] as Map<String, dynamic>? ?? {};
    final apiKey = agent["apiKey"]?.toString() ?? "";

    // Register responses don't echo back the Mongo _id (only login does),
    // so fall back to decoding it straight out of the JWT payload.
    final agentId = agent["_id"]?.toString() ?? JwtUtils.userId(token);

    await StorageService.instance.saveSession(
      token: token,
      apiKey: apiKey,
      role: role,
      email: email,
      agentId: agentId,
    );
  }

  Future<void> logout() async {
    await StorageService.instance.clear();
  }
}
