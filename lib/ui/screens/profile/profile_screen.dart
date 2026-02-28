import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Profile"), elevation: 0),
      body: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primaryBlue,
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text("User Name", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Student Account", style: TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 30),

          _buildProfileOption(Icons.edit, "Edit Profile", () {}),

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
                  activeColor: AppColors.primaryBlue,
                ),
              );
            },
          ),

          _buildProfileOption(Icons.lock, "Change Password", () {}),
          _buildProfileOption(Icons.help_outline, "Contact Support", () {}),
          const Spacer(),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextButton.icon(
              onPressed: () async {
                await authProvider.logout();
                // Use pushAndRemoveUntil to clear the navigation stack
                // so the user can't go back to the profile after logging out.
                if (context.mounted){
                  Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                      );
                }
              },

              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
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