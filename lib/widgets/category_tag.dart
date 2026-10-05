import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small coloured label showing a session's category, e.g. "Keynote".
class CategoryTag extends StatelessWidget {
  const CategoryTag({
    super.key,
    required this.category,
    this.uppercase = false,
  });

  final String category;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        uppercase ? category.toUpperCase() : category,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  static Color categoryColor(String category) {
    switch (category) {
      case 'Keynote':
        return AppColors.primary;
      case 'Sustainability':
        return AppColors.tertiary;
      case 'Deep Tech':
        return const Color(0xFF7C3AED);
      case 'Hardware':
        return const Color(0xFFEA580C);
      default:
        return AppColors.secondary;
    }
  }
}

/// "Dr. Lukas Weber" -> "LW". Skips titles ending with a dot.
String initialsOf(String name) {
  final parts = name
      .split(' ')
      .where((p) => p.isNotEmpty && !p.endsWith('.'))
      .toList();
  if (parts.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 ? parts.last[0] : '';
  return (first + last).toUpperCase();
}
