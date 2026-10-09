import 'package:flutter/material.dart';

// Global key for the ScaffoldMessenger
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class NotificationService {
 static void showSuccessSnackBar(String message) {
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
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

static void showErrorSnackBar(String message) {
  final messenger = rootScaffoldMessengerKey.currentState;

  if (messenger == null) return;

  // Prevent multiple SnackBars from stacking.
  messenger.hideCurrentSnackBar();

  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      backgroundColor: Colors.red.shade700,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      content: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  static void showLiveNotification({
    required String title,
    required String message,
    VoidCallback? onTap,
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
        content: GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: onTap == null
      ? null
      : () {
          messenger.hideCurrentSnackBar();
          onTap();
        },
  child: Directionality(
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
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}