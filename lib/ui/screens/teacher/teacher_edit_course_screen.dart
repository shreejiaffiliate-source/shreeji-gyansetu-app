import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/course_provider.dart';
import '../../widgets/gyansetu_interstitial_ad.dart'; // 🎯 NAYA: Interstitial Ad Import

class TeacherEditCourseScreen extends StatefulWidget {
  final dynamic course;

  const TeacherEditCourseScreen({super.key, required this.course});

  @override
  State<TeacherEditCourseScreen> createState() => _TeacherEditCourseScreenState();
}

class _TeacherEditCourseScreenState extends State<TeacherEditCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _thumbnailImage;

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _discountPriceCtrl;

  late String _selectedLevel;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.course['title']);
    _descCtrl = TextEditingController(text: widget.course['description']);

    _priceCtrl = TextEditingController(text: widget.course['price']?.toString() ?? "0");
    _discountPriceCtrl = TextEditingController(text: widget.course['discount_price']?.toString() ?? "");

    _selectedLevel = widget.course['level'] ?? 'Beginner';
    if (!['Beginner', 'Intermediate', 'Advanced'].contains(_selectedLevel)) {
      _selectedLevel = 'Beginner';
    }

    if (widget.course['master_category'] != null) {
      if (widget.course['master_category'] is Map) {
        _selectedCategoryId = widget.course['master_category']['id']?.toString();
      } else {
        _selectedCategoryId = widget.course['master_category']?.toString();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).fetchCategories();
    });
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) setState(() => _thumbnailImage = File(result.files.single.path!));
  }

  Future<void> _updateCourse() async {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updating course...")));

    final data = {
      "title": _titleCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "price": _priceCtrl.text.trim(),
      "discount_price": _discountPriceCtrl.text.trim(),
      "level": _selectedLevel,
      "master_category_id": _selectedCategoryId ?? "",
    };

    final result = await Provider.of<AuthProvider>(context, listen: false)
        .updateCourse(widget.course['id'], data, _thumbnailImage);

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result == "success") {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Course Updated Successfully!"), backgroundColor: AppColors.primaryGreen));

      // 🎯 NAYA CHANGE: Update hone ke baad Interstitial Ad dikhegi fir back jayega
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
    final courseProvider = Provider.of<CourseProvider>(context);
    final categories = courseProvider.categories;

    if (categories.isNotEmpty && _selectedCategoryId != null) {
      bool exists = categories.any((cat) => cat['id'].toString() == _selectedCategoryId);
      if (!exists) _selectedCategoryId = null;
    }

    String? oldImageUrl;
    if (widget.course['thumbnail'] != null) {
      oldImageUrl = widget.course['thumbnail'];
      if (oldImageUrl!.startsWith('/')) {
        final hostUrl = ApiEndpoints.baseUrl.replaceAll('/api', '');
        oldImageUrl = "$hostUrl$oldImageUrl";
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text("Edit Course Info"), elevation: 0),
      body: courseProvider.isLoading && categories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _thumbnailImage != null
                      ? Image.file(_thumbnailImage!, fit: BoxFit.cover)
                      : (oldImageUrl != null
                      ? CachedNetworkImage(imageUrl: oldImageUrl, fit: BoxFit.cover)
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 50, color: AppColors.primaryBlue),
                      SizedBox(height: 8),
                      Text("Upload New Thumbnail", style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600))
                    ],
                  )),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text("Tap image to change thumbnail", style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
            const SizedBox(height: 24),

            _buildTextField(_titleCtrl, "Course Title"),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedCategoryId,
                    decoration: InputDecoration(
                      labelText: "Category",
                      filled: true,
                      fillColor: isDark ? AppColors.bgDark : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                    ),
                    items: categories.map<DropdownMenuItem<String>>((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'].toString(),
                        child: Text(cat['title'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? "Required" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedLevel,
                    decoration: InputDecoration(
                      labelText: "Difficulty Level",
                      filled: true,
                      fillColor: isDark ? AppColors.bgDark : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                    ),
                    items: ['Beginner', 'Intermediate', 'Advanced'].map((lvl) {
                      return DropdownMenuItem(value: lvl, child: Text(lvl, overflow: TextOverflow.ellipsis));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedLevel = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildTextField(_descCtrl, "Course Description", maxLines: 4),

            Row(
              children: [
                Expanded(child: _buildTextField(_priceCtrl, "Regular Price (₹)", keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_discountPriceCtrl, "Discount Price (₹)", keyboardType: TextInputType.number, isRequired: false)),
              ],
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: _updateCourse,
                child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: isRequired ? (value) => value == null || value.trim().isEmpty ? "Required" : null : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bgDark : Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
        ),
      ),
    );
  }
}