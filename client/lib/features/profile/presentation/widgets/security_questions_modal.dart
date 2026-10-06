import 'package:flutter/material.dart';
import '../../../../features/auth/presentation/screens/security_questions_setup_screen.dart';

/// Helper to launch the Security & Recovery Questions screen either modally or as a full route
class SecurityQuestionsModal {
  static Future<bool?> show(BuildContext context, {String? userEmail, String? userPhone}) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SecurityRecoveryQuestionsScreen(
          userEmail: userEmail,
          userPhone: userPhone,
        ),
      ),
    );
  }
}
