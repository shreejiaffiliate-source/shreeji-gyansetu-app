import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  // We use a private variable to store the current mode
  ThemeMode _themeMode;

  // Constant key to avoid typos when saving/loading
  static const String _key = "theme_mode";

  // The constructor now requires the initial preference.
  // This value will be fetched in your main.dart before the app starts.
  ThemeProvider(bool isDark) : _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

  // Getters to be used in the UI
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Toggles the theme and saves the preference to local storage
  void toggleTheme(bool isOn) async {
    // 1. Update the UI immediately
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    // 2. Persist the choice to the phone's memory
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, isOn);
    } catch (e) {
      debugPrint("Error saving theme preference: $e");
    }
  }
}