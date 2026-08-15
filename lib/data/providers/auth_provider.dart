import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gyansetu/core/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../../core/utils/storage_service.dart';
import '../models/course_model.dart';
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

  // 🔥 YAHAN CHANGE KIYA HAI - getHomeData() hata kar getUserProfile() lagaya hai
  Future<void> fetchUserProfile() async {
    try {
      final response = await _apiService.getUserProfile();
      print("REAL PROFILE RESPONSE: $response");

      // Data extract karne ka safe tarika
      if (response.containsKey('user') && response['user'] != null) {
        _user = UserModel.fromJson(response['user']);
      } else {
        _user = UserModel.fromJson(response);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching profile: $e");
    }
  }

  // lib/data/providers/auth_provider.dart

  Future<bool> login(String loginId, String password, String requestedRole) async { // 🚀 Parameter add kiya
    _isAuthenticating = true;
    notifyListeners();
    try {
      // 🚀 API Service mein bhi role bhejo
      final response = await _apiService.login(loginId, password, requestedRole);

      if (response != null && response['token'] != null) {
        _token = response['token'];
        _staticToken = _token;
        await _storage.saveToken(_token!);

        String userRole = response['user_type'] ?? 'Student';
        await _storage.saveUserRole(userRole);

        await NotificationService.getAndUploadToken();
        await fetchUserProfile();
        _isAuthenticating = false;
        notifyListeners();
        return true;
      }
      throw Exception(response?['error'] ?? "Invalid Login Credentials");
    } catch (e) {
      _isAuthenticating = false;
      notifyListeners();
      rethrow;
    }
  }

  // auth_provider.dart mein ye update karo
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    required String userType, // 'Student' ya 'Teacher'
    String? qualification,
    String? experience,
  }) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      final Map<String, dynamic> registrationData = {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'password': password,
        'userType': userType, // Yahan 'Teacher' bhej rahe hain
      };

      if (userType == 'Teacher') {
        registrationData['qualification'] = qualification ?? '';
        registrationData['experience'] = experience ?? '0';
      }

      // ApiService mein sahi data bhej rahe hain
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

        // 🔥 YAHAN ASLI FIX HAI: Backend se aaye 'user_type' ko save karo
        String userRole = response['user_type'] ?? 'Student';
        await _storage.saveUserRole(userRole);

        // Notification aur Profile fetch karo
        await NotificationService.getAndUploadToken();
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

        // 🔥 YAHAN BHI ROLE SAVE KAREIN
        String userRole = response['user_type'] ?? 'Student';
        await _storage.saveUserRole(userRole);

        await NotificationService.getAndUploadToken();
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

  Future<String> updateProfile(Map<String, String> data, File? image) async {
    _isAuthenticating = true;
    notifyListeners();

    try {
      final String result = await _apiService.updateFullProfile(
          fields: data,
          imageFile: image
      );

      if (result == "success") {
        await fetchUserProfile();
        _isAuthenticating = false;
        notifyListeners();
        return "success";
      } else {
        _isAuthenticating = false;
        notifyListeners();
        return result;
      }
    } catch (e) {
      debugPrint("❌ Update Profile Error: $e");
      _isAuthenticating = false;
      notifyListeners();
      return "An unexpected error occurred. Please try again.";
    }
  }

  Future<bool> resendOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/resend-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

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

  // 🔥 YAHAN ADD KIYA: Naya Forgot Password Function
  Future<bool> forgotPassword(String email) async {
    _isAuthenticating = true;
    notifyListeners();
    try {
      // Dhyan rahe: Django mein iska URL /forgot-password/ hona chahiye
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/forgot-password/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      print("DEBUG: Forgot Password Status: ${response.statusCode}");
      print("DEBUG: Forgot Password Body: ${response.body}");

      _isAuthenticating = false;
      notifyListeners();

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("DEBUG: Forgot Password Error: $e");
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/reset-password/'),
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


  // AuthProvider class ke andar ye updated function daalein:
  Future<String> createCourse(Map<String, String> data, File? thumbnail) async {
    final token = await StorageService().getToken();
    if (token == null) return "User not authenticated";

    try {
      // 🚀 YAHAN FIX KIYA HAI: ApiConstants ki jagah ApiEndpoints kar diya
      var request = http.MultipartRequest('POST', Uri.parse(ApiEndpoints.teacherCreateCourse));
      request.headers.addAll({'Authorization': 'Token $token'});

      // Text fields add karein
      data.forEach((key, value) {
        request.fields[key] = value;
      });

      // Thumbnail image attach karein
      if (thumbnail != null) {
        request.files.add(await http.MultipartFile.fromPath('thumbnail', thumbnail.path));
      }

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 201) {
        return "success";
      } else {
        final errorData = jsonDecode(responseData.body);
        return errorData['error'] ?? "Failed to create course";
      }
    } catch (e) {
      return "An error occurred: $e";
    }
  }

  // 🚀 FETCH MODULES (Course ID ke hisaab se)
  Future<List<dynamic>> fetchModules(int courseId) async {
    final token = await StorageService().getToken();
    if (token == null) throw Exception("User not authenticated");

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherModules(courseId)),
        headers: {'Authorization': 'Token $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load modules");
      }
    } catch (e) {
      debugPrint("Error fetching modules: $e");
      return [];
    }
  }

  // 🚀 ADD NEW MODULE
  Future<bool> addModule(int courseId, String title) async {
    final token = await StorageService().getToken();
    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.teacherModules(courseId)),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          "title": title,
          "order": 0
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Error adding module: $e");
      return false;
    }
  }

  // 🚀 UPLOAD LESSON API
  Future<String> uploadLesson({
    required int moduleId,
    required String title,
    required String type,
    String? videoUrl,
    String? resources,
    bool isPreview = false,
    File? videoFile,
    File? pdfFile,
  }) async {
    final token = await StorageService().getToken();
    if (token == null) return "Authentication error";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiEndpoints.teacherAddLesson(moduleId)));
      request.headers.addAll({'Authorization': 'Token $token'});

      // Text fields
      request.fields['title'] = title;
      request.fields['lesson_type'] = type;
      request.fields['is_preview'] = isPreview.toString();
      if (videoUrl != null) request.fields['video_url'] = videoUrl;
      if (resources != null) request.fields['resources'] = resources;

      // MP4 Video File
      if (videoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('content_file', videoFile.path));
      }

      // PDF Notes File
      if (pdfFile != null) {
        request.files.add(await http.MultipartFile.fromPath('notes_file', pdfFile.path));
      }

      // 🚀 ASLI FIX YAHAN HAI: 5 minutes ka timeout lagaya hai taaki A13 crash na ho
      var responseStream = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception("Upload timed out! Please check your network connection.");
        },
      );

      var response = await http.Response.fromStream(responseStream);

      if (response.statusCode == 201) {
        return "success";
      } else {
        final errorData = jsonDecode(response.body);
        return errorData['error'] ?? "Failed to upload lesson";
      }
    } catch (e) {
      return "An error occurred: $e";
    }
  }

  // 🚀 TOGGLE COURSE STATUS
  Future<bool> toggleCourseStatus(int courseId) async {
    final token = await StorageService().getToken();
    if (token == null) return false;
    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.teacherToggleCourseStatus(courseId)),
        headers: {'Authorization': 'Token $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error toggling status: $e");
      return false;
    }
  }

  // 🚀 DELETE COURSE
  Future<bool> deleteCourse(int courseId) async {
    final token = await StorageService().getToken();
    if (token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse(ApiEndpoints.teacherDeleteCourse(courseId)),
        headers: {'Authorization': 'Token $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deleting course: $e");
      return false;
    }
  }

  // 🚀 UPDATE COURSE
  Future<String> updateCourse(int courseId, Map<String, String> data, File? thumbnail) async {
    final token = await StorageService().getToken();
    if (token == null) return "User not authenticated";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiEndpoints.teacherUpdateCourse(courseId)));
      request.headers.addAll({'Authorization': 'Token $token'});

      data.forEach((key, value) {
        request.fields[key] = value;
      });

      if (thumbnail != null) {
        request.files.add(await http.MultipartFile.fromPath('thumbnail', thumbnail.path));
      }

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        return "success";
      } else {
        final errorData = jsonDecode(responseData.body);
        return errorData['error'] ?? "Failed to update course";
      }
    } catch (e) {
      return "An error occurred: $e";
    }
  }

  // 🚀 UPDATE LESSON API
  // 🚀 UPDATE LESSON API (TIMEOUT FIX KE SATH)
  Future<String> updateLesson({
    required int lessonId,
    required String title,
    required String type,
    String? videoUrl,
    String? resources,
    bool isPreview = false,
    File? videoFile,
    File? pdfFile,
  }) async {
    final token = await StorageService().getToken();
    if (token == null) return "Authentication error";

    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiEndpoints.teacherUpdateLesson(lessonId)));
      request.headers.addAll({'Authorization': 'Token $token'});

      request.fields['title'] = title;
      request.fields['lesson_type'] = type;
      request.fields['is_preview'] = isPreview.toString();
      if (videoUrl != null) request.fields['video_url'] = videoUrl;
      if (resources != null) request.fields['resources'] = resources;

      if (videoFile != null) {
        request.files.add(await http.MultipartFile.fromPath('content_file', videoFile.path));
      }
      if (pdfFile != null) {
        request.files.add(await http.MultipartFile.fromPath('notes_file', pdfFile.path));
      }

      // 🚀 ASLI FIX YAHAN BHI HAI: 5 minutes timeout for update flow
      var responseStream = await request.send().timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception("Update timed out! Please check your network connection.");
        },
      );

      var response = await http.Response.fromStream(responseStream);

      if (response.statusCode == 200) {
        return "success";
      } else {
        final errorData = jsonDecode(response.body);
        return errorData['error'] ?? "Failed to update lesson";
      }
    } catch (e) {
      return "An error occurred: $e";
    }
  }

  // 🚀 DELETE LESSON
  Future<bool> deleteLesson(int lessonId) async {
    final token = await StorageService().getToken();
    if (token == null) return false;
    try {
      final response = await http.delete(
        Uri.parse(ApiEndpoints.teacherDeleteLesson(lessonId)),
        headers: {'Authorization': 'Token $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deleting lesson: $e");
      return false;
    }
  }


  // 🚀 Naya function: Forgot password wale OTP ko check karne ke liye
  Future<bool> verifyPasswordResetOtp(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/reset-password/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'otp': otp,
          // Yahan hum password nahi bhej rahe hain, toh backend sirf OTP validate karega
        }),
      );

      print("DEBUG: Verify Reset OTP Status: ${response.statusCode}");
      print("DEBUG: Verify Reset OTP Response: ${response.body}");

      if (response.statusCode == 200) {
        return true; // OTP sahi hai!
      } else {
        return false; // OTP galat hai!
      }
    } catch (e) {
      debugPrint("❌ Verify Reset OTP Error: $e");
      return false;
    }
  }

}