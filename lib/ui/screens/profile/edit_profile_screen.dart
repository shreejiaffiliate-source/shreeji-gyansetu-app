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

  // 1. ADD THIS FUNCTION to show the DatePicker
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));

    // Attempt to parse existing date if it exists
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
              primary: AppColors.primaryBlue, // header background color
              onPrimary: Colors.white, // header text color
              onSurface: AppColors.textDark, // body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // Formats the date to YYYY-MM-DD for Django
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
            _buildTextField(_email, "Email Address", keyboardType: TextInputType.emailAddress),
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
                // Prepare data for API
                Map<String, String> data = {
                  "first_name": _firstName.text,
                  "last_name": _lastName.text,
                  "email": _email.text,
                  "profile.branch": _branch.text,
                  "profile.enrollment_number": _enrollment.text,
                  "profile.college_name": _college.text,
                  "profile.qualification": _qualification.text,
                  "profile.date_of_birth": _dob.text,
                  "profile.bio": _bio.text,
                };

                final success = await Provider.of<AuthProvider>(context, listen: false)
                    .updateProfile(data, _imageFile);

                if (success && mounted) Navigator.pop(context);
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
        cursorColor: AppColors.primaryBlue, // Cursor ka color bhi match kar diya
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted),
          // Jab field selected/focused ho
          // floatingLabelStyle: const TextStyle(color: AppColors.primaryBlue),

          // Default border (binas select kiye)
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.borderColor),
          ),

          // ✅ Yeh hai fix: Jab field select ho (Focused)
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
          ),

          // Error border (optional but recommended)
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

  // Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1, TextInputType? keyboardType}) {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 15),
  //     child: TextFormField(
  //       controller: controller,
  //       maxLines: maxLines,
  //       keyboardType: keyboardType,
  //       decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
  //     ),
  //   );
  // }
