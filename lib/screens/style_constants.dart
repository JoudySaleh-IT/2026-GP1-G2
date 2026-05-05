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

  // You can also store your primary colors here to use elsewhere
  static const Color primaryDark = Color(0xFF511281);
  static const Color primaryLight = Color(0xFF7A3FA8);
  static const Color backgroundBeige = Color(0xFFFCF9EA);
}
