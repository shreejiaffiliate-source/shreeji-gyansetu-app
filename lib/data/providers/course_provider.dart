import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../services/api_service.dart';
import '../models/slider_model.dart';

class CourseProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CourseModel> _popularCourses = [];
  List<CourseModel> _allCourses = []; // New: Full list of all courses
  List<CourseModel> _filteredCourses = []; // New: List shown on the Search Screen
  List<dynamic> _categories = [];
  List<SliderModel> _sliders = [];
  bool _isLoading = false;

  // Getters
  List<CourseModel> get popularCourses => _popularCourses;
  List<CourseModel> get filteredCourses => _filteredCourses;
  List<SliderModel> get sliders => _sliders;
  List<dynamic> get categories => _categories;
  bool get isLoading => _isLoading;

  // 1. New method to fetch everything for the "All Courses" screen
  Future<void> fetchAllCourses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await _apiService.getAllCourses();
      _allCourses = data.map((json) => CourseModel.fromJson(json)).toList();
      _filteredCourses = _allCourses; // Initially, show everything
    } catch (e) {
      print("Error fetching all courses: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. The Search Logic
  void filterSearch(String query) {
    if (query.isEmpty) {
      _filteredCourses = _allCourses;
    } else {
      _filteredCourses = _allCourses
          .where((course) =>
          course.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners(); // This triggers the UI to rebuild instantly
  }

  Future<void> fetchHomeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.getHomeData();

      // --- DETECTOR 1: Check if the list even exists ---
      if (data['popular_courses'] == null) {
        print("!!! ERROR: Django is not sending any 'popular_courses' !!!");
      }

      if (data['sliders'] != null){
        final List sliderJson = data['sliders'];
        _sliders = sliderJson.map((json) => SliderModel.fromJson(json)).toList();
      }

      _categories = data['categories'] ?? [];

      // --- DETECTOR 2: Check each course one by one ---
      final List? coursesJson = data['popular_courses'];

      if (coursesJson != null) {
        List<CourseModel> tempCourses = [];

        for (var item in coursesJson) {
          try {
            tempCourses.add(CourseModel.fromJson(item));
          } catch (e) {
            // This line will tell us EXACTLY what is broken
            print("!!! ERROR IN ONE COURSE: $e");
            print("The data causing trouble is: $item");
          }
        }
        _popularCourses = tempCourses;
      }

    } catch (error) {
      print("!!! BIG ERROR: $error");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}