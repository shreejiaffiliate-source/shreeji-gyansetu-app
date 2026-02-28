import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../core/utils/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  String? _token;
  bool _isAuthenticating = false;

  bool get isAuthenticated => _token != null;
  bool get isAuthenticating => _isAuthenticating;

  // Check login status on app startup
  Future<void> checkLoginStatus() async {
    _token = await _storage.getToken();
    notifyListeners();
  }

  // Handle Login
  Future<bool> login(String username, String password) async {
    _isAuthenticating = true;
    notifyListeners();

    final token = await _apiService.login(username, password);

    if (token != null) {
      _token = token;
      await _storage.saveToken(token);
      _isAuthenticating = false;
      notifyListeners();
      return true;
    }

    _isAuthenticating = false;
    notifyListeners();
    return false;
  }

  // Handle Registration
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String userType,
    String? qualification,
    String? experience,
  }) async {
    _isAuthenticating = true;
    notifyListeners();

    // Prepare the data map
    final Map<String, dynamic> registrationData = {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'password': password,
      'user_type': userType,
    };

    // Add teacher fields only if necessary
    if (userType == 'Teacher') {
      registrationData['qualification'] = qualification;
      registrationData['experience'] = experience;
    }

    final success = await _apiService.register(registrationData);

    _isAuthenticating = false;
    notifyListeners();
    return success;
  }

  // Handle Logout
  Future<void> logout() async {
    _token = null;
    await _storage.logout();
    notifyListeners();
  }
}