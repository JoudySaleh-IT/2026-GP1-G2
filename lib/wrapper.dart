import 'package:faseh/screens/parent_dashboard_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/parent_login_screen.dart';
import 'screens/parent_dashboard_screen.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Waiting for Firebase to restore auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ); // simple loading while checking
        }
        // User is logged in → show dashboard
        if (snapshot.hasData) {
          return ParentDashboardScreen();
        }
        // User is NOT logged in → show your splash screen (landing page with buttons)
        return SplashScreen();
      },
    );
  }
}
