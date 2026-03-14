import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/parent_register_screen.dart';
import 'screens/parent_login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/parent_dashboard_screen.dart';
import 'screens/parent_settings_screen.dart';
import 'screens/child_selection_screen.dart';
import 'screens/child_home_screen.dart';
import 'screens/create_child_profile_screen.dart';
import 'screens/child_profile_management_screen.dart';
import 'screens/edit_child_profile_screen.dart';
import 'screens/exercises_screen.dart';
import 'screens/letter_levels_screen.dart';
import 'screens/exercise_mcq_screen.dart';
import 'screens/exercise_listening_screen.dart';
import 'screens/letter_introduction_screen.dart';
import 'screens/exercise_recording_screen.dart';
import 'screens/placement_test_screen.dart';
import 'screens/placement_result_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/exercise_listening_result_screen.dart';
import 'screens/exercise_recording_result_screen.dart';
import 'screens/exercise_mcq_result_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter engine is initialized before runApp
  Firebase.initializeApp();
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
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },

      // ─── Global App Theme ────────────────────────────────────────
      // These colors apply across the whole app unless overridden
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF511281), // Your purple brand color
        ),
        useMaterial3: true,

        // Default font for Arabic text rendering
        fontFamily:
            'Tajawal', // See pubspec.yaml setup below if you want this font
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
        '/parent/dashboard': (context) => const ParentDashboardScreen(),
        '/parent/settings': (context) => const ParentSettingsScreen(),
        '/child/selection': (context) => const ChildSelectionScreen(),
        '/child/home': (context) => const ChildHomeScreen(),
        '/parent/create-child': (context) => const CreateChildProfileScreen(),
        '/parent/child-profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return ChildProfileManagementScreen(childId: args?['childId']);
        },
        '/parent/child-profile/edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return EditChildProfileScreen(childId: args?['childId']);
        },
        '/child/exercises': (context) => const ExercisesScreen(),
        '/child/letter-levels': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return LetterLevelsScreen(letter: args?['letter'] ?? 'ض');
        },
        '/child/exercise/mcq': (context) => ExerciseMCQScreen(
          letter:
              (ModalRoute.of(context)!.settings.arguments as Map?)?['letter'] ??
              'ض',
        ),
        '/child/exercise/mcq-result': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ExerciseMCQResultScreen(
            score: args['score'],
            total: args['total'],
            answers: List<Map<String, dynamic>>.from(args['answers']),
            questions: List<Map<String, dynamic>>.from(args['questions']),
            letter: args['letter'] ?? 'ض',
          );
        },
        '/child/exercise/listening': (context) => ExerciseListeningScreen(
          letter:
              (ModalRoute.of(context)!.settings.arguments as Map?)?['letter'] ??
              'ض',
        ),
        '/child/letter-introduction': (context) => LetterIntroductionScreen(
          letter:
              (ModalRoute.of(context)!.settings.arguments as Map?)?['letter'] ??
              'ض',
        ),
        '/child/exercise/recording': (context) => ExerciseRecordingScreen(
          letter:
              (ModalRoute.of(context)!.settings.arguments as Map?)?['letter'] ??
              'ض',
        ),
        '/child/placement-test': (context) => const PlacementTestScreen(),
        '/child/placement-result': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final rawScores = args?['letterScores'] as List?;
          return PlacementResultScreen(
            score: args?['score'] ?? 72,
            weakLetters: List<String>.from(
              args?['weakLetters'] ?? ['ق', 'ض', 'خ'],
            ),
            strongLetters: List<String>.from(
              args?['strongLetters'] ?? ['س', 'ص', 'غ'],
            ),
            letterScores: rawScores != null && rawScores.isNotEmpty
                ? rawScores
                      .map(
                        (e) =>
                            LetterScore(letter: e['letter'], score: e['score']),
                      )
                      .toList()
                : const [
                    // ← use defaults when PlacementTest doesn't send scores yet
                    LetterScore(letter: 'ق', score: 35),
                    LetterScore(letter: 'ض', score: 42),
                    LetterScore(letter: 'خ', score: 48),
                    LetterScore(letter: 'س', score: 81),
                    LetterScore(letter: 'ص', score: 76),
                    LetterScore(letter: 'غ', score: 79),
                  ],
          );
        },
        '/child/leaderboard': (context) => const LeaderboardScreen(),
        '/child/exercise-listening-result': (context) =>
            const ExerciseListeningResultScreen(),

        '/child/exercise/recording-result': (context) =>
            const ExerciseRecordingResultScreen(),
      }, // ← closes routes: { }
    ); // ← closes MaterialApp(
  } // ← closes build()
} // ← closes MyApp

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
