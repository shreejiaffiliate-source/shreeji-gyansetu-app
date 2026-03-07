import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/course_provider.dart';
import '../../../data/models/course_model.dart';
import '../../widgets/course_card.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void dispose() {
    // Always dispose controllers to prevent memory leaks
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // TRIGGER FETCH: This ensures data is loaded even if you come from Bottom Nav
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final courseProvider = Provider.of<CourseProvider>(context, listen: false);
      if (courseProvider.filteredCourses.isEmpty) {
        courseProvider.fetchAllCourses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("All Courses"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                courseProvider.filterSearch(value);
                setState(() {}); // 2. Call setState to show/hide the clear icon
              },
              decoration: InputDecoration(
                hintText: "Search courses...",
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryCyan),

                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.textMuted),
                  onPressed: () {
                    _searchController.clear(); // Clear the text
                    courseProvider.filterSearch(""); // Reset the search filter
                    setState(() {}); // Rebuild to hide the icon
                  },
                )
                    : null,

                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: courseProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => courseProvider.fetchAllCourses(),
        child: courseProvider.filteredCourses.isEmpty
          ? _buildNoResults()
        : ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20),
          itemCount: courseProvider.categories.length,
          itemBuilder: (context, index) {
            final category = courseProvider.categories[index];
            final String categoryTitle = category['title'] ?? 'Category';
            final String iconClass = (category['icon_class'] ?? '').toString();

            final filteredCourses = courseProvider.filteredCourses
                .where((course) => course.categoryName == categoryTitle)
                .toList();

            if (filteredCourses.isEmpty) return const SizedBox.shrink();

            return _buildCategoryRow(context, categoryTitle, iconClass, filteredCourses);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryRow(BuildContext context, String title, String iconClass, List<CourseModel> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(_getIconData(iconClass), color: AppColors.primaryBlue),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const Divider(indent: 16, endIndent: 16),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 15, bottom: 10),
                child: CourseCard(course: courses[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
  IconData _getIconData(String? iconClass) {
    if (iconClass == null) return Icons.category;

    switch (iconClass.trim()) {
      case 'fa-solid fa-computer':
        return Icons.computer;
      case 'fa-briefcase':
        return Icons.business_center;
      case 'fa-money-bill':
        return Icons.payments;
      default:
        return Icons.category;
    }
  }
  Widget _buildNoResults() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Allows pull-to-refresh
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              "No courses found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try searching for something else.",
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
