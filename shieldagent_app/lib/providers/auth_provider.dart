import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  String? role; // AgentRole.buyer | AgentRole.vendor
  String? email;
  bool isLoading = false;
  String? errorMessage;

  Future<void> bootstrap() async {
    final hasSession = await StorageService.instance.hasSession();
    if (hasSession) {
      role = await StorageService.instance.getRole();
      email = await StorageService.instance.getEmail();
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({
    required String role,
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await AuthService.instance.login(
        role: role,
        email: email,
        password: password,
      );
      this.role = role;
      this.email = email;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = "Couldn't reach the server. Try again.";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String role,
    required String displayName,
    required String email,
    required String password,
    double? budgetLimit,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await AuthService.instance.register(
        role: role,
        displayName: displayName,
        email: email,
        password: password,
        budgetLimit: budgetLimit,
      );
      this.role = role;
      this.email = email;
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = "Couldn't reach the server. Try again.";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await AuthService.instance.logout();
    role = null;
    email = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
