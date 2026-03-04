import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/course_provider.dart';
import '../../widgets/course_card.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> with SingleTickerProviderStateMixin {
  // Nullable controller to prevent LateInitializationError
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize with 2 tabs for Ongoing and Completed
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Refreshing data from provider on load
      Provider.of<CourseProvider>(context, listen: false).fetchMyCourses();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to ensure the tab counts and lists update instantly
    return Consumer<CourseProvider>(
      builder: (context, courseProvider, child) {
        final allEnrolled = courseProvider.myEnrolledCourses;

        // Filtering logic inside the builder ensures it reacts to Provider updates
        final ongoingCourses = allEnrolled.where((c) => c.progress < 1.0).toList();
        final completedCourses = allEnrolled.where((c) => c.progress >= 1.0).toList();

        if (_tabController == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text("My Learning", style: TextStyle(fontWeight: FontWeight.bold)),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryBlue,
              labelColor: AppColors.primaryBlue,
              tabs: [
                Tab(text: "Ongoing (${ongoingCourses.length})"),
                Tab(text: "Completed (${completedCourses.length})"),
              ],
            ),
          ),
          // Added RefreshIndicator for manual sync
          body: RefreshIndicator(
            onRefresh: () => courseProvider.fetchMyCourses(forceRefresh: true),
            child: courseProvider.isLoading && allEnrolled.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
              controller: _tabController,
              children: [
                _buildCourseList(ongoingCourses),
                _buildCourseList(completedCourses),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseList(List<dynamic> courses) {
    if (courses.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _buildLearningCard(context, courses[index]);
      },
    );
  }

  Widget _buildLearningCard(BuildContext context, dynamic course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 3. Null-safe Progress Calculation
    double currentProgress = (course.progress ?? 0.0).toDouble();
    bool isCompleted = currentProgress >= 1.0;
    String displayPercent = "${(currentProgress * 100).toInt()}%";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Reusing your existing adaptive CourseCard
            CourseCard(course: course),

            // Dynamic Progress Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Course Progress",
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      Text(
                        displayPercent,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          // Blue while studying, Green when finished
                          color: isCompleted ? AppColors.primaryGreen : AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Dynamic Progress Bar
                  LinearProgressIndicator(
                    value: currentProgress,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    color: isCompleted ? AppColors.primaryGreen : AppColors.primaryBlue,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded,
                size: 80, color: AppColors.primaryBlue),
          ),
          const SizedBox(height: 24),
          const Text("No courses found here",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Keep learning to achieve your goals!",
              style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}