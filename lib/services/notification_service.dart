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
          style: const TextStyle(fontFamily: 'Tajawal'), 
        ),
        backgroundColor: const Color(0xFF511281), 
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Optional: We can also add an error snackbar method with a red color!
  static void showErrorSnackBar(String message) {
    rootScaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  static void showLiveNotification({
  required String title,
  required String message,
}) {
  final messenger = rootScaffoldMessengerKey.currentState;

  if (messenger == null) return;

  // Prevent multiple SnackBars from stacking.
  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      backgroundColor: const Color(0xFF511281),
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const Icon(
              Icons.notifications_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
