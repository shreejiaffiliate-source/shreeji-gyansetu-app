import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/theme_provider.dart';

// Ye screens shayad aapke profile folder mein hain, absolute path use kar raha hu taaki error na aaye
import 'package:gyansetu/ui/screens/profile/support_screen.dart';
import 'package:gyansetu/ui/screens/profile/change_password_screen.dart';

// 🚀 Yahan naya Teacher Edit Profile import kiya hai
import 'teacher_edit_profile_screen.dart';

class TeacherProfileScreen extends StatelessWidget {
  const TeacherProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Consumer lagaya hai taaki photo/name change hote hi screen turant update ho jaye
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        // 💡 SAFE NAME LOGIC
        String displayName = "Teacher";
        if (user != null) {
          String fName = (user.firstName ?? "").trim();
          String lName = (user.lastName ?? "").trim();
          String uName = (user.username ?? "").trim();

          if (fName.isNotEmpty) {
            displayName = "$fName $lName".trim();
          } else if (uName.isNotEmpty) {
            displayName = uName;
          }
        }

        return Scaffold(
          appBar: AppBar(
              title: const Text("My Profile"),
              elevation: 0,
              centerTitle: true
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                // 1. SAFE PROFILE PICTURE LOGIC
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primarySoft,
                  backgroundImage: (user?.profilePhoto?.isNotEmpty == true)
                      ? NetworkImage(user!.profilePhoto!)
                      : null,
                  child: (user?.profilePhoto?.isNotEmpty == true)
                      ? null
                      : const Icon(Icons.person, size: 50, color: AppColors.primaryBlue),
                ),
                const SizedBox(height: 16),

                // 2. NAME & ROLE
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.userType ?? "Teacher",
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                ),
                const SizedBox(height: 30),

                // 3. MENU OPTIONS
                _buildProfileOption(Icons.edit, "Edit Profile", () {
                  Navigator.push(
                    context,
                    // 🚀 Yahan TeacherEditProfileScreen set kiya hai
                    MaterialPageRoute(builder: (context) => const TeacherEditProfileScreen()),
                  );
                }),

                // Theme Switcher (Ekdum Student Profile jaisa)
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return ListTile(
                      leading: Icon(
                        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: AppColors.primaryCyan,
                      ),
                      title: const Text("Dark Mode", style: TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (bool value) {
                          themeProvider.toggleTheme(value);
                        },
                        activeThumbColor: AppColors.primaryBlue,
                      ),
                    );
                  },
                ),

                _buildProfileOption(Icons.lock, "Change Password", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
                }),

                _buildProfileOption(Icons.headset_mic_outlined, "Contact Support", () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
                }),

                const SizedBox(height: 40),

                // 4. LOGOUT BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text("Logout"),
                          content: const Text("Are you sure you want to logout?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text("No", style: TextStyle(color: AppColors.textMuted)),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                // 🚀 Provider ka logout function call kar diya
                                await authProvider.logout();
                                if (!context.mounted) return;
                                Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
                              },
                              child: const Text("Yes", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryCyan),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}