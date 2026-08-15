import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/storage_service.dart';

class TeacherQueriesScreen extends StatefulWidget {
  const TeacherQueriesScreen({super.key});

  @override
  State<TeacherQueriesScreen> createState() => _TeacherQueriesScreenState();
}

class _TeacherQueriesScreenState extends State<TeacherQueriesScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _replyController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  List<dynamic> _allQueries = [];
  List<dynamic> _filteredQueries = [];
  String _selectedFilter = 'All'; // Options: 'All', 'Pending', 'Resolved'

  @override
  void initState() {
    super.initState();
    _fetchQueries();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  // 1. Fetch Queries from API
  Future<void> _fetchQueries() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storageService.getToken();
      if (token == null) throw Exception("Token not found");

      final response = await http.get(
        Uri.parse(ApiEndpoints.teacherQueries),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _allQueries = data;
        });
        _applyFilter();
      } else {
        throw Exception("Failed to load queries from server");
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

  // 2. Filter Logic locally
  void _applyFilter() {
    List<dynamic> temp = _allQueries;
    if (_selectedFilter == 'Pending') {
      temp = temp.where((q) => q['is_resolved'] == false).toList();
    } else if (_selectedFilter == 'Resolved') {
      temp = temp.where((q) => q['is_resolved'] == true).toList();
    }
    setState(() {
      _filteredQueries = temp;
    });
  }

  // 3. Post Reply to Backend API
  Future<void> _submitReply(int queryId) async {
    final answerText = _replyController.text.trim();
    if (answerText.isEmpty) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
    );

    try {
      final token = await _storageService.getToken();
      final response = await http.post(
        Uri.parse(ApiEndpoints.teacherReplyQuery(queryId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: json.encode({"answer": answerText}),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        _replyController.clear();
        Navigator.pop(context); // Close BottomSheet

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Reply submitted successfully! 🎉"), backgroundColor: AppColors.primaryGreen, behavior: SnackBarBehavior.floating),
        );
        _fetchQueries(); // List reload karo
      } else {
        throw Exception("Failed to submit reply");
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.redAccent),
      );
    }
  }

  // 4. Premium Bottom Sheet for replying
  void _showReplyBottomSheet(dynamic query) {
    _replyController.text = query['answer'] ?? "";
    final bool isAlreadyResolved = query['is_resolved'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20, left: 20, right: 20
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isAlreadyResolved ? "View Discussion" : "Write Reply", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            Text("Student: ${query['student_name']}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(height: 4),
            Text("Question: ${query['question']}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            TextField(
              controller: _replyController,
              maxLines: 4,
              enabled: !isAlreadyResolved,
              decoration: InputDecoration(
                hintText: "Type your answer here...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bgDark : Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 20),
            if (!isAlreadyResolved)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _submitReply(query['id']),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text("Send Response", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: const Text("Student Queries"),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterChipsBar(isDark),
          Expanded(child: _buildMainContent(isDark)),
        ],
      ),
    );
  }

  Widget _buildFilterChipsBar(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade200))
      ),
      child: Row(
        children: ['All', 'Pending', 'Resolved'].map((label) {
          final isSelected = _selectedFilter == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.primaryBlue,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textMuted, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedFilter = label);
                  _applyFilter();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMainContent(bool isDark) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue));

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error: $_errorMessage", style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _fetchQueries, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_filteredQueries.isEmpty) return _buildEmptyState(isDark);

    return RefreshIndicator(
      onRefresh: _fetchQueries,
      color: AppColors.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: _filteredQueries.length,
        itemBuilder: (context, index) {
          final query = _filteredQueries[index];
          return _buildQueryCard(query, isDark);
        },
      ),
    );
  }

  Widget _buildQueryCard(dynamic query, bool isDark) {
    final isResolved = query['is_resolved'] ?? false;
    final forestGreen = const Color(0xFF1B5E20);
    final pendingColor = Colors.orange.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(query['student_name'] ?? "Anonymous Student", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isResolved ? forestGreen.withOpacity(0.1) : pendingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isResolved ? "Resolved" : "Pending",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isResolved ? forestGreen : pendingColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("${query['course_name']} • ${query['lesson_title']}", style: const TextStyle(fontSize: 12, color: AppColors.primaryCyan, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(query['question'] ?? "", style: const TextStyle(fontSize: 14, height: 1.3)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(query['created_at_formatted'] ?? "", style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showReplyBottomSheet(query),
                  icon: Icon(isResolved ? Icons.visibility : Icons.reply, size: 16),
                  label: Text(isResolved ? "View Discussion" : "Reply Now"),
                  style: TextButton.styleFrom(
                    foregroundColor: isResolved ? AppColors.textMuted : AppColors.primaryBlue,
                    backgroundColor: isResolved ? Colors.transparent : AppColors.primarySoft,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 60, color: AppColors.textMuted.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text("No Queries Found", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("No student doubts match this filter.", style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}