class ApiEndpoints {
  // Replace with your actual Django server URL
  static const String baseUrl = "https://www.gyansetu.shreejifintech.com/api"; // Default for Android Emulator
  //static const String baseUrl = "http://172.30.151.65:8000/api"; // Default for Android Emulator

  static const String register = "$baseUrl/register/";
  static const String login = "$baseUrl/login/";
  static const String home = "$baseUrl/home/";



  static const String courses = "$baseUrl/courses/";
  static const String myLearning = "$baseUrl/my-learning/";
  static const String profile = "$baseUrl/profile/";
  static const String teacherCourses = "$baseUrl/teacher/courses/";
  // 👇 Ye naye endpoints add karein
  static const String teacherQueries = "$baseUrl/teacher/queries/";
  static String teacherReplyQuery(int queryId) => "$baseUrl/teacher/queries/$queryId/reply/";

  // 🚀 Add Course Endpoint (Naya add kiya)
  static const String teacherCreateCourse = "$baseUrl/teacher/course/create/";

  // Module fetch aur create karne ke liye
  static String teacherModules(int courseId) => "$baseUrl/teacher/course/$courseId/modules/";

  // Lesson upload karne ke liye
  static String teacherAddLesson(int moduleId) => "$baseUrl/teacher/module/$moduleId/add-lesson/";

  static String teacherToggleCourseStatus(int courseId) => "$baseUrl/teacher/course/$courseId/toggle-status/";
  static String teacherDeleteCourse(int courseId) => "$baseUrl/teacher/course/$courseId/delete/";
  static String teacherUpdateCourse(int courseId) => "$baseUrl/teacher/course/$courseId/update/";
  static String teacherUpdateLesson(int lessonId) => "$baseUrl/teacher/lesson/$lessonId/update/";
  static String teacherDeleteLesson(int lessonId) => "$baseUrl/teacher/lesson/$lessonId/delete/";

  static const String health = "$baseUrl/home/";

}
