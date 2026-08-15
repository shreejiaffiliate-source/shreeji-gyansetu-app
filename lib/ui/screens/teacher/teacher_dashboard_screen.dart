import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/storage_service.dart';
import '../../../data/providers/auth_provider.dart';

// 🚀 Saari asli screens import kar li hain
import 'teacher_add_course_screen.dart';
import 'teacher_queries_screen.dart';
import 'teacher_courses_screen.dart';
import 'teacher_manage_curriculum_screen.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final StorageService _storageService = StorageService();

  bool _isLoading = true;
  int _totalCourses = 0;
  int _totalStudents = 0;
  List<dynamic> _recentCourses = [];
  String _errorMessage = "";

  // Temporary flag for Sir/Madam greeting (until backend supports gender)
  final bool isMale = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception("Authentication token not found.");

      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherCourses),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> courses = json.decode(response.body);

        int totalC = courses.length;
        int totalS = 0;
        for (var course in courses) {
          totalS += (course['enrollment_count'] ?? 0) as int;
        }

        List<dynamic> recent = courses.take(5).toList();

        if (!mounted) return;

        setState(() {
          _totalCourses = totalC;
          _totalStudents = totalS;
          _recentCourses = recent;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = "Failed to load stats";
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // 🚀 Sirf un features ke liye jo abhi nahi bane (Earnings, Live Class)
  void _navigateToPlaceholder(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PlaceholderScreen(title: title)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final String teacherName = authProvider.user?.firstName ?? (isMale ? "Sir" : "Madam");
    final String greetingTitle = "Welcome back, $teacherName";

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'lib/assets/images/logo.png',
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrack) => const Icon(Icons.school, color: AppColors.primaryBlue),
            ),
            const SizedBox(width: 8),
            const Text(
              "Shreeji GyanSetu",
              style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("No new notifications at the moment."),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
          : RefreshIndicator(
        onRefresh: _fetchDashboardStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 1. Welcome Banner
              _buildWelcomeBanner(greetingTitle),

              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 24),

              // 2. Overview Stats
              _buildSectionHeader("Overview", null),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Courses",
                        value: "$_totalCourses",
                        icon: Icons.video_library,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        title: "Total Students",
                        value: "$_totalStudents",
                        icon: Icons.groups,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Quick Actions
              _buildSectionHeader("Quick Actions", null),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // 🚀 Asli screens se link kar diya hai!
                    _buildQuickActionItem("Add Course", Icons.add_circle, AppColors.primaryCyan, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherAddCourseScreen())).then((_) => _fetchDashboardStats());
                    }),
                    _buildQuickActionItem("Queries", Icons.forum, AppColors.primaryBlue, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherQueriesScreen()));
                    }),
                    // _buildQuickActionItem("Earnings", Icons.account_balance_wallet, Colors.orange, () => _navigateToPlaceholder("My Earnings")),
                    // _buildQuickActionItem("Live Class", Icons.live_tv, AppColors.liveRed, () => _navigateToPlaceholder("Go Live")),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 4. Recent Courses
              _buildSectionHeader("Recent Courses", () {
                // 🚀 See All par click karne se All Courses screen khulegi
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherCoursesScreen())).then((_) => _fetchDashboardStats());
              }),
              const SizedBox(height: 12),

              if (_recentCourses.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("No courses available.", style: TextStyle(color: AppColors.textMuted))),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _recentCourses.length,
                    itemBuilder: (context, index) {
                      final course = _recentCourses[index];
                      return _buildCourseCard(course);
                    },
                  ),
                ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildSectionHeader(String title, VoidCallback? onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text("See All", style: TextStyle(color: AppColors.primaryCyan)),
            ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(String greeting) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryCyan],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.school, size: 120, color: Colors.white.withOpacity(0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Instructor Panel", style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  greeting,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Manage your courses and interact with students.",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderColor),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(String title, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3)),
                boxShadow: [
                  if (!isDark) BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))
                ],
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = course['title'] ?? 'No Title';
    final courseId = course['id'];
    final students = course['enrollment_count'] ?? 0;
    final isActive = course['is_active'] ?? false;

    String imageUrl = "https://via.placeholder.com/150/0B4378/FFFFFF/?text=Course";
    if (course['thumbnail'] != null) {
      imageUrl = course['thumbnail'];
      if (imageUrl.startsWith('/')) {
        // 🚀 URL Theek kiya gaya hai local image testing ke liye
        final hostUrl = ApiEndpoints.baseUrl.replaceAll('/api', '');
        imageUrl = "$hostUrl$imageUrl";
      }
    }

    return GestureDetector(
      // 🚀 Asli Manage Curriculum screen par bheja hai
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherManageCurriculumScreen(
              courseId: courseId,
              courseTitle: title,
            ),
          ),
        ).then((_) => _fetchDashboardStats());
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderColor),
          boxShadow: [
            if (!isDark) BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.grey[300]),
                errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.error)),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primaryGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isActive ? "Published" : "Draft",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isActive ? AppColors.primaryGreen : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                  ),
                  const SizedBox(height: 8),

                  // Students
                  Row(
                    children: [
                      const Icon(Icons.group, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        "$students Students",
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🚀 Sirf Earnings aur Live Class ke liye placeholder bacha hai
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: AppColors.primaryBlue.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              "Coming Soon!",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "We are building the '$title' screen.",
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Go Back"),
            )
          ],
        ),
      ),
    );
  }
}