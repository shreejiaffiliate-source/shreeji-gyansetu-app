import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/gyansetu_interstitial_ad.dart'; // 🎯 NAYA: Interstitial Ad Import

class TeacherAddLessonScreen extends StatefulWidget {
  final int moduleId;
  final String moduleTitle;

  const TeacherAddLessonScreen({super.key, required this.moduleId, required this.moduleTitle});
  @override
  State<TeacherAddLessonScreen> createState() => _TeacherAddLessonScreenState();
}

class _TeacherAddLessonScreenState extends State<TeacherAddLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _resourcesCtrl = TextEditingController();

  String _selectedType = 'Video';
  bool _isFreePreview = false;

  File? _videoFile;
  File? _pdfFile;

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result != null) setState(() => _videoFile = File(result.files.single.path!));
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) setState(() => _pdfFile = File(result.files.single.path!));
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == 'Video' && _videoFile == null && _videoUrlCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a Video URL or Upload an MP4 File"), backgroundColor: Colors.red));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading Lesson... This might take a minute.")));

    final provider = Provider.of<AuthProvider>(context, listen: false);
    final result = await provider.uploadLesson(
      moduleId: widget.moduleId,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lesson uploaded successfully!"), backgroundColor: AppColors.primaryGreen));

      // 🎯 NAYA CHANGE: Lesson add hone ke baad Ad show karo
      GyansetuInterstitialAd.showAd(
        onComplete: () {
          Navigator.pop(context, true);
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
      appBar: AppBar(title: const Text("Upload Lesson")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text("Adding to: ${widget.moduleTitle}", style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 20),

            _buildTextField(_titleCtrl, "Lesson Title", hint: "e.g. Introduction to Python", isRequired: true),

            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedType,
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
              _buildTextField(_videoUrlCtrl, "Video Link (YouTube/Vimeo)", hint: "Paste link here if not uploading file", isRequired: false),

              const Text("Upload File (MP4)", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFilePickerBtn("Choose Video File", _videoFile, _pickVideo),
              const SizedBox(height: 16),
            ],

            const Text("Notes PDF", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildFilePickerBtn("Choose PDF File", _pdfFile, _pickPdf),
            const Text("Upload a PDF that students can view while watching.", style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 16),

            _buildTextField(_resourcesCtrl, "Lesson Resources (Links/Text)", maxLines: 3, hint: "GitHub links or extra info...", isRequired: false),

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
                onPressed: _saveLesson,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Save Lesson", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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