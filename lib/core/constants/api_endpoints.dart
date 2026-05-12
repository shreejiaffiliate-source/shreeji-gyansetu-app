class ApiEndpoints {
  // Replace with your actual Django server URL
  static const String baseUrl = "https://www.gyansetu.shreejifintech.com/api"; // Default for Android Emulator
  //static const String baseUrl = "http://10.208.24.65:8000/api"; // Default for Android Emulator

  static const String register = "$baseUrl/register/";
  static const String login = "$baseUrl/login/";
  static const String home = "$baseUrl/home/";
  static const String courses = "$baseUrl/courses/";
  static const String myLearning = "$baseUrl/my-learning/";
  static const String profile = "$baseUrl/profile/";
}