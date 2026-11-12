import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'leaderboard_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
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

// Send streak achievement notifications after a successful practice.
Future<void> _notifyStreakAchievement({
  required String childId,
  required MotivationAwardResult result,
}) async {
  if (!result.awarded ||
      result.streak < 3 ||
      result.streak % 3 != 0) {
    return;
  }

  try {
    final callable = FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('notifyFaseehStreak');

    await callable.call({
      'childId': childId,
    });
  } catch (e) {
    // Notification failure must never affect completed practice.
    debugPrint('Streak notification failed: $e');
  }
}

Future<void> testStreakAchievement(String childId) async {
  try {
    final result = await FirebaseFunctions.instanceFor(
      region: 'us-central1',
    ).httpsCallable('notifyFaseehStreak').call({
      'childId': childId,
    });

    debugPrint('STREAK TEST RESULT: ${result.data}');
  } catch (e) {
    debugPrint('STREAK TEST ERROR: $e');
  }
}

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

final result = await _db.runTransaction<MotivationAwardResult>(
  (transaction) async {      // ---------------------------------------------------------
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

    await _notifyStreakAchievement(
      childId: childId,
      result: result,
    );

    return result;
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

final result = await _db.runTransaction<MotivationAwardResult>(
  (transaction) async {      // ---------------------------------------------------------
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

    await _notifyStreakAchievement(
      childId: childId,
      result: result,
    );

    return result;
  }

  Future<MotivationAwardResult> recordPracticeTogetherCompletion({
    required String childId,
    required String sessionId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    if (childId.isEmpty || sessionId.isEmpty) {
      throw Exception('INVALID_ARGUMENT');
    }

    final childRef = _db.collection('children').doc(childId);

    // Same session can never reward the same child twice.
    final eventRef = childRef
        .collection('motivation_events')
        .doc('practice_$sessionId');

    final sessionRef = _db.collection('practice_sessions').doc(sessionId);

    final publicProfileRef = _db
        .collection('child_public_profiles')
        .doc(childId);

    final leaderboardRef = _db.collection('leaderboard_profiles').doc(childId);

    final DateTime today = _saudiToday();
    final String todayKey = _toDayKey(today);

final result = await _db.runTransaction<MotivationAwardResult>(
  (transaction) async {      // -------------------------------------------------------
      // ALL READS FIRST
      // -------------------------------------------------------

      final eventSnapshot = await transaction.get(eventRef);

      final childSnapshot = await transaction.get(childRef);

      final publicProfileSnapshot = await transaction.get(publicProfileRef);

      final sessionSnapshot = await transaction.get(sessionRef);

      if (!childSnapshot.exists || childSnapshot.data() == null) {
        throw Exception('CHILD_NOT_FOUND');
      }

      final childData = childSnapshot.data()!;

      final int currentPoints = (childData['points'] as num?)?.toInt() ?? 0;

      final int currentStreak = (childData['streak'] as num?)?.toInt() ?? 0;

      // -------------------------------------------------------
      // DUPLICATE PROTECTION
      // -------------------------------------------------------

      if (eventSnapshot.exists) {
        final eventData = eventSnapshot.data();

        return MotivationAwardResult(
          awarded: false,
          pointsAwarded: (eventData?['pointsAwarded'] as num?)?.toInt() ?? 0,
          totalPoints: currentPoints,
          streak: currentStreak,
        );
      }

      if (!sessionSnapshot.exists || sessionSnapshot.data() == null) {
        throw Exception('SESSION_NOT_FOUND');
      }

      if (!publicProfileSnapshot.exists ||
          publicProfileSnapshot.data() == null) {
        throw Exception('PUBLIC_PROFILE_NOT_FOUND');
      }

      final sessionData = sessionSnapshot.data()!;

      final publicData = publicProfileSnapshot.data()!;

      if (sessionData['status'] != 'completed') {
        throw Exception('SESSION_NOT_COMPLETED');
      }

      final String senderId = sessionData['senderId']?.toString() ?? '';

      final String receiverId = sessionData['receiverId']?.toString() ?? '';

      if (childId != senderId && childId != receiverId) {
        throw Exception('NOT_SESSION_MEMBER');
      }

      final bool isSender = childId == senderId;

      final String exerciseType = sessionData['exerciseType']?.toString() ?? '';

      if (exerciseType != 'listening' && exerciseType != 'speaking') {
        throw Exception('INVALID_EXERCISE_TYPE');
      }

      final int correctCount =
          (sessionData[isSender ? 'senderCorrectCount' : 'receiverCorrectCount']
                  as num?)
              ?.toInt() ??
          0;

      if (correctCount < 0 || correctCount > 8) {
        throw Exception('INVALID_CORRECT_COUNT');
      }

      final String letter =
          sessionData[isSender ? 'senderLetter' : 'receiverLetter']
              ?.toString() ??
          '';

      final String level =
          sessionData[isSender ? 'senderLevel' : 'receiverLevel']?.toString() ??
          '';

      final String result = sessionData['result']?.toString() ?? '';

      final String winnerId = sessionData['winnerId']?.toString() ?? '';

      final bool isTie = result == 'tie';

      final bool won = !isTie && winnerId == childId;

      final String outcome;

      if (isTie) {
        outcome = 'tie';
      } else if (won) {
        outcome = 'winner';
      } else {
        outcome = 'loser';
      }

      // -------------------------------------------------------
      // COMPETITION POINT RULES
      // -------------------------------------------------------

      final int potentialPoints = exerciseType == 'speaking'
          ? correctCount * 125
          : correctCount * 50;

      // Winner and exact tie receive points.
      // Loser receives 0.
      final int pointsAwarded = (won || isTie) ? potentialPoints : 0;

      final int newPoints = currentPoints + pointsAwarded;

      // ALL completed competitors get streak credit,
      // including the loser.
      final int newStreak = _calculateStreak(
        currentStreak: currentStreak,
        lastPracticeDay: childData['lastPracticeDay'],
        today: today,
      );

      final String ageGroup = _leaderboardService.resolveAgeGroup(childData);

      final String publicName = (publicData['name'] ?? '').toString().trim();

      final String publicAvatar = (publicData['avatar'] ?? '🌟').toString();

      if (publicName.isEmpty) {
        throw Exception('PUBLIC_NAME_NOT_FOUND');
      }

      // -------------------------------------------------------
      // WRITES
      // -------------------------------------------------------

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

      transaction.set(eventRef, {
        'childId': childId,
        'source': 'practice_together',
        'sessionId': sessionId,
        'exerciseType': exerciseType,
        'outcome': outcome,
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

    await _notifyStreakAchievement(
      childId: childId,
      result: result,
    );

    return result;
  }
}
