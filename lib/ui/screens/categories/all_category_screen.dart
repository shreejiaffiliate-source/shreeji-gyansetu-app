import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_service.dart';
import '../../widgets/category_item.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Categories",),
        // leading: BackButton(
        //   color: Colors.white,
        // ),
        // backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: ApiService().getHomeData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Error loading categories"));
          }

          final List categories = snapshot.data!['categories'] ?? [];

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 icons per row
              mainAxisSpacing: 20,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              // Reusing your existing CategoryItem widget for consistency
              return CategoryItem(category: categories[index]);
            },
          );
        },
      ),
    );
  }
}