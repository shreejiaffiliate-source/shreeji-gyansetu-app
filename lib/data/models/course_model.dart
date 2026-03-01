class CourseModel {
  final int id;
  final String title;
  final String slug;
  final String thumbnail;
  final String description;
  final String price;
  final String? discountPrice;
  final String level;
  final bool isLive;
  final String categoryName;
  final String teacherName;
  final int enrollmentCount;
  final List<ModuleModel> modules;
  final bool isEnrolled;

  CourseModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.thumbnail,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.level,
    required this.isLive,
    required this.categoryName,
    required this.teacherName,
    required this.enrollmentCount,
    required this.modules,
    required this.isEnrolled,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) {
    print("Course: ${json['title']} | Enrolled From API: ${json['is_enrolled']}");
    return CourseModel(
      id: json['id'],
      title: json['title'] ?? 'Untitled Course',
      slug: json['slug'] ?? '',
      thumbnail: json['thumbnail'] ?? '', // Django provides absolute URL via Serializer
      description: json['description'] ?? '',
      price: json['price']?.toString() ?? '0',
      discountPrice: json['discount_price']?.toString(),
      level: json['level'] ?? 'Beginner',
      isLive: json['is_live'] ?? false,
      categoryName: json['master_category'] != null
          ? json['master_category']['title'] ?? 'General'
          : 'General',
      teacherName: json['teacher'] != null
          ? "${json['teacher']['first_name'] ?? ''} ${json['teacher']['last_name'] ?? ''}".trim()
          : 'Instructor',
      enrollmentCount: json['enrollment_count'] ?? 0,
      modules: (json['modules'] as List?)
          ?.map((m) => ModuleModel.fromJson(m))
          .toList() ?? [],
      isEnrolled: json['is_enrolled'] ?? false,
    );
  }
}

class ModuleModel {
  final String title;
  final List<LessonModel> lessons;

  ModuleModel({required this.title, required this.lessons});

  factory ModuleModel.fromJson(Map<String, dynamic> json) {
    return ModuleModel(
      title: json['title'],
      lessons: (json['lessons'] as List?)
          ?.map((l) => LessonModel.fromJson(l))
          .toList() ?? [],
    );
  }
}

class LessonModel {
  final int id;
  final String title;
  final String videoUrl;
  final bool isPreview;



  LessonModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.isPreview,
  });

  factory LessonModel.fromJson(Map<String, dynamic> json) {
    return LessonModel(
      id: json['id'],
      title: json['title'],
      videoUrl: json['video_url'] ?? '',
      isPreview: json['is_preview'] ?? false,
    );
  }
}

class UserModel {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? userType;
  final String? profilePhoto;
  final String? phoneNumber;
  final String? collegeName;
  final String? branch;
  final String? enrollmentNumber;
  final String? qualification;
  final String? dateOfBirth;
  final String? bio;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.userType,
    this.profilePhoto,
    this.phoneNumber,
    this.collegeName,
    this.branch,
    this.enrollmentNumber,
    this.qualification,
    this.dateOfBirth,
    this.bio,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // 1. Extract the nested profile dictionary safely
    final Map<String, dynamic> profile = json['profile'] ?? {};

    return UserModel(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      // 2. Map fields from the nested profile object
      userType: profile['user_type'] ?? 'Student',
      // Ensure these keys match your Django Profile model fields exactly
      phoneNumber: profile['phone_number'],
      collegeName: profile['college_name'],
      branch: profile['branch'],
      enrollmentNumber: profile['enrollment_number'],
      qualification: profile['qualification'],
      dateOfBirth: profile['date_of_birth'],
      bio: profile['bio'],
      // 3. Use the absolute URL from the SerializerMethodField if you added it
      profilePhoto: json['profile_photo'] ?? profile['photo'],
    );
  }
}