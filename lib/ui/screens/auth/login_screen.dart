import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../navigation_wrapper.dart';
import 'register_screen.dart';
import 'otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscured = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '305890739233-vl7frn1tvpo8kigp17aost7ffa86aidh.apps.googleusercontent.com',
  );

  void _handleGoogleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final Map<String, dynamic> googleData = {
        'email': googleUser.email,
        'google_id': googleUser.id,
        'first_name': googleUser.displayName?.split(' ').first ?? '',
        'last_name': googleUser.displayName?.split(' ').last ?? '',
      };

      bool success = await authProvider.loginWithGoogle(googleData);
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const NavigationWrapper()),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint("❌ Google Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Google Sign-In failed: $e")),
        );
      }
    }
  }

  void _handleLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields")));
      return;
    }

    try {
      bool success = await authProvider.login(
        _loginController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const NavigationWrapper()),
              (route) => false,
        );
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll("Exception: ", "");
      if (!mounted) return;
      if (errorMessage.contains("Email not verified")) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OtpVerificationScreen(email: _loginController.text.trim())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  // ✅ Forgot Password Dialog
  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController forgotEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your email to receive a verification OTP."),
            const SizedBox(height: 16),
            TextField(
              controller: forgotEmailController,
              decoration: const InputDecoration(
                hintText: "Email Address",
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String email = forgotEmailController.text.trim();
              if (email.isEmpty) return;

              // ✅ STEP 1: Dialog band hone se pehle Navigator aur AuthProvider ka reference le lo
              final navigator = Navigator.of(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);

              // ✅ STEP 2: Dialog band karo
              navigator.pop();

              // ✅ STEP 3: API Call karo
              bool sent = await authProvider.resendOtp(email);

              if (sent) {
                print("Moving to OTP Screen now...");

                // ✅ STEP 4: Ab saved 'navigator' use karo, 'context' nahi
                navigator.push(
                  MaterialPageRoute(
                    builder: (context) => OtpVerificationScreen(
                      email: email,
                      isPasswordReset: true,
                    ),
                  ),
                );
              } else {
                // Yahan snackbar ke liye primary context use kar sakte ho agar screen mounted hai
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to send OTP. Please try again.")),
                  );
                }
              }
            },
            child: const Text("Send OTP"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Image.asset('lib/assets/images/logo.png', height: 100, errorBuilder: (c, e, s) => const Icon(Icons.school, size: 80, color: AppColors.primaryBlue)),
                    const SizedBox(height: 16),
                    Text("Shreeji GyanSetu", style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppColors.primaryBlue, fontSize: 28)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Text("Welcome Back", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Text("Login to your account", style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 32),
              CustomTextField(hintText: "Username or Email", icon: Icons.person_outline, controller: _loginController),
              const SizedBox(height: 16),
              CustomTextField(
                hintText: "Password",
                icon: Icons.lock_outline,
                controller: _passwordController,
                isPassword: _isObscured,
                suffixIcon: IconButton(
                  icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () => _showForgotPasswordDialog(context), // ✅ Working Forgot Password
                      child: const Text("Forgot Password?", style: TextStyle(color: AppColors.primaryCyan))
                  )
              ),
              const SizedBox(height: 24),
              CustomButton(text: "Login", isLoading: authProvider.isAuthenticating, onPressed: _handleLogin),
              const SizedBox(height: 20),
              const Center(child: Text("OR", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: authProvider.isAuthenticating ? null : _handleGoogleLogin,
                  icon: Image.asset('lib/assets/images/google_logo.png', height: 24, width: 24),
                  label: const Text("Continue with Google", style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: AppColors.borderColor)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())), child: const Text("Register", style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final TextEditingController controller;
  final bool isPassword;
  final Widget? suffixIcon;
  const CustomTextField({super.key, required this.hintText, required this.icon, required this.controller, this.isPassword = false, this.suffixIcon});
  @override
  Widget build(BuildContext context) {
    return TextFormField(controller: controller, obscureText: isPassword, decoration: InputDecoration(hintText: hintText, prefixIcon: Icon(icon), suffixIcon: suffixIcon, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
  }
}