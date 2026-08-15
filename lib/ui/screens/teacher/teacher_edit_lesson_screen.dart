import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/gyansetu_interstitial_ad.dart'; // 🎯 NAYA: Interstitial Ad Import

class TeacherEditLessonScreen extends StatefulWidget {
  final dynamic lesson;
  final String moduleTitle;

  const TeacherEditLessonScreen({super.key, required this.lesson, required this.moduleTitle});
  @override
  State<TeacherEditLessonScreen> createState() => _TeacherEditLessonScreenState();
}

class _TeacherEditLessonScreenState extends State<TeacherEditLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _videoUrlCtrl;
  late TextEditingController _resourcesCtrl;

  late String _selectedType;
  late bool _isFreePreview;

  File? _videoFile;
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.lesson['title'] ?? "");
    _videoUrlCtrl = TextEditingController(text: widget.lesson['video_url'] ?? "");
    _resourcesCtrl = TextEditingController(text: widget.lesson['resources'] ?? "");

    _selectedType = widget.lesson['lesson_type'] == 'Document' ? 'Document' : 'Video';
    _isFreePreview = widget.lesson['is_preview'] ?? false;
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) setState(() => _videoFile = File(result.files.single.path!));
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null) setState(() => _pdfFile = File(result.files.single.path!));
  }

  Future<void> _updateLesson() async {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updating Lesson...")));

    final provider = Provider.of<AuthProvider>(context, listen: false);
    final result = await provider.updateLesson(
      lessonId: widget.lesson['id'],
      title: _titleCtrl.text.trim(),
      type: _selectedType,
      videoUrl: _videoUrlCtrl.text.trim(),
      resources: _resourcesCtrl.text.trim(),
      isPreview: _isFreePreview,
      videoFile: _videoFile,
      pdfFile: _pdfFile,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result == "success") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lesson updated successfully!"), backgroundColor: AppColors.primaryGreen));

      // 🎯 NAYA CHANGE: Lesson update hone ke baad Ad show karo
      GyansetuInterstitialAd.showAd(
        onComplete: () {
          Navigator.pop(context, true); // Update hone ke baad list reload
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text("Edit Lesson")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text("Module: ${widget.moduleTitle}", style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 20),

            _buildTextField(_titleCtrl, "Lesson Title", isRequired: true),

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: "Type",
                  filled: true,
                  fillColor: isDark ? AppColors.bgDark : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['Video', 'Document'].map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl))).toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
            ),

            if (_selectedType == 'Video') ...[
              _buildTextField(_videoUrlCtrl, "Video Link (YouTube/Vimeo)", isRequired: false),

              const Text("Upload New Video File (MP4)", style: TextStyle(fontWeight: FontWeight.bold)),
              const Text("Leave empty to keep existing video", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 8),
              _buildFilePickerBtn("Choose Video File", _videoFile, _pickVideo),
              const SizedBox(height: 16),
            ],

            const Text("Notes PDF", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Leave empty to keep existing PDF", style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            _buildFilePickerBtn("Choose PDF File", _pdfFile, _pickPdf),
            const SizedBox(height: 16),

            _buildTextField(_resourcesCtrl, "Lesson Resources (Links/Text)", maxLines: 3, isRequired: false),

            SwitchListTile(
              title: const Text("Mark as Free Preview?"),
              value: _isFreePreview,
              activeThumbColor: AppColors.primaryBlue,
              onChanged: (val) => setState(() => _isFreePreview = val),
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _updateLesson,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Update Lesson", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? hint, int maxLines = 1, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: isRequired ? (value) => value == null || value.trim().isEmpty ? "Required" : null : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bgDark : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildFilePickerBtn(String label, File? file, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(4)),
              child: const Text("Choose File", style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(file != null ? file.path.split('/').last : "No file chosen", style: const TextStyle(color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}