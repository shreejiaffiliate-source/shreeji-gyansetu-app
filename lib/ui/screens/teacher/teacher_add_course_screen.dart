import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/course_provider.dart';
import '../../widgets/gyansetu_interstitial_ad.dart'; // 🎯 NAYA: Interstitial Ad Import

class TeacherAddCourseScreen extends StatefulWidget {
  const TeacherAddCourseScreen({super.key});

  @override
  State<TeacherAddCourseScreen> createState() => _TeacherAddCourseScreenState();
}

class _TeacherAddCourseScreenState extends State<TeacherAddCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _thumbnailImage;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _discountPriceCtrl = TextEditingController();

  String _selectedLevel = 'Beginner';
  String? _selectedCategoryId;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _thumbnailImage = File(pickedFile.path));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CourseProvider>(context, listen: false).fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final courseProvider = Provider.of<CourseProvider>(context);
    final categories = courseProvider.categories;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(title: const Text("Create New Course"), elevation: 0),
      // 🚀 FIX: Jab tak categories load na ho, loader dikhao taaki dropdown khali na rahe
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
                  color: isDark ? AppColors.cardDark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  image: _thumbnailImage != null ? DecorationImage(image: FileImage(_thumbnailImage!), fit: BoxFit.cover) : null,
                  border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3), width: 2),
                ),
                child: _thumbnailImage == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 50, color: AppColors.primaryBlue),
                    SizedBox(height: 8),
                    Text("Upload Course Thumbnail", style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600))
                  ],
                )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(_titleCtrl, "Course Title"),

            // 🚀 CATEGORY & LEVEL ROW
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true, // 🚀 YAHAN YE LINE ADD KAR
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
                        child: Text(cat['title'] ?? 'Unknown', overflow: TextOverflow.ellipsis), // 👈 isExpanded ke sath ellipsis kaam karega
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? "Required" : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true, // 🚀 YAHAN BHI YE LINE ADD KAR
                    value: _selectedLevel,
                     decoration: InputDecoration(
                      labelText: "Difficulty Level",
                      filled: true,
                      fillColor: isDark ? AppColors.bgDark : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2)),
                    ),
                    items: ['Beginner', 'Intermediate', 'Advanced'].map((lvl) {
                      return DropdownMenuItem(value: lvl, child: Text(lvl, overflow: TextOverflow.ellipsis)); // Yahan bhi ellipsis laga de safe side
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
                Expanded(
                  child: _buildTextField(_priceCtrl, "Regular Price (₹)", keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(_discountPriceCtrl, "Discount Price (₹)", keyboardType: TextInputType.number, isRequired: false),
                ),
              ],
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (_thumbnailImage == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a thumbnail")));
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Creating course...")));

                    final data = {
                      "title": _titleCtrl.text.trim(),
                      "description": _descCtrl.text.trim(),
                      "price": _priceCtrl.text.trim(),
                      "discount_price": _discountPriceCtrl.text.trim(),
                      "level": _selectedLevel,
                      "master_category_id": _selectedCategoryId!,
                    };

                    final result = await Provider.of<AuthProvider>(context, listen: false).createCourse(data, _thumbnailImage);

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();

                    if (result == "success") {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Course Created Successfully!"), backgroundColor: Colors.green));

                      // 🎯 NAYA CHANGE: Course create hone ke baad full screen ad dikhegi, fir back hoga
                      GyansetuInterstitialAd.showAd(
                        onComplete: () {
                          Navigator.pop(context);
                        },
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text("Create Course", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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