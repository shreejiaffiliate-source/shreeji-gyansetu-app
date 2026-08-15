import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';
import '../models/slider_model.dart';

class CourseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CourseModel> _myEnrolledCourses = [];
  List<CourseModel> _popularCourses = [];
  List<CourseModel> _allCourses = [];
  List<CourseModel> _filteredCourses = [];
  List<dynamic> _categories = [];
  List<SliderModel> _sliders = [];
  bool _isLoading = false;

  List<CourseModel> get myEnrolledCourses => _myEnrolledCourses;
  List<CourseModel> get popularCourses => _popularCourses;
  List<CourseModel> get filteredCourses => _filteredCourses;
  List<SliderModel> get sliders => _sliders;
  List<dynamic> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchAllCourses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await _apiService.getAllCourses();
      _allCourses = data.map((json) => CourseModel.fromJson(json)).toList();
      _filteredCourses = _allCourses;
    } catch (e) {
      debugPrint("Error fetching all courses: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterSearch(String query) {
    if (query.isEmpty) {
      _filteredCourses = _allCourses;
    } else {
      _filteredCourses = _allCourses
          .where((course) =>
          course.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> fetchMyCourses({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _myEnrolledCourses = [];
      _isLoading = true;
      notifyListeners();
    } else if (_myEnrolledCourses.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final List<dynamic> data = await _apiService.getMyCourses();
      final List<CourseModel> fetched = data.map((json) => CourseModel.fromJson(json)).toList();

      final Map<int, CourseModel> distinctCourses = {};
      for (var course in fetched) {
        distinctCourses[course.id] = course;
      }

      _myEnrolledCourses = distinctCourses.values.toList();

      if (_myEnrolledCourses.isNotEmpty) {
        debugPrint("Provider: Fetched ${_myEnrolledCourses.length} enrolled courses.");
      } else {
        debugPrint("Provider: Student has no enrolled courses yet.");
      }

    } catch (e) {
      debugPrint("Error fetching my courses: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHomeData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.getHomeData();
      if (data['sliders'] != null){
        final List sliderJson = data['sliders'];
        _sliders = sliderJson.map((json) => SliderModel.fromJson(json)).toList();
      }
      _categories = data['categories'] ?? [];
      final List? coursesJson = data['popular_courses'];
      if (coursesJson != null) {
        _popularCourses = coursesJson.map((item) => CourseModel.fromJson(item)).toList();
      }
      await fetchMyCourses();
    } catch (error) {
      debugPrint("!!! Home Data Error: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 🚀 NAYA FUNCTION: Sirf Categories load karne ke liye (Teacher Dashboard ke liye)
  Future<void> fetchCategories() async {
    if (_categories.isNotEmpty) return; // Agar pehle se load hai toh time bacha lo

    _isLoading = true;
    notifyListeners();
    try {
      // Home data wali API se hi categories nikal lenge
      final data = await _apiService.getHomeData();
      _categories = data['categories'] ?? [];
    } catch (error) {
      debugPrint("Error fetching categories: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeLesson(int lessonId) async {
    try {
      bool success = await _apiService.markLessonAsComplete(lessonId);

      if (success) {
        await fetchMyCourses(forceRefresh: true);
        await fetchHomeData();
        debugPrint("Provider: Lesson $lessonId sync complete.");
      }
    } catch (e) {
      debugPrint("Error in Provider: $e");
    }
  }

  List<dynamic> _notifications = [];
  List<dynamic> get notifications => _notifications;

  Future<void> fetchNotifications() async {
    try {
      final data = await _apiService.getNotifications();
      _notifications = data;
      notifyListeners();
    } catch (e) {
      debugPrint("Notification Error: $e");
    }
  }

  LessonModel? findLessonById(int lessonId) {
    for (var course in _myEnrolledCourses) {
      for (var module in course.modules) {
        for (var lesson in module.lessons) {
          if (lesson.id == lessonId) {
            return lesson;
          }
        }
      }
    }
    return null;
  }

  Future<void> markNotificationRead(int notificationId) async {
    try {
      bool success = await _apiService.markNotificationAsRead(notificationId);
      if (success) {
        _notifications.removeWhere((n) => n['id'] == notificationId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error marking notification read: $e");
    }
  }
}