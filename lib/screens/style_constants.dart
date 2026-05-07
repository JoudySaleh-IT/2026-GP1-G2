import 'package:flutter/material.dart';

class FaseehStyle {
  // The exact gradient you love
  static const BoxDecoration headerDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
    ),
    boxShadow: [
      BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
    ],
  );

  static EdgeInsets getStandardPadding(BuildContext context) {
    return EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 8,
      bottom: 12,
      right: 20,
      left: 20,
    );
  }

  // NEW: larger padding (exactly as in _EditHeader)
  static EdgeInsets getLargeHeaderPadding(BuildContext context) {
    return EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 8,
      bottom: 12,
      right: 16,
      left: 16,
    );
  }

  // NEW: Standard large header (matches _EditHeader style)
  static Widget buildLargeHeader({
    required BuildContext context,
    required String title,
    String? subtitle,
    Widget? leading, // e.g., back button
    List<Widget>?
    trailingActions, // for multiple icons (edit/delete, logout, etc.)
  }) {
    return Container(
      decoration: headerDecoration,
      padding: getLargeHeaderPadding(context),
      child: Row(
        children: [
          if (leading != null) leading,
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'Tajawal',
                    ),
                  ),
              ],
            ),
          ),
          if (trailingActions != null) Row(children: trailingActions),
        ],
      ),
    );
  }
}
