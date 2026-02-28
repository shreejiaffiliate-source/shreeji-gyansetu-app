import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/slider_model.dart';
import '../../../data/providers/course_provider.dart';
import '../../widgets/category_item.dart'; // We'll build this simple widget next
import '../../widgets/course_card.dart';   // We'll build this simple widget next
import '../categories/all_category_screen.dart';
import '../courses/course_list_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure the first build is done
    // before we trigger a potential state change from the API
    WidgetsBinding.instance.addPostFrameCallback((_){
      if (mounted){
        Provider.of<CourseProvider>(context, listen: false).fetchHomeData();
  }
        });
}

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('lib/assets/images/logo.png',
            height: 40,
            width: 40,
              errorBuilder: (context, error, stackTrack){
              return const Icon(Icons.school);
              },
            ),

            // const Icon(Icons.school, color: AppColors.primaryBlue),
            // const SizedBox(width: 2),
            Text("Shreeji GyanSetu", style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
        ],
      ),
      body: courseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => courseProvider.fetchHomeData(),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // 1. Promotional Carousel (Dynamic from slides API)
              _buildCarousel(courseProvider.sliders),

              const SizedBox(height: 24),

              // 2. Categories Section
              _buildSectionHeader("Explore Categories", () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllCategoriesScreen()),
                );
              }),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
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

              // 3. Trending Courses (Vertical Grid)
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
                  clipBehavior: Clip.none, // Allow shadows and borders to bleed out slightly
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.70, // Making it slightly smaller (taller cards)
                  ),
                  itemCount: courseProvider.popularCourses.length,
                  itemBuilder: (context, index) {
                    final course = courseProvider.popularCourses[index];
                    // This print will tell us if Flutter is actually trying to build all courses
                    debugPrint("Building course index $index: ${course.title}");
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
          TextButton(onPressed: onSeeAll, child: const Text("See All", style: TextStyle(color: AppColors.primaryCyan))),
        ],
      ),
    );
  }

  Widget _buildCarousel(List<SliderModel> sliders) {
    if (sliders.isEmpty) {
      // Show a default gradient box if no sliders are found in DB
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(colors: [AppColors.primaryBlue, AppColors.primaryCyan]),
        ),
        child: const Center(child: Text("Welcome to Shreeji GyanSetu", style: TextStyle(color: Colors.white))),
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
                // Real image from Django
                CachedNetworkImage(
                  imageUrl: slider.image,
                  fit: BoxFit.fill,
                  placeholder: (context, url) => Container(color: Colors.grey[300]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                // Dark overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    ),
                  ),
                ),
                // Banner Title
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