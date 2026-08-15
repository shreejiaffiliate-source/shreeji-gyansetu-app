import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  late TextEditingController _firstName, _lastName, _email, _branch, _enrollment, _college, _qualification, _dob, _bio;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    print("User Data: ${user?.firstName} ${user?.lastName}");
    _firstName = TextEditingController(text: user?.firstName);
    _lastName = TextEditingController(text: user?.lastName);
    _email = TextEditingController(text: user?.email);
    _branch = TextEditingController(text: user?.branch);
    _enrollment = TextEditingController(text: user?.enrollmentNumber);
    _college = TextEditingController(text: user?.collegeName);
    _qualification = TextEditingController(text: user?.qualification);
    _dob = TextEditingController(text: user?.dateOfBirth);
    _bio = TextEditingController(text: user?.bio);
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));

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
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  backgroundColor: AppColors.primaryBlue,
                  radius: 50,
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null ? const Icon(Icons.camera_alt, size: 40, color: Colors.white,) : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_firstName, "First Name"),
            _buildTextField(_lastName, "Last Name"),
            // ✅ EMAIL KO READ-ONLY KAR DIYA HAI
            _buildTextField(
              _email,
              "Email Address",
              keyboardType: TextInputType.emailAddress,
              readOnly: true, // User ise touch nahi kar sakta
            ),
            _buildTextField(_branch, "Branch"),
            _buildTextField(_enrollment, "Enrollment Number"),
            _buildTextField(_college, "College/University Name"),
            _buildTextField(_qualification, "Current Qualification"),
            _buildTextField(
              _dob,
              "Date of Birth",
              readOnly: true,
              onTap: () => _selectDate(context),
              suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primaryBlue),
            ),
            _buildTextField(_bio, "Bio", maxLines: 3),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Updating profile..."), duration: Duration(seconds: 1)),
                  );

                  // 🚀 FIX: Email ko yahan se poora hata do.
                  // Email ki zaroorat nahi hai update karne ke liye.
                  Map<String, String> data = {
                    "first_name": _firstName.text.trim(),
                    "last_name": _lastName.text.trim(),
                    "profile.branch": _branch.text.trim(),
                    "profile.college_name": _college.text.trim(),
                    "profile.qualification": _qualification.text.trim(),
                    "profile.date_of_birth": _dob.text.trim(),
                    "profile.bio": _bio.text.trim(),
                  };

                  // 🚀 FIX: Enrollment Number empty ho toh safely handle karo
                  if (_enrollment.text.trim().isNotEmpty) {
                    data["profile.enrollment_number"] = _enrollment.text.trim();
                  } else {
                    data["profile.enrollment_number"] = "";
                  }

                  final result = await Provider.of<AuthProvider>(context, listen: false)
                      .updateProfile(data, _imageFile);

                  if (mounted) {
                    if (result == "success") {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Profile updated successfully!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(result),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        validator: (value) {
          if (label != "Email Address" && (value == null || value.trim().isEmpty)) {
            // Agar aapko baaki fields optional rakhni hain toh isko hata sakte ho
            return "Please enter your $label";
          }
          return null;
        },
        cursorColor: AppColors.primaryBlue,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}