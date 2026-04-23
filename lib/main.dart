import 'package:faseh/wrapper.dart';
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
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/child_enter_code_screen.dart';
import 'services/childSession.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class NoStretchScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // This removes the glowing/stretching completely
    return child;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'فصيح',
      scrollBehavior: NoStretchScrollBehavior(),
      initialRoute: '/',
      //home: Wrapper(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF511281)),
        useMaterial3: true,
        fontFamily: 'Tajawal',
      ),
      routes: {
        // ─── مسارات ولي الأمر (Parent Routes) ───
        '/parent/register': (context) => const ParentRegisterScreen(),
        '/parent/login': (context) => const ParentLoginScreen(),
        '/parent/forgot-password': (context) => const ForgotPasswordScreen(),
        '/parent/dashboard': (context) => const ParentDashboardScreen(),
        '/parent/settings': (context) => const ParentSettingsScreen(),
        '/parent/select-child': (context) => const ChildSelectionScreen(),
        '/parent/create-child': (context) => const CreateChildProfileScreen(),

        '/': (context) => const SplashScreen(),
        // Ensure this matches the name in your SplashScreen button
        '/child/enter-code': (context) => const ChildEnterCodeScreen(),

        '/parent/child-profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return ChildProfileManagementScreen(childId: args?['childId']);
        },

        '/parent/child-profile/edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return EditChildProfileScreen(childId: args?['childId']);
        },

        // ─── مسارات الطفل (Child Routes) ───
        '/child/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          // Check arguments first, then check our global ChildSession as a backup
          final String? id = args is String
              ? args
              : (args as Map?)?['childId'] ?? ChildSession.currentChildId;

          if (id == null || id.isEmpty) {
            // If we still have no ID, send them back to the splash to login/pair
            return const SplashScreen();
          }
          return ChildHomeScreen(childId: id);
        },

        '/child/exercises': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final String? id = args is String ? args : (args as Map?)?['childId'];
          return ExercisesScreen(childId: id ?? '');
        },

        '/child/letter-levels': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return LetterLevelsScreen(
            letter: args?['letter'] ?? 'ض',
            childId: args?['childId'] ?? '',
          );
        },

        '/child/letter-introduction': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return LetterIntroductionScreen(
            letter: args?['letter'] ?? 'ض',
            childId: args?['childId'] ?? '',
          );
        },

        // ── التمارين (Exercises) ──
        '/child/exercise/mcq': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return ExerciseMCQScreen(
            letter: args?['letter'] ?? 'ض',
            childId: args?['childId'] ?? '',
          );
        },

        '/child/exercise/mcq-result': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map;
          return ExerciseMCQResultScreen(
            score: args['score'],
            total: args['total'],
            answers: List<Map<String, dynamic>>.from(args['answers']),
            questions: List<Map<String, dynamic>>.from(args['questions']),
            letter: args['letter'] ?? 'ض',
            childId: args['childId'] ?? '',
          );
        },

        '/child/exercise/listening': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return ExerciseListeningScreen(
            letter: args?['letter'] ?? 'ض',
            childId: args?['childId'] ?? '',
          );
        },

        '/child/exercise/recording': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return ExerciseRecordingScreen(
            letter: args?['letter'] ?? 'ض',
            childId: args?['childId'] ?? '',
          );
        },

        // ── اختبار تحديد المستوى ──
        '/child/placement-test': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final String? id = args is String ? args : (args as Map?)?['childId'];
          return PlacementTestScreen(childId: id ?? '');
        },

        '/child/placement-result': (context) {
          // 1. نستقبل البيانات القادمة من شاشة الاختبار
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;

          // 2. نحول قائمة الحروف إلى النموذج الذي تفهمه شاشة النتائج (LetterScore)
          List<LetterScore> convertedScores = (args['letterScores'] as List)
              .map((item) {
                return LetterScore(
                  letter: item['letter'],
                  score: item['score'],
                );
              })
              .toList();

          // 3. نفتح الشاشة ونمرر لها البيانات النظيفة
          return PlacementResultScreen(
            childId: args['childId'],
            score: args['score'],
            letterScores: convertedScores,
          );
        },

        '/child/leaderboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final String? id = args is String ? args : (args as Map?)?['childId'];
          return LeaderboardScreen(childId: id ?? '');
        },

        '/child/exercise-listening-result': (context) =>
            const ExerciseListeningResultScreen(),
        '/child/exercise/recording-result': (context) =>
            const ExerciseRecordingResultScreen(),
      },
    );
  }
}
