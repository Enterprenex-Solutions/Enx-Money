import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// In-app notification and toast alert service
class NotificationService {
  NotificationService._();

  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Show Success Snackbar
  static void showSuccess(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_rounded,
    );
  }

  /// Show Error Snackbar
  static void showError(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error_rounded,
    );
  }

  /// Show Info Snackbar
  static void showInfo(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info_rounded,
    );
  }

  /// Show Warning Snackbar
  static void showWarning(String message) {
    _showSnackBar(
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void _showSnackBar({
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    messengerKey.currentState?.removeCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: backgroundColor,
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
