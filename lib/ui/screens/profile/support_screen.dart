import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'help_center_screen.dart';
import '../../../core/constants/app_colors.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  // URL Launching for Phone Calls
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
  }

  // WhatsApp Support Function
  Future<void> _openWhatsApp() async {
    String phoneNumber = "919601591839"; // Support number
    String message = "Hello Shreeji GyanSetu Support, I need help.";

    final Uri whatsappAppUrl = Uri.parse(
        "whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}"
    );

    final Uri whatsappWebUrl = Uri.parse(
        "https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}"
    );

    try {
      if (await canLaunchUrl(whatsappAppUrl)) {
        await launchUrl(whatsappAppUrl);
      } else {
        await launchUrl(whatsappWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("WhatsApp launch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dynamic background based on AppTheme
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            // Uses theme-adaptive back button
            leading: const BackButton(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Support Center",
                  style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryBlue, AppColors.primaryCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                        top: 40,
                        right: -20,
                        child: CircleAvatar(
                            radius: 80,
                            backgroundColor: Colors.white.withOpacity(0.1)
                        )
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text("Instant Help",
                    style: TextStyle(color: AppColors.primaryBlue, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _buildQuickAction(
                      context,
                      title: "WhatsApp",
                      icon: FontAwesomeIcons.whatsapp,
                      color: AppColors.primaryGreen,
                      onTap: _openWhatsApp,
                    ),
                    const SizedBox(width: 15),
                    _buildQuickAction(
                      context,
                      title: "Call Us",
                      icon: Icons.phone_in_talk_outlined,
                      color: AppColors.primaryCyan,
                      onTap: () => _launchURL("tel:+919054648658"),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text("Self Service",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                // Corrected: Passing context to the helper method
                _buildModernTile(
                  context,
                  title: "Help Center / FAQs",
                  desc: "Get instant answers to common questions",
                  icon: Icons.auto_stories_outlined,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HelpCenterScreen())
                  ),
                ),
                const SizedBox(height: 40),
                const Center(
                  child: Text("App Version 1.0.0 • Made for Shreeji GyanSetu",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            // Adaptive color from AppTheme (cardBg or cardDark)
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                // Dynamic shadow opacity for Dark Mode clarity
                color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              FaIcon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // Corrected Function Signature
  Widget _buildModernTile(BuildContext context, {required String title, required String desc, required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(12),
        // Dynamic tile color matching your CourseCard
        tileColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // Uses 10% opacity blue from AppColors
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10)
          ),
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(desc, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}