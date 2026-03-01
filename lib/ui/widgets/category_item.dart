import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../screens/categories/category_detail.dart';

class CategoryItem extends StatelessWidget {
  final dynamic category;

  const CategoryItem({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    debugPrint("Category Data: $category");

    final String iconClass = (category['icon_class'] ?? '').toString();
    final String categoryName = (category['name'] ?? category['title'] ?? 'Category').toString();
    final String categorySlug = (category['slug'] ?? '').toString();

    return InkWell(
      onTap: () {
        // 3. Navigate to CategoryDetailScreen with category data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(
              categoryName: categoryName,
              categorySlug: categorySlug,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 15),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.primarySoft, // Soft blue from our AppColors
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.1)),
              ),
              child: Icon(
                _getIconData(iconClass),
                color: AppColors.primaryBlue,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              categoryName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple helper to map FontAwesome strings from Django to Flutter Icons
  IconData _getIconData(String? iconClass) {
    // Use a null check to prevent errors if the field is empty
    if (iconClass == null) return Icons.category;

    switch (iconClass.trim()) {
      case 'fa-solid fa-computer':
        return Icons.computer;

      case 'fa-briefcase':
        return Icons.business_center;

      case 'fa-money-bill':
        return Icons.payments; // This matches the "finance" look well

      default:
      // Fallback if the string doesn't match perfectly
        return Icons.category;
    }
  }
}