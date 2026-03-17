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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.signOut();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'فصيح',
      initialRoute: '/',
      home: Wrapper(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF511281),
        ),
        useMaterial3: true,
        fontFamily: 'Tajawal',
      ),
      routes: {
        '/parent/register': (context) => const ParentRegisterScreen(),
        '/parent/login': (context) => const ParentLoginScreen(),
        '/parent/forgot-password': (context) => const ForgotPasswordScreen(),
        '/parent/dashboard': (context) => const ParentDashboardScreen(),
        '/parent/settings': (context) => const ParentSettingsScreen(),
        '/child/selection': (context) => const ChildSelectionScreen(),
        '/child/home': (context) {
  final args = ModalRoute.of(context)!.settings.arguments;
  if (args == null || args is! String || args.isEmpty) {
    return const Scaffold(
      body: Center(child: Text("خطأ: لم يتم العثور على هوية الطفل")),
    );
  }
  return ChildHomeScreen(childId: args);
},
        '/parent/create-child': (context) => const CreateChildProfileScreen(),
        '/parent/child-profile': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return ChildProfileManagementScreen(childId: args?['childId']);
        },
        '/parent/child-profile/edit': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return EditChildProfileScreen(childId: args?['childId']);
        },
        '/child/exercises': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args == null || args is! String) {
            return const Scaffold(
              body: Center(child: Text("خطأ: لم يتم العثور على هوية الطفل")),
            );
          }
          return ExercisesScreen(childId: args);
        },
        '/child/letter-levels': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args is Map) {
            return LetterLevelsScreen(
              letter: args['letter'] ?? 'ض',
              childId: args['childId'] ?? '',
            );
          }
          if (args is String) {
            return LetterLevelsScreen(
              letter: 'ض',
              childId: args,
            );
          }
          return const Scaffold(
            body: Center(child: Text("خطأ: لم يتم العثور على هوية الطفل")),
          );
        },
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
        '/child/letter-introduction': (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map?;
  return LetterIntroductionScreen(
    letter: args?['letter'] ?? 'ض',
    childId: args?['childId'] ?? '', // ✅
  );
},
        '/child/exercise/recording': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          return ExerciseRecordingScreen(
            letter: args?['letter'] ?? 'ض',
            childId: args?['childId'] ?? '',
          );
        },
        '/child/placement-test': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args == null || args is! String) {
            return const Scaffold(
              body: Center(child: Text("خطأ: لم يتم العثور على هوية الطفل")),
            );
          }
          return PlacementTestScreen(childId: args);
        },
        '/child/placement-result': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map?;
          final rawScores = args?['letterScores'] as List?;
          return PlacementResultScreen(
            childId: args?['childId'] ?? '',
            score: args?['score'] ?? 72,
            weakLetters: List<String>.from(
              args?['weakLetters'] ?? ['ق', 'ض', 'خ'],
            ),
            strongLetters: List<String>.from(
              args?['strongLetters'] ?? ['س', 'ص', 'غ'],
            ),
            letterScores: rawScores != null && rawScores.isNotEmpty
                ? rawScores
                    .map((e) => LetterScore(letter: e['letter'], score: e['score']))
                    .toList()
                : const [
                    LetterScore(letter: 'ق', score: 35),
                    LetterScore(letter: 'ض', score: 42),
                    LetterScore(letter: 'خ', score: 48),
                    LetterScore(letter: 'س', score: 81),
                    LetterScore(letter: 'ص', score: 76),
                    LetterScore(letter: 'غ', score: 79),
                  ],
          );
        },
        '/child/leaderboard': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          if (args == null || args is! String) {
            return const Scaffold(
              body: Center(child: Text("خطأ: لم يتم العثور على هوية الطفل")),
            );
          }
          return LeaderboardScreen(childId: args);
        },
        '/child/exercise-listening-result': (context) =>
            const ExerciseListeningResultScreen(),
        '/child/exercise/recording-result': (context) =>
            const ExerciseRecordingResultScreen(),
      },
    );
  }
}