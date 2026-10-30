import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LeaderboardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------------------------------------------------------------------
  // DOB helpers
  // ---------------------------------------------------------------------------

  DateTime? _parseDob(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  int? _calculateAge(dynamic rawDob) {
    final dob = _parseDob(rawDob);

    if (dob == null) {
      return null;
    }

    // Saudi local calendar date.
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));

    int age = now.year - dob.year;

    final bool birthdayPassed =
        now.month > dob.month || (now.month == dob.month && now.day >= dob.day);

    if (!birthdayPassed) {
      age--;
    }

    return age;
  }

  String resolveAgeGroup(Map<String, dynamic> childData) {
    // Prefer DOB because stored numeric age can become
    // outdated after the child's birthday.
    int? age = _calculateAge(childData['dob']);

    // Legacy fallback.
    age ??= (childData['age'] as num?)?.toInt();

    if (age == null) {
      throw Exception('AGE_NOT_FOUND');
    }

    if (age >= 5 && age <= 7) {
      return 'G1';
    }

    if (age >= 8 && age <= 10) {
      return 'G2';
    }

    if (age >= 11 && age <= 13) {
      return 'G3';
    }

    throw Exception('AGE_OUTSIDE_FASEH_RANGE');
  }

  // ---------------------------------------------------------------------------
  // Ensure current child has a leaderboard-safe profile
  // ---------------------------------------------------------------------------

  Future<void> ensureLeaderboardProfile({required String childId}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    if (childId.isEmpty) {
      throw Exception('INVALID_CHILD_ID');
    }

    final childRef = _db.collection('children').doc(childId);

    final publicProfileRef = _db
        .collection('child_public_profiles')
        .doc(childId);

    final leaderboardRef = _db.collection('leaderboard_profiles').doc(childId);

    final results = await Future.wait([childRef.get(), publicProfileRef.get()]);

    final childSnapshot = results[0];
    final publicSnapshot = results[1];

    if (!childSnapshot.exists || childSnapshot.data() == null) {
      throw Exception('CHILD_NOT_FOUND');
    }

    if (!publicSnapshot.exists || publicSnapshot.data() == null) {
      throw Exception('PUBLIC_PROFILE_NOT_FOUND');
    }

    final childData = childSnapshot.data()!;

    final publicData = publicSnapshot.data()!;

    final int points = (childData['points'] as num?)?.toInt() ?? 0;

    final int streak = (childData['streak'] as num?)?.toInt() ?? 0;

    final String ageGroup = resolveAgeGroup(childData);

    final String name = (publicData['name'] ?? '').toString().trim();

    final String avatar = (publicData['avatar'] ?? '🌟').toString();

    if (name.isEmpty) {
      throw Exception('PUBLIC_NAME_NOT_FOUND');
    }

    final batch = _db.batch();

    // Keep the derived group privately as the
    // source of truth for rule validation.
    batch.update(childRef, {
      'points': points,
      'streak': streak,
      'ageGroup': ageGroup,
    });

    // Only leaderboard-safe fields are exposed here.
    batch.set(leaderboardRef, {
      'name': name,
      'avatar': avatar,
      'points': points,
      'streak': streak,
      'ageGroup': ageGroup,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    debugPrint(
      '🏆 LEADERBOARD PROFILE → '
      'child=$childId, '
      'points=$points, '
      'streak=$streak, '
      'ageGroup=$ageGroup',
    );
  }
}
