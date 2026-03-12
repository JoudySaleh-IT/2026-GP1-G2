import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/parent_register_screen.dart';
import 'screens/parent_login_screen.dart';
import 'screens/forgot_password_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ─── App Name ────────────────────────────────────────────────
      title: 'فصيح',

      // ─── Hide the debug banner in the top right corner ───────────
      debugShowCheckedModeBanner: false,

      // ─── RTL Support for Arabic ──────────────────────────────────
      // This makes the entire app layout go right-to-left by default
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },

      // ─── Global App Theme ────────────────────────────────────────
      // These colors apply across the whole app unless overridden
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF511281), // Your purple brand color
        ),
        useMaterial3: true,

        // Default font for Arabic text rendering
        fontFamily: 'Tajawal', // See pubspec.yaml setup below if you want this font
      ),

      // ─── Starting Screen ─────────────────────────────────────────
      // This is the first screen users see when they open the app
      home: const SplashScreen(),

      // ─── Named Routes ────────────────────────────────────────────
      // These let you navigate between screens using Navigator.pushNamed()
      // As you build more screens, add them here.
      routes: {
        // TODO: This is the main area that has all the paths, so when you add a new page the path should be here
        // once you build them, e.g:
        // '/parent/register': (context) => const ParentRegisterScreen(),
        '/parent/register': (context) => const ParentRegisterScreen(),
        '/parent/login': (context) => const ParentLoginScreen(),
        '/parent/forgot-password': (context) => const ForgotPasswordScreen(),

      },
    );
  }
}

// ─── Temporary Placeholder Screen ──────────────────────────────────────────
// This is just a stand-in screen so buttons don't crash the app.
// Delete this once you have real screens built.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF511281),
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Color(0xFF511281)),
            const SizedBox(height: 16),
            Text(
              'شاشة $title\nقيد الإنشاء',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF511281),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF511281),
                foregroundColor: Colors.white,
              ),
              child: const Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }
}
