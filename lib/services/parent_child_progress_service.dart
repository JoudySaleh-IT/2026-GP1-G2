import 'package:cloud_firestore/cloud_firestore.dart';

enum ParentLetterState { mastered, inProgress, notStarted }

class ParentLetterProgress {
  final String letter;

  final int placementScore;

  /// beginner / intermediate / advanced
  final String startingLevel;

  /// beginner / intermediate / advanced
  final String currentLevel;

  final bool listeningPassed;
  final bool pronunciationPassed;

  /// Latest saved result for the CURRENT difficulty.
  final int? listeningScore;
  final int? pronunciationScore;
  final int? pronunciationCorrectCount;

  final ParentLetterState state;

  final bool masteredByPlacement;

  final int completedRequiredLevels;
  final int totalRequiredLevels;

  const ParentLetterProgress({
    required this.letter,
    required this.placementScore,
    required this.startingLevel,
    required this.currentLevel,
    required this.listeningPassed,
    required this.pronunciationPassed,
    required this.listeningScore,
    required this.pronunciationScore,
    required this.pronunciationCorrectCount,
    required this.state,
    required this.masteredByPlacement,
    required this.completedRequiredLevels,
    required this.totalRequiredLevels,
  });

  bool get isMastered => state == ParentLetterState.mastered;
}

class ParentChildProgressSummary {
  final bool placementDone;

  final int streak;
  final int lifetimePoints;

  final int masteredLetters;

  final List<ParentLetterProgress> letters;

  const ParentChildProgressSummary({
    required this.placementDone,
    required this.streak,
    required this.lifetimePoints,
    required this.masteredLetters,
    required this.letters,
  });
}

class ParentChildProgressService {
  final FirebaseFirestore _db;

  ParentChildProgressService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  static const List<String> targetLetters = ['ق', 'خ', 'غ', 'ص', 'س', 'ض'];

  ParentChildProgressSummary buildSummary(Map<String, dynamic> childData) {
    final bool placementDone = childData['placementDone'] == true;

    final int streak = (childData['streak'] as num?)?.toInt() ?? 0;

    // Lifetime achievement points.
    // Do NOT use availablePoints here.
    final int lifetimePoints = (childData['points'] as num?)?.toInt() ?? 0;

    final Map<String, dynamic> letterScores = {};

    final dynamic rawScores = childData['letterScores'];

    if (rawScores is Map) {
      rawScores.forEach((key, value) {
        letterScores[key.toString()] = value;
      });
    }

    final Map<String, dynamic> exerciseProgress = {};

    final dynamic rawProgress = childData['exerciseProgress'];

    if (rawProgress is Map) {
      rawProgress.forEach((key, value) {
        exerciseProgress[key.toString()] = value;
      });
    }

    final letters = targetLetters
        .map(
          (letter) => _buildLetterProgress(
            letter: letter,
            placementDone: placementDone,
            letterScores: letterScores,
            exerciseProgress: exerciseProgress,
          ),
        )
        .toList();

    final int masteredLetters = letters
        .where((letter) => letter.isMastered)
        .length;

    return ParentChildProgressSummary(
      placementDone: placementDone,
      streak: streak,
      lifetimePoints: lifetimePoints,
      masteredLetters: masteredLetters,
      letters: letters,
    );
  }

