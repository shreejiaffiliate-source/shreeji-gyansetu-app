import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscuredOld = true;
  bool _isObscuredNew = true;
  bool _isObscuredConfirm = true;
  bool _isLoading = false;

  Future<void> _updatePassword() async {
    // 1. Basic Field Validation (Required checks)
    if (!_formKey.currentState!.validate()) return;

    final oldPass = _oldPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    // 2. Logic: New and Old password should not be same
    if (oldPass == newPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("New password cannot be the same as old password!")),
      );
      return;
    }

    // 3. Logic: Match New and Confirm Password
    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Backend Call
    final success = await ApiService().changePassword(oldPass, newPass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully!")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update. Please check your old password.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primaryBlue,
      ),
      body: SingleChildScrollView( // Added for keyboard overflow safety
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 10),
              _buildPasswordField(
                controller: _oldPasswordController,
                label: "Old Password",
                isObscured: _isObscuredOld,
                onToggle: () => setState(() => _isObscuredOld = !_isObscuredOld),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _newPasswordController,
                label: "New Password",
                isObscured: _isObscuredNew,
                onToggle: () => setState(() => _isObscuredNew = !_isObscuredNew),
              ),
              const SizedBox(height: 20),
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: "Confirm New Password",
                isObscured: _isObscuredConfirm,
                onToggle: () => setState(() => _isObscuredConfirm = !_isObscuredConfirm),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Field required";
                  if (value != _newPasswordController.text) return "Passwords do not match";
                  return null;
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updatePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save New Password", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated with Theme Color matching border
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isObscured,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isObscured,
      cursorColor: AppColors.primaryBlue,
      validator: validator ?? (value) => (value == null || value.isEmpty) ? "Field required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        floatingLabelStyle: const TextStyle(color: AppColors.primaryBlue),

        // Default Border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),

        // Focus Border (Theme Color Match)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),

        suffixIcon: IconButton(
          icon: Icon(isObscured ? Icons.visibility_off : Icons.visibility, size: 20),
          color: AppColors.textMuted,
          onPressed: onToggle,
        ),
      ),
    );
  }
}