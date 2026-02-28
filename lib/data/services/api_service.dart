import 'dart:convert';
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
}

