import 'package:flutter/material.dart';
import 'package:gyansetu/ui/screens/profile/support_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/theme_provider.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart'; // Create this next
import '../../../data/models/course_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), elevation: 0),
        body: SingleChildScrollView(
          // Added padding to give the whole screen some breathing room
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              // 1. Profile Picture
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primarySoft,
                backgroundImage: (user?.profilePhoto != null)
                    ? NetworkImage(user!.profilePhoto!)
                    : null,
                child: (user?.profilePhoto == null)
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),

              // Fetching actual Name from Django User Model
              Text(
                  "${user?.firstName ?? 'User'} ${user?.lastName ?? ''}".trim().isEmpty
                      ? user?.username ?? "User"
                      : "${user?.firstName ?? ''} ${user?.lastName ?? ''}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              Text(
                  user?.userType ?? "Student",
                  style: const TextStyle(color: AppColors.textMuted)
              ),
              const SizedBox(height: 30),

          _buildProfileOption(Icons.edit, "Edit Profile", () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            );
          }),

              // Theme Switcher
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ListTile(
                leading: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: AppColors.primaryCyan,
                ),
                title: const Text("Dark Mode"),
                trailing: Switch(
                  // IMPORTANT: This value must come from the provider
                  value: themeProvider.isDarkMode,
                  onChanged: (bool value) {
                    // This calls the toggleTheme method we just wrote
                    themeProvider.toggleTheme(value);
                  },
                  activeThumbColor: AppColors.primaryBlue,
                ),
              );
            },
          ),

              _buildProfileOption(Icons.lock, "Change Password", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                );
              }),
              _buildProfileOption(Icons.headset_mic_outlined, "Contact Support", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SupportScreen()),
                );
              }),
              const SizedBox(height: 60),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextButton.icon(
                  onPressed: () async {
                    await authProvider.logout();
                    if (!context.mounted) return;
                    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                      '/login',
                          (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryCyan),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}