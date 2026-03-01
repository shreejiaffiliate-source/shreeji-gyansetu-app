import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/course_model.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/custom_button.dart';
import '../../screens/learning/lesson_player_screen.dart';
import 'package:provider/provider.dart';
import '../../../data/providers/course_provider.dart';


class CourseDetailScreen extends StatelessWidget {
  final CourseModel course;
  const CourseDetailScreen({super.key, required this.course});

  // Function to handle enrollment
  Future<void> _enrollUser(BuildContext context) async {
    final success = await ApiService().enrollInCourse(course.id);

    if (success) {
      // 1. REFRESH PROVIDER: This updates the 'isEnrolled' status in the app memory
      // and ensures the Admin Panel data is reflected locally.
      await Provider.of<CourseProvider>(context, listen: false).fetchAllCourses();

      // 2. Show the Congratulations dialog
      _showSuccessDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enrollment failed. Please try again.")),
      );
    }
  }

  // Success Dialog / Screen
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 80),
            const SizedBox(height: 20),
            const Text(
              "Congratulations!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "You have successfully enrolled in the course.",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: "View Course", // Updated Text
              onPressed: () {
                Navigator.pop(context); // Close dialog

                // Open first lesson immediately
                if (course.modules.isNotEmpty && course.modules.first.lessons.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LessonPlayerScreen(lesson: course.modules.first.lessons.first)),
                  );
                } else {
                  // If no lessons, go back to refresh the main detail screen
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. Sleek Expanding App Bar with Thumbnail
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            // backgroundColor: AppColors.primaryBlue,
            // leading: const BackButton(
            //   color: Colors.white,
            // ),
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: course.thumbnail,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Title and Level Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          course.level,
                          style: const TextStyle(color: AppColors.primaryBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text("${course.enrollmentCount} Students",
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(course.title, style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // 3. Price & Action
                  Row(
                    children: [
                      Text("₹${course.discountPrice}", style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGreen)),
                      const SizedBox(width: 10),
                      if (course.price != null)
                        Text("₹${course.price}", style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textMuted)),
                      const Spacer(),
                      const Icon(Icons.share, color: AppColors.primaryBlue),
                    ],
                  ),
                  const Divider(height: 40),

                  // 4. Description
                  const Text("About this course", style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(course.description, style: const TextStyle(
                      color: AppColors.textMuted, height: 1.5)),

                  const SizedBox(height: 30),

                  // 5. Curriculum Placeholder (Matches your Django Modules)
                  const Text("Course Curriculum", style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (course.modules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text("Curriculum details coming soon.",
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    )
                  else
                  // This calls the NEW method defined below
                    ...course.modules.map((module) =>
                        _buildModuleSection(context, module)),

                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // 6. Sticky Bottom Enroll Button
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme
              .of(context)
              .cardColor,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: CustomButton(
          text: course.isEnrolled ? "Go to Dashboard" : "Enroll Now", // Updated text
          isSecondary: true,
          onPressed: () {
            if (course.isEnrolled) {
              // If already enrolled, scroll to curriculum or open player
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You are already enrolled!")));
            } else {
              _enrollUser(context);
            }
          },
        ),
      ),
    );
  }

  // New Dynamic Module Builder
  Widget _buildModuleSection(BuildContext context, ModuleModel module) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: const Icon(Icons.library_books, color: AppColors.primaryBlue),
        title: Text(
          module.title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        children: module.lessons.map((lesson) {
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 32, right: 16),
            leading: Icon(
              // Show a lock icon if they can't access it
              (course.isEnrolled || lesson.isPreview) ? Icons.play_circle_fill : Icons.lock_outline,
              color: (course.isEnrolled || lesson.isPreview) ? AppColors.primaryCyan : AppColors.textMuted,
              size: 20,
            ),
            title: Text(lesson.title, style: const TextStyle(fontSize: 14)),
            onTap: () {
              if (course.isEnrolled || lesson.isPreview) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LessonPlayerScreen(lesson: lesson),
                  ),
                );
              } else {
                // Show a message asking them to enroll
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Enroll in this course to unlock this lesson!")),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}