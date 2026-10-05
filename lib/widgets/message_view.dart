import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centered icon, title and message, with an optional action button.
/// Used for empty and error states.
class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final label = actionLabel;
    final action = onAction;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          if (label != null && action != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: action,
              icon: const Icon(Icons.refresh),
              label: Text(label),
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}
