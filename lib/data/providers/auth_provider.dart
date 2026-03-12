import 'dart:io';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../../core/utils/storage_service.dart';
import '../models/course_model.dart';
import '../services/notification_service.dart'; // Import your notification service

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  // --- ADDED STATIC TOKEN FOR NOTIFICATION SERVICE ---
  static String? _staticToken;
  static String? get storedToken => _staticToken;
  // ---------------------------------------------------

  String? _token;
  UserModel? _user;
  bool _isAuthenticating = false;

  bool get isAuthenticated => _token != null;
  bool get isAuthenticating => _isAuthenticating;
  UserModel? get user => _user;
  String? get token => _token;

  // Check login status on app startup
  Future<void> checkLoginStatus() async {
    _token = await _storage.getToken();
    _staticToken = _token; // Sync to static variable

    if (_token != null) {
      // If we found a token, sync it with Django for push notifications
      NotificationService.getAndUploadToken();
      await fetchUserProfile();
    }
    notifyListeners();
  }

  // New method to fetch User Profile data from Django
  Future<void> fetchUserProfile() async {
    try {
      final response = await _apiService.getHomeData();
      if (response['user'] != null) {
        _user = UserModel.fromJson(response['user']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  // Handle Login
  Future<bool> login(String username, String password) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      final tokenResponse = await _apiService.login(username, password);

      if (tokenResponse != null) {
        _token = tokenResponse;
        _staticToken = tokenResponse;
        await _storage.saveToken(tokenResponse);

        // --- CRITICAL: FIREBASE CRASH-PROOFING ---
        // Humne isse try-catch mein dala hai taaki error aane par bhi login na ruke.
        try {
          await NotificationService.getAndUploadToken();
          print("✅ FCM Sync Attempted");
        } catch (firebaseErr) {
          // Agar Firebase initialized nahi hai toh sirf print karega, app nahi rukegi
          print("⚠️ Firebase Error (Syncing later): $firebaseErr");
        }

        await fetchUserProfile();

        _isAuthenticating = false;
        notifyListeners(); // 🔥 Ab ye line pakka chalegi aur screen badal jayegi!
        return true;
      }
    } catch (e) {
      print("❌ API Login Error: $e");
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

    final Map<String, dynamic> registrationData = {
      'first_name': firstName,
      'last_name': lastName,
      'username': username,
      'email': email,
      'password': password,
      'user_type': userType,
    };

    if (userType == 'Teacher') {
      registrationData['qualification'] = qualification;
      registrationData['experience'] = experience;
    }

    final success = await _apiService.register(registrationData);

    _isAuthenticating = false;
    notifyListeners();
    return success;
  }

  // Update Profile
  Future<bool> updateProfile(Map<String, String> data, File? image) async {
    final success = await _apiService.updateFullProfile(fields: data, imageFile: image);
    if (success) {
      await fetchUserProfile();
    }
    return success;
  }

  // Handle Logout
  Future<void> logout() async {
    _token = null;
    _staticToken = null; // Clear static token
    _user = null;
    await _storage.logout();
    notifyListeners();
  }
}