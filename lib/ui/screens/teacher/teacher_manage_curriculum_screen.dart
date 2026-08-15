import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import 'teacher_add_lesson_screen.dart';
import 'teacher_edit_lesson_screen.dart';

class TeacherManageCurriculumScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const TeacherManageCurriculumScreen({
    super.key,
    required this.courseId,
    required this.courseTitle
  });

  @override
  State<TeacherManageCurriculumScreen> createState() => _TeacherManageCurriculumScreenState();
}

class _TeacherManageCurriculumScreenState extends State<TeacherManageCurriculumScreen> {
  final TextEditingController _moduleTitleCtrl = TextEditingController();
  List<dynamic> _modules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<AuthProvider>(context, listen: false);
    final modules = await provider.fetchModules(widget.courseId);

    if(mounted) {
      setState(() {
        _modules = modules;
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewModule() async {
    if (_moduleTitleCtrl.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saving Module...")));

    final provider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await provider.addModule(widget.courseId, _moduleTitleCtrl.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (success) {
      _moduleTitleCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Module Added!"), backgroundColor: AppColors.primaryGreen));
      _loadModules();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to add module"), backgroundColor: Colors.red));
    }
  }

  void _navigateToAddLesson(int moduleId, String moduleTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherAddLessonScreen(
          moduleId: moduleId,
          moduleTitle: moduleTitle,
        ),
      ),
    ).then((value) {
      if (value == true) {
        _loadModules();
      }
    });
  }

  // 🚀 NAYA FUNCTION: Lesson delete confirm karne ke liye
  // 🚀 NAYA FUNCTION: Context shadowing fix ke sath
  void _confirmDeleteLesson(int lessonId) {
    showDialog(
      context: context,
      // 🚀 FIX: Isko 'dialogContext' naam de diya taaki clash na ho
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Lesson?"),
        content: const Text("Are you sure you want to delete this lesson? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // 🚀 dialogContext use kiya
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              // 1. Dialog band karo dialogContext se
              Navigator.pop(dialogContext);

              // 2. Ab asli 'context' (main screen ka) use karke Snackbar dikhao
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Deleting..."))
              );

              // 3. API Call bhi main context se
              bool success = await Provider.of<AuthProvider>(context, listen: false).deleteLesson(lessonId);

              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lesson deleted successfully!"), backgroundColor: AppColors.primaryGreen));
                _loadModules(); // List refresh karega
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to delete lesson."), backgroundColor: Colors.red));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Manage Curriculum", style: TextStyle(fontSize: 16)),
            Text(widget.courseTitle, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.cardDark : Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Add New Module / Chapter", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _moduleTitleCtrl,
                        decoration: InputDecoration(
                          hintText: "Enter Module Title...",
                          filled: true,
                          fillColor: isDark ? AppColors.bgDark : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _addNewModule,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                      ),
                      child: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _modules.isEmpty
                ? const Center(child: Text("No modules added yet.", style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _modules.length,
              itemBuilder: (context, index) {
                final module = _modules[index];
                final List lessons = module['lessons'] ?? [];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: isDark ? AppColors.cardDark : Colors.white,
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    title: Text(module['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      if (lessons.isNotEmpty)
                        ...lessons.map((lesson) {
                          bool isVideo = lesson['lesson_type'] == 'Video';
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                  color: isVideo ? AppColors.primaryBlue.withOpacity(0.1) : AppColors.primaryGreen.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8)
                              ),
                              child: Icon(
                                  isVideo ? Icons.play_circle_fill : Icons.picture_as_pdf,
                                  color: isVideo ? AppColors.primaryBlue : AppColors.primaryGreen
                              ),
                            ),
                            title: Text(lesson['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            subtitle: Text(isVideo ? "Video Lesson" : "Document Lesson", style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            // 🚀 FIX: Yahan Edit aur Delete dono Button daal diye hain!
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: AppColors.primaryBlue, size: 20),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TeacherEditLessonScreen(
                                          lesson: lesson,
                                          moduleTitle: module['title'],
                                        ),
                                      ),
                                    ).then((value) {
                                      if (value == true) {
                                        _loadModules();
                                      }
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () => _confirmDeleteLesson(lesson['id']),
                                ),
                              ],
                            ),
                          );
                        }),

                      if (lessons.isNotEmpty) const Divider(),

                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: OutlinedButton.icon(
                          onPressed: () => _navigateToAddLesson(module['id'], module['title']),
                          icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen),
                          label: const Text("Add Lesson to this Module", style: TextStyle(color: AppColors.primaryGreen)),
                          style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primaryGreen),
                              minimumSize: const Size(double.infinity, 45)
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}