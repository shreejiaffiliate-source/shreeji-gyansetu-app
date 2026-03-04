class ApiEndpoints {
  // Replace with your actual Django server URL
  static const String baseUrl = "http://192.168.31.137:8000/api"; // Default for Android Emulator

  static const String login = "$baseUrl/login/";
  static const String home = "$baseUrl/home/";
  static const String courses = "$baseUrl/courses/";
  static const String myLearning = "$baseUrl/my-learning/";
  static const String profile = "$baseUrl/profile/";
}