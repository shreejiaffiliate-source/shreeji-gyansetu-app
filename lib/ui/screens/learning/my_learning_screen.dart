import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class MyLearningScreen extends StatelessWidget {
  const MyLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Learning")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2, // Placeholder until we connect the MyCourses API
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: Container(
                width: 60,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.play_lesson, color: AppColors.primaryBlue),
              ),
              title: const Text("Python Web Scraping", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Progress: 45%"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}