import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class TeacherEditProfileScreen extends StatefulWidget {
  const TeacherEditProfileScreen({super.key});

  @override
  State<TeacherEditProfileScreen> createState() => _TeacherEditProfileScreenState();
}

class _TeacherEditProfileScreenState extends State<TeacherEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;

  late TextEditingController _firstName, _lastName, _email, _qualification, _experience, _dob, _bio;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    _firstName = TextEditingController(text: user?.firstName);
    _lastName = TextEditingController(text: user?.lastName);
    _email = TextEditingController(text: user?.email);
    _qualification = TextEditingController(text: user?.qualification);
    _dob = TextEditingController(text: user?.dateOfBirth);
    _bio = TextEditingController(text: user?.bio);

    // 🚀 PERFECT FIX: Ab user model se asali data uthayega, 0 nahi dikhayega
    _experience = TextEditingController(text: user?.experienceYears?.toString() ?? "0");
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 25)); // Default age 25 for teachers

    if (_dob.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_dob.text);
      } catch (e) {
        debugPrint("Could not parse existing date: $e");
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dob.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: const Text("Edit Instructor Profile"),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.1),
                  radius: 55,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : (Provider.of<AuthProvider>(context, listen: false).user?.profilePhoto != null
                      ? NetworkImage(Provider.of<AuthProvider>(context, listen: false).user!.profilePhoto!) as ImageProvider
                      : null),
                  child: _imageFile == null && Provider.of<AuthProvider>(context, listen: false).user?.profilePhoto == null
                      ? const Icon(Icons.camera_alt, size: 40, color: AppColors.primaryBlue)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(child: Text("Tap to change photo", style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
            const SizedBox(height: 24),

            _buildSectionHeader("Personal Details"),
            Row(
              children: [
                Expanded(child: _buildTextField(_firstName, "First Name")),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField(_lastName, "Last Name")),
              ],
            ),

            // Email is read-only for security
            _buildTextField(
              _email,
              "Email Address",
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
              suffixIcon: const Icon(Icons.lock_outline, color: AppColors.textMuted, size: 18),
            ),

            _buildTextField(
              _dob,
              "Date of Birth",
              readOnly: true,
              onTap: () => _selectDate(context),
              suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primaryBlue, size: 20),
            ),

            const SizedBox(height: 16),
            _buildSectionHeader("Professional Details"),

            _buildTextField(_qualification, "Highest Qualification (e.g. M.Tech, PhD)"),

            _buildTextField(
              _experience,
              "Years of Experience",
              keyboardType: TextInputType.number,
              suffixIcon: const Padding(
                padding: EdgeInsets.all(14.0),
                child: Text("Years", style: TextStyle(color: AppColors.textMuted)),
              ),
            ),

            _buildTextField(_bio, "Professional Bio", maxLines: 4),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {

                    // 🚀 FIXED: BuildContext warning solved by storing references before await
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    messenger.showSnackBar(
                      const SnackBar(content: Text("Updating instructor profile..."), duration: Duration(seconds: 1)),
                    );

                    // 🚀 Save button ke andar ye check karein
                    Map<String, String> data = {
                      "first_name": _firstName.text,
                      "last_name": _lastName.text,
                      "email": _email.text,
                      "profile.qualification": _qualification.text,
                      "profile.experience_years": _experience.text, // <--- Ye value sahi hai?
                      "profile.date_of_birth": _dob.text,
                      "profile.bio": _bio.text,
                    };

// 🚀 Ye line add karke dekho terminal mein kya print hota hai
                    print("DEBUG: Sending to Backend: $data");

                    final result = await Provider.of<AuthProvider>(context, listen: false).updateProfile(data, _imageFile);

                    if (!mounted) return;
                    messenger.hideCurrentSnackBar();

                    if (result == "success") {
                      messenger.showSnackBar(
                        const SnackBar(content: Text("Profile updated successfully!"), backgroundColor: AppColors.primaryGreen, behavior: SnackBarBehavior.floating),
                      );
                      navigator.pop();
                    } else {
                      messenger.showSnackBar(
                        SnackBar(content: Text(result), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
                      );
                    }
                  }
                },
                child: const Text("Save Profile", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryCyan),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      {int maxLines = 1,
        TextInputType? keyboardType,
        bool readOnly = false,
        VoidCallback? onTap,
        Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return "Required";
          }
          return null;
        },
        cursorColor: AppColors.primaryBlue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.bgDark : Colors.grey.shade50,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}