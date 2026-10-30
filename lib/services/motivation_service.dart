import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'leaderboard_service.dart';

class MotivationAwardResult {
  final bool awarded;
  final int pointsAwarded;
  final int totalPoints;
  final int streak;

  const MotivationAwardResult({
    required this.awarded,
    required this.pointsAwarded,
    required this.totalPoints,
    required this.streak,
  });
}

class MotivationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LeaderboardService _leaderboardService = LeaderboardService();

  // ---------------------------------------------------------------------------
  // Create a unique ID for one exercise attempt.
  // The same ID must be reused until that attempt finishes.
  // ---------------------------------------------------------------------------

  String createAttemptId(String childId) {
    return _db
        .collection('children')
        .doc(childId)
        .collection('motivation_events')
        .doc()
        .id;
  }

  // ---------------------------------------------------------------------------
  // Saudi calendar day
  //
  // Streaks depend on calendar days, not on "24 hours since last practice".
  // Saudi Arabia is UTC+3.
  // ---------------------------------------------------------------------------

  DateTime _saudiToday() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));

    return DateTime.utc(now.year, now.month, now.day);
  }

  String _toDayKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');

    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  DateTime? _parseDayKey(dynamic value) {
    if (value == null) {
      return null;
    }

    final parts = value.toString().split('-');

    if (parts.length != 3) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime.utc(year, month, day);
  }

  // ---------------------------------------------------------------------------
  // Calculate new streak
  // ---------------------------------------------------------------------------

  int _calculateStreak({
    required int currentStreak,
    required dynamic lastPracticeDay,
    required DateTime today,
  }) {
    final lastDay = _parseDayKey(lastPracticeDay);

    // First recorded practice.
    if (lastDay == null) {
      return 1;
    }

    final yesterday = today.subtract(const Duration(days: 1));

    // Already practiced today.
    if (lastDay == today) {
      return currentStreak > 0 ? currentStreak : 1;
    }

    // Practiced yesterday → consecutive day.
    if (lastDay == yesterday) {
      return currentStreak > 0 ? currentStreak + 1 : 1;
    }

    // Missed one or more days.
    return 1;
  }

  // ---------------------------------------------------------------------------
  // SOLO LISTENING
  //
  // Rule:
  // points = correct answers × 50
  //
  // A fully completed attempt counts toward the streak even when the child
  // did not reach the Listening passing threshold.
  // ---------------------------------------------------------------------------

  Future<MotivationAwardResult> recordListeningCompletion({
    required String childId,
    required String attemptId,
    required String letter,
    required String level,
    required int correctCount,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    if (childId.isEmpty || attemptId.isEmpty) {
      throw Exception('INVALID_ARGUMENT');
    }

    if (correctCount < 0 || correctCount > 8) {
      throw Exception('INVALID_CORRECT_COUNT');
    }

    const int pointsPerCorrectAnswer = 50;

    final int pointsAwarded = correctCount * pointsPerCorrectAnswer;

    final childRef = _db.collection('children').doc(childId);

    final eventRef = childRef.collection('motivation_events').doc(attemptId);

    final publicProfileRef = _db
        .collection('child_public_profiles')
        .doc(childId);

    final leaderboardRef = _db.collection('leaderboard_profiles').doc(childId);

    final DateTime today = _saudiToday();

    final String todayKey = _toDayKey(today);

    return _db.runTransaction<MotivationAwardResult>((transaction) async {
      // ---------------------------------------------------------
      // Read everything before making writes.
      // ---------------------------------------------------------

      final eventSnapshot = await transaction.get(eventRef);

      final childSnapshot = await transaction.get(childRef);

      final publicProfileSnapshot = await transaction.get(publicProfileRef);

      if (!publicProfileSnapshot.exists ||
          publicProfileSnapshot.data() == null) {
        throw Exception('PUBLIC_PROFILE_NOT_FOUND');
      }

      final publicData = publicProfileSnapshot.data()!;

      if (!childSnapshot.exists || childSnapshot.data() == null) {
        throw Exception('CHILD_NOT_FOUND');
      }

      final data = childSnapshot.data()!;

      final int currentPoints = (data['points'] as num?)?.toInt() ?? 0;

      final int currentStreak = (data['streak'] as num?)?.toInt() ?? 0;

      // ---------------------------------------------------------
      // Duplicate protection
      //
      // If this exact attempt already awarded points,
      // return without adding anything again.
      // ---------------------------------------------------------

      if (eventSnapshot.exists) {
        final eventData = eventSnapshot.data();

        return MotivationAwardResult(
          awarded: false,
          pointsAwarded: (eventData?['pointsAwarded'] as num?)?.toInt() ?? 0,
          totalPoints: currentPoints,
          streak: currentStreak,
        );
      }

      // ---------------------------------------------------------
      // Calculate updated motivation state.
      // ---------------------------------------------------------

      final int newPoints = currentPoints + pointsAwarded;

      final int newStreak = _calculateStreak(
        currentStreak: currentStreak,
        lastPracticeDay: data['lastPracticeDay'],
        today: today,
      );

      final String ageGroup = _leaderboardService.resolveAgeGroup(data);

      final String publicName = (publicData['name'] ?? '').toString().trim();

      final String publicAvatar = (publicData['avatar'] ?? '🌟').toString();

      if (publicName.isEmpty) {
        throw Exception('PUBLIC_NAME_NOT_FOUND');
      }

      // ---------------------------------------------------------
      // Update child motivation values and leaderboard.
      // ---------------------------------------------------------

      transaction.update(childRef, {
        'points': newPoints,
        'streak': newStreak,
        'ageGroup': ageGroup,
        'lastPracticeDay': todayKey,
        'lastPracticeAt': FieldValue.serverTimestamp(),
      });

      transaction.set(leaderboardRef, {
        'name': publicName,
        'avatar': publicAvatar,
        'points': newPoints,
        'streak': newStreak,
        'ageGroup': ageGroup,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ---------------------------------------------------------
      // Record this attempt permanently.
      // This prevents duplicate point awards.
      // ---------------------------------------------------------

      transaction.set(eventRef, {
        'childId': childId,
        'source': 'listening',
        'letter': letter,
        'level': level,
        'correctCount': correctCount,
        'pointsAwarded': pointsAwarded,
        'streakAfter': newStreak,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return MotivationAwardResult(
        awarded: true,
        pointsAwarded: pointsAwarded,
        totalPoints: newPoints,
        streak: newStreak,
      );
    });
  }

  Future<MotivationAwardResult> recordSpeakingCompletion({
    required String childId,
    required String attemptId,
    required String letter,
    required String level,
    required int averageScore,
    required int correctCount,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    if (childId.isEmpty || attemptId.isEmpty) {
      throw Exception('INVALID_ARGUMENT');
    }

    if (averageScore < 0 || averageScore > 100) {
      throw Exception('INVALID_AVERAGE_SCORE');
    }

    if (correctCount < 0 || correctCount > 8) {
      throw Exception('INVALID_CORRECT_COUNT');
    }

    const int pointsPerScore = 10;

    final int pointsAwarded = averageScore * pointsPerScore;

    final childRef = _db.collection('children').doc(childId);

    final eventRef = childRef.collection('motivation_events').doc(attemptId);

    final publicProfileRef = _db
        .collection('child_public_profiles')
        .doc(childId);

    final leaderboardRef = _db.collection('leaderboard_profiles').doc(childId);

    final DateTime today = _saudiToday();

    final String todayKey = _toDayKey(today);

    return _db.runTransaction<MotivationAwardResult>((transaction) async {
      // ---------------------------------------------------------
      // Read child + event first
      // ---------------------------------------------------------

      final eventSnapshot = await transaction.get(eventRef);

      final childSnapshot = await transaction.get(childRef);

      if (!childSnapshot.exists || childSnapshot.data() == null) {
        throw Exception('CHILD_NOT_FOUND');
      }

      final data = childSnapshot.data()!;

      final int currentPoints = (data['points'] as num?)?.toInt() ?? 0;

      final int currentStreak = (data['streak'] as num?)?.toInt() ?? 0;

      // ---------------------------------------------------------
      // Duplicate protection
      // ---------------------------------------------------------

      if (eventSnapshot.exists) {
        final eventData = eventSnapshot.data();

        return MotivationAwardResult(
          awarded: false,
          pointsAwarded: (eventData?['pointsAwarded'] as num?)?.toInt() ?? 0,
          totalPoints: currentPoints,
          streak: currentStreak,
        );
      }

      // ---------------------------------------------------------
      // Read safe public profile
      // ---------------------------------------------------------

      final publicProfileSnapshot = await transaction.get(publicProfileRef);

      if (!publicProfileSnapshot.exists ||
          publicProfileSnapshot.data() == null) {
        throw Exception('PUBLIC_PROFILE_NOT_FOUND');
      }

      final publicData = publicProfileSnapshot.data()!;

      // ---------------------------------------------------------
      // Calculate new motivation values
      // ---------------------------------------------------------

      final int newPoints = currentPoints + pointsAwarded;

      final int newStreak = _calculateStreak(
        currentStreak: currentStreak,
        lastPracticeDay: data['lastPracticeDay'],
        today: today,
      );

      final String ageGroup = _leaderboardService.resolveAgeGroup(data);

      final String publicName = (publicData['name'] ?? '').toString().trim();

      final String publicAvatar = (publicData['avatar'] ?? '🌟').toString();

      if (publicName.isEmpty) {
        throw Exception('PUBLIC_NAME_NOT_FOUND');
      }

      // ---------------------------------------------------------
      // Update private child motivation state
      // ---------------------------------------------------------

      transaction.update(childRef, {
        'points': newPoints,
        'streak': newStreak,
        'ageGroup': ageGroup,
        'lastPracticeDay': todayKey,
        'lastPracticeAt': FieldValue.serverTimestamp(),
      });

      // ---------------------------------------------------------
      // Keep leaderboard in sync
      // ---------------------------------------------------------

      transaction.set(leaderboardRef, {
        'name': publicName,
        'avatar': publicAvatar,
        'points': newPoints,
        'streak': newStreak,
        'ageGroup': ageGroup,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // ---------------------------------------------------------
      // Permanent motivation event
      // ---------------------------------------------------------

      transaction.set(eventRef, {
        'childId': childId,
        'source': 'speaking',
        'letter': letter,
        'level': level,
        'averageScore': averageScore,
        'correctCount': correctCount,
        'pointsAwarded': pointsAwarded,
        'streakAfter': newStreak,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return MotivationAwardResult(
        awarded: true,
        pointsAwarded: pointsAwarded,
        totalPoints: newPoints,
        streak: newStreak,
      );
    });
  }
}
