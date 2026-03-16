import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  // 1. Controller and Query state for Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  int _selectedCategoryIndex = 0;
  final List<String> _categories = ['All', 'Courses', 'Videos', 'Enrollment', 'Account'];

  final List<Map<String, String>> _allFaqs = [
    {'category': 'Courses', 'q': 'How do I search for a course?', 'a': 'Use the search bar on the course screen or filter by categories.'},
    {'category': 'Videos', 'q': 'Can I watch videos offline?', 'a': 'Currently, videos require an active internet connection to stream.'},
    {'category': 'Enrollment', 'q': 'How do I enroll in a course?', 'a': 'Open the course details and tap the "Enroll" button.'},
    {'category': 'Account', 'q': 'How to change my password?', 'a': 'Go to Profile -> Change Password to update your security credentials.'},
  ];

  @override
  void dispose() {
    // Clean up controller when screen is destroyed
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    // 2. Combined Logic: Filter by Category AND Search Query
    List<Map<String, String>> displayedFaqs = _allFaqs.where((faq) {
      final matchesCategory = _selectedCategoryIndex == 0 ||
          faq['category'] == _categories[_selectedCategoryIndex];

      final matchesSearch = faq['q']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          faq['a']!.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Header with Gradient
                Container(
                  width: double.infinity,
                  height: 220,
                  padding: const EdgeInsets.only(left: 10, right: 24, top: 50),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.primaryCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 14, top: 10),
                        child: Text(
                          "How can we \nhelp you today?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 3. WORKING Search Bar
                Positioned(
                  bottom: -25, left: 24, right: 24,
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value; // Update list on every keystroke
                        });
                      },
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: "Search your issue...",
                        hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryCyan),
                        // Clear button appears only when text is present
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Adaptive Categories List
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  bool isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategoryIndex = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryCyan : cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primaryBlue : (isDark ? AppColors.borderDark : Colors.grey.shade300),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _categories[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // 4. FAQ List with Empty State
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: displayedFaqs.isEmpty
                  ? Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.search_off, size: 60, color: Colors.grey.withOpacity(0.5)),
                  const SizedBox(height: 16) ,
                  Text(
                    "No results found for '$_searchQuery'",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              )
                  : Column(
                children: displayedFaqs.map((faq) => _buildFaqTile(context, faq['q']!, faq['a']!)).toList(),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(BuildContext context, String question, String answer) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primaryCyan,
          collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
          title: Text(
            question,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Text(
                answer,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}