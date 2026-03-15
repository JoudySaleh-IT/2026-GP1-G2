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
        print(
          '🔥 Wrapper build: connectionState = ${snapshot.connectionState}, hasData = ${snapshot.hasData}',
        );
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          print('🔥 User is logged in, showing dashboard');
          return ParentDashboardScreen();
        }
        print('🔥 No user, showing splash');
        return SplashScreen();
      },
    );
  }
}
