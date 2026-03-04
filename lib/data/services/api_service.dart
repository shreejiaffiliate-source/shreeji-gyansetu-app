import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_endpoints.dart';
import '../../core/utils/storage_service.dart';

class ApiService {
  final StorageService _storage = StorageService();

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
      headers: await _getHeaders(), // <-- ADD THIS LINE
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load courses');
    }
  }

  // 3. Login Service
  Future<String?> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.login),
      body: json.encode({'username': username, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['token']; // The DRF Token
    }
    return null;
  }

// Register Service

  Future<bool> register(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/register/"),
        body: data,
      );

      // Django usually returns 201 Created for successful registration
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("Registration Error: $e");
      return false;
    }
  }

  // 4. Fetch Courses by Category Slug
  Future<List<dynamic>> getCoursesByCategory(String categorySlug) async {
    // Appends the slug as a query parameter: ?category_slug=your-slug
    final response = await http.get(
      Uri.parse("${ApiEndpoints.courses}?category_slug=$categorySlug"),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load category courses');
    }

    // 5. To Enroll is Courses

  }

  Future<bool> enrollInCourse(int courseId) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiEndpoints.baseUrl}/enroll/"),
        body: json.encode({'course_id': courseId}),
        // Key must match Django request.data.get
        headers: await _getHeaders(),
      );

      // DEBUG: print(response.body);
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Update Profile

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

  Future<bool> changePassword(String oldPass, String newPass) async {
    final response = await http.post(
      Uri.parse("${ApiEndpoints.baseUrl}/change-password/"), // Ensure this matches urls.py
      body: json.encode({
        'old_password': oldPass,
        'new_password': newPass,
      }),
      headers: await _getHeaders(),
    );
    return response.statusCode == 200;
  }

// Lesson Progress

  Future<bool> markLessonAsComplete(int lessonId) async {
    try {
      // FIX: Use your existing helper instead of _storage.read
      final headers = await _getHeaders();

      final response = await http.post(
        // FIX: Use ApiEndpoints.baseUrl instead of undefined baseUrl
        Uri.parse('${ApiEndpoints.baseUrl}/lessons/$lessonId/complete/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        debugPrint("Lesson $lessonId marked complete successfully.");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error marking lesson complete: $e");
      return false;
    }
  }
  Future<List<dynamic>> getMyCourses() async {
    // 1. Generate a unique timestamp to force a fresh request
    final String cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();

    // 2. Append the timestamp to the URL (e.g., .../api/my-learning/?t=1709450000)
    final String url = "${ApiEndpoints.myLearning}?t=$cacheBuster";

    final response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      // Debug print to verify the fresh data is arriving
      final List<dynamic> data = json.decode(response.body);
      debugPrint("API: Fetched fresh progress data: $data");
      return data;
    } else {
      throw Exception('Failed to load enrolled courses');
    }
  }

  Future<bool> postLessonQuery(int lessonId, String question) async {
    final url = "${ApiEndpoints.baseUrl}/lessons/$lessonId/query/"; // Matches Django URL

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({"question": question}),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      debugPrint("Error posting query: $e");
      return false;
    }
  }

  // lib/data/services/api_service.dart

  Future<List<dynamic>> getLessonQueries(int lessonId) async {
    final url = "${ApiEndpoints.baseUrl}/lessons/$lessonId/queries/list/";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching queries: $e");
      return [];
    }
  }

  Future<List<dynamic>> getNotifications() async {
    // Use a cache buster to ensure the badge updates in real-time
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String url = "${ApiEndpoints.baseUrl}/notifications/?t=$timestamp";

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(), // Essential for IsAuthenticated check
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("API Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("Network Error fetching notifications: $e");
      return [];
    }
  }

// Helper to clear the notification once clicked
  Future<bool> markNotificationAsRead(int notificationId) async {
    final String url = "${ApiEndpoints.baseUrl}/notifications/$notificationId/read/";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}




