import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pronunciation_exercise_data.dart';

class PronunciationRepository {
  static Future<List<PronunciationExerciseData>> getExercises({
    required String letter,
    required String level,
  }) async {
    // قراءة ملف JSON
    final jsonString = await rootBundle.loadString(
      'assets/data/pronunciation_exercises.json',
    );

    // تحويل النص إلى JSON
    final Map<String, dynamic> jsonData = jsonDecode(jsonString);

    // أخذ جميع التمارين
    final List<dynamic> allExercises = jsonData['exercises'] ?? [];

    // اختيار التمارين الخاصة بالحرف والمستوى فقط
    final exercises = allExercises
        .where(
          (exercise) =>
              exercise['letter'] == letter && exercise['level'] == level,
        )
        .map(
          (exercise) => PronunciationExerciseData.fromJson(
            exercise as Map<String, dynamic>,
          ),
        )
        .toList();

    // ترتيبها من 1 إلى 8
    exercises.sort((a, b) => a.order.compareTo(b.order));

    return exercises;
  }
}
