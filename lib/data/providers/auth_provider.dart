import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gyansetu/core/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../../core/utils/storage_service.dart';
import '../models/course_model.dart'; // Ensure this has UserModel
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storage = StorageService();

  static String? _staticToken;
  static String? get storedToken => _staticToken;

  String? _token;
  UserModel? _user;
  bool _isAuthenticating = false;

  bool get isAuthenticated => _token != null;
  bool get isAuthenticating => _isAuthenticating;
  UserModel? get user => _user;
  String? get token => _token;

  Future<void> checkLoginStatus() async {
    _token = await _storage.getToken();
    _staticToken = _token;
    if (_token != null) {
      NotificationService.getAndUploadToken();
      await fetchUserProfile();
    }
    notifyListeners();
  }

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

  Future<bool> login(String loginId, String password) async {
    _isAuthenticating = true;
    notifyListeners();
    try {
      final response = await _apiService.login(loginId, password);
      if (response != null && response['token'] != null) {
        _token = response['token'];
        _staticToken = _token;
        await _storage.saveToken(_token!);
        NotificationService.getAndUploadToken().catchError((e) => debugPrint("⚠️ Firebase Sync Error: $e"));
        await fetchUserProfile();
        _isAuthenticating = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("❌ API Login Error: $e");
    }
    _isAuthenticating = false;
    notifyListeners();
    return false;
  }

  // ✅ FIXED: Register method with correct data mapping
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

    try {
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
        registrationData['experience_years'] = experience;
      }

      // Pass 'registrationData' to the service
      bool success = await _apiService.apiRegister(registrationData);

      _isAuthenticating = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint("❌ Register Error: $e");
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    _isAuthenticating = true;
    notifyListeners();
    try {
      final response = await _apiService.verifyEmailOtp(email, otp);
      if (response != null && response['token'] != null) {
        _token = response['token'];
        _staticToken = _token;
        await _storage.saveToken(_token!);
        await fetchUserProfile();
        _isAuthenticating = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("❌ OTP Error: $e");
    }
    _isAuthenticating = false;
    notifyListeners();
    return false;
  }

  Future<bool> loginWithGoogle(Map<String, dynamic> googleData) async {
    _isAuthenticating = true;
    notifyListeners();
    try {
      final response = await _apiService.googleLogin(googleData);
      if (response != null && response['token'] != null) {
        _token = response['token'];
        _staticToken = _token;
        await _storage.saveToken(_token!);
        await fetchUserProfile();
        _isAuthenticating = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("❌ Google Login Error: $e");
    }
    _isAuthenticating = false;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    _token = null;
    _staticToken = null;
    _user = null;
    await _storage.logout();
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, String> data, File? image) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      final success = await _apiService.updateFullProfile(
          fields: data,
          imageFile: image
      );

      if (success) {
        // Profile update hone ke baad naya data fetch karo
        await fetchUserProfile();
      }

      _isAuthenticating = false;
      notifyListeners();
      return success;
    } catch (e) {
      debugPrint("❌ Update Profile Error: $e");
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/resend-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      // ✅ DEBUG: Terminal mein check karo status code kya aa raha hai
      print("DEBUG: Status Code: ${response.statusCode}");
      print("DEBUG: Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("DEBUG: Catch Error: $e");
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/reset-password/'), // ✅ Apna sahi URL check kar lena
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          'password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = json.decode(response.body);
        debugPrint("❌ Reset Password Error: ${data['error']}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Network Error: $e");
      return false;
    }
  }
}