  ParentLetterProgress _buildLetterProgress({
    required String letter,
    required bool placementDone,
    required Map<String, dynamic> letterScores,
    required Map<String, dynamic> exerciseProgress,
  }) {
    final dynamic rawScore = letterScores[letter];

    final int placementScore = rawScore is num ? rawScore.toInt() : 0;

    // ============================================================
    // Placement has not been completed yet
    // ============================================================
    if (!placementDone) {
      return ParentLetterProgress(
        letter: letter,
        placementScore: placementScore,
        startingLevel: 'beginner',
        currentLevel: 'beginner',
        listeningPassed: false,
        pronunciationPassed: false,
        listeningScore: null,
        pronunciationScore: null,
        pronunciationCorrectCount: null,
        state: ParentLetterState.notStarted,
        masteredByPlacement: false,
        completedRequiredLevels: 0,
        totalRequiredLevels: 3,
      );
    }

    // ============================================================
    // Mastered directly from Placement Test
    // ============================================================
    if (placementScore >= 80) {
      return ParentLetterProgress(
        letter: letter,
        placementScore: placementScore,
        startingLevel: 'advanced',
        currentLevel: 'advanced',
        listeningPassed: true,
        pronunciationPassed: true,
        listeningScore: null,
        pronunciationScore: null,
        pronunciationCorrectCount: null,
        state: ParentLetterState.mastered,
        masteredByPlacement: true,
        completedRequiredLevels: 0,
        totalRequiredLevels: 0,
      );
    }

    // ============================================================
    // Determine the child's journey for this letter
    // ============================================================
    final bool startsFromBeginner = placementScore < 50;

    final String startingLevel = startsFromBeginner
        ? 'beginner'
        : 'intermediate';

    final List<String> requiredLevels = startsFromBeginner
        ? const ['beginner', 'intermediate', 'advanced']
        : const ['intermediate', 'advanced'];

    final dynamic rawLetterProgress = exerciseProgress[letter];

    final Map<String, dynamic> letterProgress = {};

    if (rawLetterProgress is Map) {
      rawLetterProgress.forEach((key, value) {
        letterProgress[key.toString()] = value;
      });
    }

    bool hasStarted = false;
    int completedLevels = 0;

    // ============================================================
    // Find first required difficulty that is not fully completed
    // ============================================================
    for (final level in requiredLevels) {
      final dynamic rawLevel = letterProgress[level];

      // Difficulty hasn't been touched yet.
      if (rawLevel is! Map) {
        return ParentLetterProgress(
          letter: letter,
          placementScore: placementScore,
          startingLevel: startingLevel,
          currentLevel: level,
          listeningPassed: false,
          pronunciationPassed: false,
          listeningScore: null,
          pronunciationScore: null,
          pronunciationCorrectCount: null,
          state: hasStarted
              ? ParentLetterState.inProgress
              : ParentLetterState.notStarted,
          masteredByPlacement: false,
          completedRequiredLevels: completedLevels,
          totalRequiredLevels: requiredLevels.length,
        );
      }

      hasStarted = true;

      final Map<String, dynamic> levelData = Map<String, dynamic>.from(
        rawLevel,
      );

      final bool listeningPassed = levelData['listeningPassed'] == true;

      final bool pronunciationPassed = levelData['pronunciationPassed'] == true;

      final int? listeningScore = _asInt(levelData['listeningScore']);

      final int? pronunciationScore = _asInt(levelData['pronunciationScore']);

      final int? pronunciationCorrectCount = _asInt(
        levelData['pronunciationCorrectCount'],
      );

      // This difficulty is still active.
      if (!listeningPassed || !pronunciationPassed) {
        return ParentLetterProgress(
          letter: letter,
          placementScore: placementScore,
          startingLevel: startingLevel,
          currentLevel: level,
          listeningPassed: listeningPassed,
          pronunciationPassed: pronunciationPassed,
          listeningScore: listeningScore,
          pronunciationScore: pronunciationScore,
          pronunciationCorrectCount: pronunciationCorrectCount,
          state: ParentLetterState.inProgress,
          masteredByPlacement: false,
          completedRequiredLevels: completedLevels,
          totalRequiredLevels: requiredLevels.length,
        );
      }

      // Listening + Speaking completed.
      completedLevels++;
    }

    // ============================================================
    // All required difficulties completed
    // ============================================================
    final dynamic rawAdvanced = letterProgress['advanced'];

    final Map<String, dynamic> advancedData = rawAdvanced is Map
        ? Map<String, dynamic>.from(rawAdvanced)
        : {};

    return ParentLetterProgress(
      letter: letter,
      placementScore: placementScore,
      startingLevel: startingLevel,
      currentLevel: 'advanced',
      listeningPassed: true,
      pronunciationPassed: true,
      listeningScore: _asInt(advancedData['listeningScore']),
      pronunciationScore: _asInt(advancedData['pronunciationScore']),
      pronunciationCorrectCount: _asInt(
        advancedData['pronunciationCorrectCount'],
      ),
      state: ParentLetterState.mastered,
      masteredByPlacement: false,
      completedRequiredLevels: requiredLevels.length,
      totalRequiredLevels: requiredLevels.length,
    );
  }

  int? _asInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return null;
  }

  // ==============================================================
  // Activity during the last 7 KSA calendar days
  // ==============================================================
  Stream<QuerySnapshot<Map<String, dynamic>>> watchLastSevenDays(
    String childId,
  ) {
    final DateTime nowKsa = DateTime.now().toUtc().add(
      const Duration(hours: 3),
    );

    final DateTime todayMidnightKsa = DateTime.utc(
      nowKsa.year,
      nowKsa.month,
      nowKsa.day,
    );

    final DateTime startUtc = todayMidnightKsa
        .subtract(const Duration(hours: 3))
        .subtract(const Duration(days: 6));

    return _db
        .collection('children')
        .doc(childId)
        .collection('motivation_events')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startUtc),
        )
        .orderBy('createdAt')
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentActivity(
    String childId, {
    int limit = 5,
  }) {
    return _db
        .collection('children')
        .doc(childId)
        .collection('motivation_events')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
