import 'package:flutter/material.dart';
import 'package:gyansetu/data/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // 1. Controllers for common fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 2. Controllers for Teacher-specific fields
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _isObscured = true;

  String _selectedUserType = 'Student'; // Default choice

  void _handleRegister() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all mandatory fields")),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.register(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      userType: _selectedUserType,
      qualification: _qualificationController.text.trim(),
      experience: _experienceController.text.trim(),
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP has been sent to your email!")),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(email: _emailController.text.trim()),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Register Failed. Username/Email might be taken")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Create Account",
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.primaryBlue,
                fontSize: 28,
              ),
            ),
            const Text("Join the Shreeji GyanSetu community",
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 32),

            // User Type Selector (Dropdown)
            const Text("Register As", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedUserType,
                  isExpanded: true,
                  items: ['Student', 'Teacher'].map((String type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedUserType = value!);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Common Fields
            Row(
              children: [
                Expanded(child: CustomTextField(hintText: "First Name", icon: Icons.person_outline, controller: _firstNameController)),
                const SizedBox(width: 10),
                Expanded(child: CustomTextField(hintText: "Last Name", icon: Icons.person_outline, controller: _lastNameController)),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(hintText: "Username", icon: Icons.alternate_email, controller: _usernameController),
            const SizedBox(height: 16),
            CustomTextField(hintText: "Email Address", icon: Icons.email_outlined, controller: _emailController),
            const SizedBox(height: 16),
            CustomTextField(
              hintText: "Password",
              icon: Icons.lock_outline,
              controller: _passwordController,
              isPassword: _isObscured, // Use the state here
              suffixIcon: IconButton(
                icon: Icon(
                  _isObscured ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              ),
            ),

            // Conditional Teacher Fields
            if (_selectedUserType == 'Teacher') ...[
              const SizedBox(height: 24),
              const Text("Professional Background", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryCyan)),
              const SizedBox(height: 12),
              CustomTextField(hintText: "Qualification (e.g. M.Sc)", icon: Icons.history_edu, controller: _qualificationController),
              const SizedBox(height: 16),
              CustomTextField(hintText: "Years of Experience", icon: Icons.work_outline, controller: _experienceController),
            ],

            const SizedBox(height: 40),
            CustomButton(
              text: "Create Account",
              onPressed: _handleRegister,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
