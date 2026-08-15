import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // 🚀 Added Provider
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/storage_service.dart';
import '../../../data/providers/auth_provider.dart'; // 🚀 Added AuthProvider
import 'teacher_edit_course_screen.dart';
import 'teacher_add_course_screen.dart';
import 'teacher_manage_curriculum_screen.dart';
import '../../widgets/gyansetu_native_ad.dart'; // 🎯 NAYA: Native Ad Import

class TeacherCoursesScreen extends StatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  State<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends State<TeacherCoursesScreen> {
  final StorageService _storageService = StorageService();

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _allCourses = [];
  List<dynamic> _filteredCourses = [];

  String _searchQuery = "";
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchAndSetCourses();
  }

  Future<void> _fetchAndSetCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception("No token found");

      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherCourses),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (!mounted) return;

        setState(() {
          _allCourses = data;
        });
        _applyFilters();
      } else {
        throw Exception("Failed to load courses");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<dynamic> temp = _allCourses;

    if (_selectedFilter == 'Published') {
      temp = temp.where((course) => course['is_active'] == true).toList();
    } else if (_selectedFilter == 'Drafts') {
      temp = temp.where((course) => course['is_active'] == false).toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      temp = temp.where((course) {
        final title = (course['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery.toLowerCase().trim());
      }).toList();
    }

    setState(() {
      _filteredCourses = temp;
    });
  }

  void _navigateToPlaceholder(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(child: Text("$title Screen\n(Coming Soon)", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: AppColors.textMuted))),
        ),
      ),
    );
  }

  void _navigateToAddCourse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TeacherAddCourseScreen()),
    ).then((_) {
      _fetchAndSetCourses();
    });
  }

  void _navigateToManageCurriculum(int courseId, String courseTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherManageCurriculumScreen(
          courseId: courseId,
          courseTitle: courseTitle,
        ),
      ),
    ).then((_) {
      _fetchAndSetCourses(); // Wapas aane par list update karo
    });
  }

  // 🚀 PUBLISH / UNPUBLISH LOGIC
  Future<void> _togglePublishStatus(int courseId) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updating status...")));
    final provider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await provider.toggleCourseStatus(courseId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      _fetchAndSetCourses(); // List refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update status"), backgroundColor: Colors.red));
    }
  }

  // 🚀 DELETE COURSE LOGIC
  Future<void> _deleteCourse(int courseId) async {
    // Pehle Confirmation Dialog dikhao
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Course?"),
        content: const Text("Are you sure you want to delete this course? This action cannot be undone."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Deleting course...")));
    final provider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await provider.deleteCourse(courseId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Course deleted successfully"), backgroundColor: AppColors.primaryGreen));
      _fetchAndSetCourses(); // List refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete course"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Courses"),
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _navigateToAddCourse
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterSection(isDark),
          Expanded(
            child: _buildBodyContent(isDark),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddCourse,
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Course", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBodyContent(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));
    }

    if (_errorMessage != null) {
      return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text("Error: $_errorMessage", textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchAndSetCourses, child: const Text("Retry"))
            ],
          )
      );
    }

    if (_allCourses.isEmpty) {
      return _buildEmptyState(context, isDark, false);
    }

    if (_filteredCourses.isEmpty) {
      return _buildEmptyState(context, isDark, true);
    }

    return RefreshIndicator(
      onRefresh: _fetchAndSetCourses,
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _filteredCourses.length,
        itemBuilder: (context, index) {
          final course = _filteredCourses[index];
          return Column(
            children: [
              _buildPremiumCourseCard(context, course, isDark),
              // 🎯 NAYA CHANGE: Har doosre course ke baad ek Native Ad
              if ((index + 1) % 2 == 0)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: GyansetuNativeAd(), // Apna ad widget call kiya
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchAndFilterSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
                color: isDark ? Colors.black12 : Colors.grey.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 4)
            )
          ]
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              _searchQuery = value;
              _applyFilters();
            },
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
            decoration: InputDecoration(
              hintText: "Search your courses...",
              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              filled: true,
              fillColor: isDark ? AppColors.bgDark : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("All"),
                _buildFilterChip("Published"),
                _buildFilterChip("Drafts"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedFilter == label;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (bool selected) {
          if (selected) {
            setState(() {
              _selectedFilter = label;
            });
            _applyFilters();
          }
        },
        selectedColor: AppColors.primaryBlue,
        backgroundColor: isDark ? AppColors.cardDark : Colors.grey.shade50,
        labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? AppColors.primaryBlue : (isDark ? AppColors.borderDark : Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCourseCard(BuildContext context, dynamic course, bool isDark) {
    final title = course['title'] ?? 'Untitled Course';
    final courseId = course['id'];
    final isActive = course['is_active'] ?? false;
    final studentsCount = course['enrollment_count'] ?? 0;
    final price = course['discount_price'] ?? course['price'] ?? "0.00";

    String imageUrl = "https://via.placeholder.com/150/0B4378/FFFFFF/?text=Course";
    if (course['thumbnail'] != null) {
      imageUrl = course['thumbnail'];
      if (imageUrl.startsWith('/')) {
        final hostUrl = ApiEndpoints.baseUrl.replaceAll('/api', '');
        imageUrl = "$hostUrl$imageUrl";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(color: Colors.grey.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _navigateToManageCurriculum(courseId, title),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 100,
                  width: 100,
                  margin: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.error)),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12, right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? AppColors.primaryGreen.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? "Published" : "Draft",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? AppColors.primaryGreen : AppColors.textMuted,
                                ),
                              ),
                            ),
                            Text(
                              "₹$price",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryCyan, fontSize: 13),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.people, size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              "$studentsCount Enrolled",
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? AppColors.borderDark : Colors.grey.shade200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 🚀 Edit Button Update
              _buildCardActionBtn(Icons.edit_document, "Edit Info", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TeacherEditCourseScreen(course: course)),
                ).then((value) {
                  if (value == true) {
                    _fetchAndSetCourses(); // Agar update ho gaya toh list reload hogi
                  }
                });
              }),
              Container(height: 20, width: 1, color: isDark ? AppColors.borderDark : Colors.grey.shade200),

              _buildCardActionBtn(Icons.video_library, "Lessons", () => _navigateToManageCurriculum(courseId, title)),

              Container(height: 20, width: 1, color: isDark ? AppColors.borderDark : Colors.grey.shade200),

              // 🚀 UPDATED MENU ITEMS
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
                onSelected: (value) {
                  if (value == 'delete') {
                    _deleteCourse(courseId);
                  } else if (value == 'status') {
                    _togglePublishStatus(courseId);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'status',
                    child: Text(isActive ? 'Unpublish Course' : 'Publish Course',
                        style: TextStyle(color: isActive ? Colors.orange : AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete Course', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCardActionBtn(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark, bool isSearchEmpty) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.05), shape: BoxShape.circle),
              child: Icon(isSearchEmpty ? Icons.search_off : Icons.school_outlined, size: 70, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 24),
            Text(isSearchEmpty ? "No Matches Found" : "No Courses Yet", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                isSearchEmpty ? "Try a different search or filter." : "Start sharing your knowledge with the world.",
                style: const TextStyle(color: AppColors.textMuted)
            ),
            if (!isSearchEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _navigateToAddCourse,
                icon: const Icon(Icons.add),
                label: const Text("Create First Course"),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}