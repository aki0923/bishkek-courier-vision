import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

class Helpers {
  /// Format date to relative time (e.g., "2 hours ago")
  static String formatRelativeTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'только что';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} мин назад';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ч назад';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} дн назад';
      } else if (difference.inDays < 30) {
        return '${(difference.inDays / 7).floor()} нед назад';
      } else {
        return '${(difference.inDays / 30).floor()} мес назад';
      }
    } catch (e) {
      return dateString;
    }
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Show error snackbar
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Copy text to clipboard with feedback
  static Future<void> copyToClipboard(
      BuildContext context,
      String text, {
        String? successMessage,
      }) async {
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      showSuccess(
        context,
        successMessage ?? 'Скопировано в буфер обмена',
      );
    }
  }

  /// Format points with proper Russian declension
  static String formatPoints(int points) {
    final lastTwo = points % 100;
    final lastOne = points % 10;

    if (lastTwo >= 11 && lastTwo <= 19) {
      return '$points баллов';
    } else if (lastOne == 1) {
      return '$points балл';
    } else if (lastOne >= 2 && lastOne <= 4) {
      return '$points балла';
    } else {
      return '$points баллов';
    }
  }

  /// Get status color
  static Color getStatusColor(String? status) {
    switch (status) {
      case 'novice':
        return AppTheme.textSecondary;
      case 'helper':
        return AppTheme.primaryBlue;
      case 'expert':
        return AppTheme.accentYellow;
      case 'master':
        return Colors.pinkAccent;
      default:
        return AppTheme.textSecondary;
    }
  }

  /// Get status label
  static String getStatusLabel(String? status) {
    switch (status) {
      case 'novice':
        return 'Новичок';
      case 'helper':
        return 'Помощник';
      case 'expert':
        return 'Эксперт';
      case 'master':
        return 'Мастер';
      default:
        return 'Курьер';
    }
  }

  /// Confirm dialog
  static Future<bool> confirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        String confirmText = 'Да',
        String cancelText = 'Отмена',
        bool isDangerous = false,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: isDangerous
                ? ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
            )
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}



