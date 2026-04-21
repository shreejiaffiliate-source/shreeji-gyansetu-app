import 'package:flutter/material.dart';
import 'package:gyansetu/ui/screens/profile/support_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/theme_provider.dart';
import 'change_password_screen.dart';
import 'edit_profile_screen.dart';
import '../../../data/models/course_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 💡 Consumer lagaya hai taaki data save hote hi screen apne aap update ho jaye
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        // 💡 SAFE NAME LOGIC: Empty string ya null dono ko handle karega
        String displayName = "User";
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
          appBar: AppBar(title: const Text("Profile"), elevation: 0),
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
                      : const Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),

                // 2. NAME (Ab yahan pakka Dabhi Kashyap ya username aayega)
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                    user?.userType ?? "Student",
                    style: const TextStyle(color: AppColors.textMuted)
                ),
                const SizedBox(height: 30),

                // OPTIONS
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
                const SizedBox(height: 60),

                // LOGOUT BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
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
                    label: const Text("Logout", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}