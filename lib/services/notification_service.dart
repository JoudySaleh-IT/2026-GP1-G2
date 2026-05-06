import 'package:flutter/material.dart';

// 1. Create a global key for the ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class NotificationService {
  // 2. Create a static method that takes just the message
  static void showSuccessSnackBar(String message) {
    // We use the global key to show the SnackBar anywhere in the app
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Tajawal'), // Your custom font
        ),
        backgroundColor: const Color(0xFF511281), // Your Faseh primary color
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Optional: You can also add an error snackbar method with a red color!
  static void showErrorSnackBar(String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
