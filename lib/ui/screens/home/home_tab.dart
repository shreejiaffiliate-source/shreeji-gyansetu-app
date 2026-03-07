import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/slider_model.dart';
import '../../../data/providers/course_provider.dart';
import '../../widgets/category_item.dart';
import '../../widgets/course_card.dart';
import '../categories/all_category_screen.dart';
import '../courses/course_list_screen.dart';
import '../learning/lesson_player_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<CourseProvider>(context, listen: false);
        // Sync home content and check for new teacher replies
        provider.fetchHomeData();
        provider.fetchNotifications();
      }
    });
  }

  // Adaptive Notification Dialog
  void _showNotificationDialog(BuildContext context, CourseProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Notifications",
          style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: provider.notifications.isEmpty
              ? const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("No new teacher replies.", textAlign: TextAlign.center),
          )
              : ListView.separated(
            shrinkWrap: true,
            itemCount: provider.notifications.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final notif = provider.notifications[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.primarySoft,
                  child: const Icon(Icons.message, color: AppColors.primaryBlue, size: 20),
                ),
                title: Text(
                  notif['course_title'] ?? "Course Update",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  notif['message'] ?? "",
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () async {
                  final int notifId = notif['id'];
                  final int lessonId = notif['lesson_id'];

                  await provider.markNotificationRead(notifId);
                  if (mounted) Navigator.pop(context);

                  final lesson = provider.findLessonById(lessonId);

                  if (lesson != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LessonPlayerScreen(
                          lesson: lesson,
                          openQueries: true, // 1. Pass this flag to trigger the bottom sheet
                        ),
                      ),
                    ).then((_) {
                      provider.fetchNotifications();
                    });
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close", style: TextStyle(color: AppColors.primaryBlue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'lib/assets/images/logo.png',
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrack) => const Icon(Icons.school),
            ),
            const SizedBox(width: 8),
            const Text(
              "Shreeji GyanSetu",
              style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Notification Bell with logic-driven badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                onPressed: () => _showNotificationDialog(context, courseProvider),
                icon: const Icon(Icons.notifications_none),
              ),
              if (courseProvider.notifications.isNotEmpty)
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${courseProvider.notifications.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: courseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async {
          await courseProvider.fetchHomeData();
          await courseProvider.fetchNotifications();
        },
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildCarousel(courseProvider.sliders),
              const SizedBox(height: 24),
              _buildSectionHeader("Explore Categories", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllCategoriesScreen()),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                height: 130,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: courseProvider.categories.length,
                  itemBuilder: (context, index) {
                    return CategoryItem(category: courseProvider.categories[index]);
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Trending Courses", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CourseListScreen()),
                );
              }),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  clipBehavior: Clip.none,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.70,
                  ),
                  itemCount: courseProvider.popularCourses.length,
                  itemBuilder: (context, index) {
                    final course = courseProvider.popularCourses[index];
                    return CourseCard(course: course);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: onSeeAll,
            child: const Text("See All", style: TextStyle(color: AppColors.primaryCyan)),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel(List<SliderModel> sliders) {
    if (sliders.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(colors: [AppColors.primaryBlue, AppColors.primaryCyan]),
        ),
        child: const Center(
          child: Text("Welcome to Shreeji GyanSetu", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 180,
        autoPlay: true,
        enlargeCenterPage: true,
        aspectRatio: 16 / 9,
        viewportFraction: 0.9,
      ),
      items: sliders.map((slider) {
        return Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: slider.image,
                  fit: BoxFit.fill,
                  placeholder: (context, url) => Container(color: Colors.grey[300]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                    slider.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}