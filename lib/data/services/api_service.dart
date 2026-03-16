import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  // Helper to get headers with Auth Token
  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Token $token',
    };
  }

  // 1. Fetch Home Data (Categories + Popular Courses)
  Future<Map<String, dynamic>> getHomeData() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.home),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load home data');
    }
  }

  // 2. Fetch All Courses
  Future<List<dynamic>> getAllCourses() async {
    final response = await http.get(
      Uri.parse(ApiEndpoints.courses),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load courses');
    }
  }

  // --- NEW: Smart Login (Supports Username or Email) ---
  Future<Map<String, dynamic>?> login(String loginId, String password) async {
    try {

      final String loginUrl = "${ApiEndpoints.baseUrl}/login/";
      debugPrint("Connecting to: $loginUrl");

      final response = await http.post(
        Uri.parse(loginUrl),
        body: json.encode({
          'login_id': loginId.trim(), // Can be email or username
          'password': password
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body); // Returns token, username, user_type
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- NEW: Registration with OTP ---
  Future<bool> apiRegister(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/register/"),
        body: json.encode(data),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Registration Error: $e");
      return false;
    }
  }

  // --- NEW: Verify Email OTP ---
  Future<Map<String, dynamic>?> verifyEmailOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/verify-email/"),
        body: json.encode({'email': email, 'otp': otp}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body); // Returns token on success
      }
      return null;
    } catch (e) {
      debugPrint("OTP Verification Error: $e");
      return null;
    }
  }

  // --- NEW: Google Sign-In ---
  Future<Map<String, dynamic>?> googleLogin(Map<String, dynamic> googleData) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/google-login/"),
        body: json.encode(googleData),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Google Login Error: $e");
      return null;
    }
  }

  // 4. Fetch Courses by Category Slug
  Future<List<dynamic>> getCoursesByCategory(String categorySlug) async {
    final response = await http.get(
      Uri.parse("${ApiEndpoints.courses}?category_slug=$categorySlug"),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load category courses');
    }
  }

  // 5. Enroll in Course
  Future<bool> enrollInCourse(int courseId, String paymentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/enroll/'),
        headers: headers,
        body: jsonEncode({
          'course_id': courseId,
          'razorpay_payment_id': paymentId,
        }),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("Enrollment Error: $e");
      return false;
    }
  }

  // 6. Update Profile
  Future<bool> updateFullProfile({
    required Map<String, String> fields,
    File? imageFile,
  }) async {
    var request = http.MultipartRequest(
      'PATCH',
      Uri.parse(ApiEndpoints.profile),
    );

    request.headers.addAll(await _getHeaders());
    request.fields.addAll(fields);

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath('profile.photo', imageFile.path));
    }

    final response = await request.send();
    return response.statusCode == 200;
  }

  // 7. Change Password
  Future<bool> changePassword(String oldPass, String newPass) async {
    final response = await http.post(
      Uri.parse("${ApiEndpoints.baseUrl}/change-password/"),
      body: json.encode({
        'old_password': oldPass,
        'new_password': newPass,
      }),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

  // 8. Lesson Progress Tracking
  Future<bool> markLessonAsComplete(int lessonId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/lessons/$lessonId/complete/'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error marking lesson complete: $e");
      return false;
    }
  }

  Future<List<dynamic>> getMyCourses() async {
    final String cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
    final String url = "${ApiEndpoints.myLearning}?t=$cacheBuster";

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load enrolled courses');
    }
  }

  Future<void> updateVideoProgress(int lessonId, double seconds) async {
    try {
      final Map<String, String> authHeaders = await _getHeaders();
      await _dio.post(
        '/lessons/$lessonId/update-progress/',
        data: {'last_position': seconds},
        options: Options(headers: authHeaders),
      );
    } catch (e) {
      debugPrint("Error syncing progress: $e");
    }
  }

  // ✅ NEW: Get latest video position from backend
  Future<double?> getLatestVideoProgress(int lessonId) async {
    try {
      // Hum direct http use kar rahe hain consistent rehne ke liye
      final response = await http.get(
        Uri.parse("${ApiEndpoints.baseUrl}/lessons/$lessonId/update-progress/"), // ✅ Check backend URL
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Backend agar 'last_position' ya 'saved_position' bhej raha hai toh wahi use karein
        return double.tryParse(data['last_position'].toString());
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching latest progress: $e");
      return null;
    }
  }

  // 9. Queries & Notifications
  Future<bool> postLessonQuery(int lessonId, String question) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/lessons/$lessonId/query/"),
        headers: await _getHeaders(),
        body: jsonEncode({"question": question}),
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("Error posting query: $e");
      return false;
    }
  }

  Future<List<dynamic>> getLessonQueries(int lessonId) async {
    try {
      final response = await http.get(
        Uri.parse("${ApiEndpoints.baseUrl}/lessons/$lessonId/queries/list/"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return [];
    } catch (e) {
      debugPrint("Error fetching queries: $e");
      return [];
    }
  }

  Future<List<dynamic>> getNotifications() async {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    try {
      final response = await http.get(
        Uri.parse("${ApiEndpoints.baseUrl}/notifications/?t=$timestamp"),
        headers: await _getHeaders(),
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return [];
    } catch (e) {
      debugPrint("Network Error fetching notifications: $e");
      return [];
    }
  }

  Future<bool> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/notifications/$notificationId/read/"),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/resend-otp/"),
        body: json.encode({'email': email}),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}