import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

enum PracticeExerciseType { listening, speaking }

extension PracticeExerciseTypeValue on PracticeExerciseType {
  String get firestoreValue {
    switch (this) {
      case PracticeExerciseType.listening:
        return 'listening';

      case PracticeExerciseType.speaking:
        return 'speaking';
    }
  }
}

class PracticeAvailableExercise {
  final String letter;
  final String level;

  const PracticeAvailableExercise({required this.letter, required this.level});

  String get id => '$letter|$level';

  String get arabicLevel {
    switch (level) {
      case 'beginner':
        return 'مبتدئ';
      case 'intermediate':
        return 'متوسط';
      case 'advanced':
        return 'متقدم';
      default:
        return level;
    }
  }
}

class PracticeTogetherService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Creates the same pair ID for A-B and B-A.
  String _buildPairId(String childA, String childB) {
    final ids = [childA, childB]..sort();

    return '${ids[0]}__${ids[1]}';
  }

  String _normalizeLevel(dynamic rawLevel) {
    final level = rawLevel?.toString().trim().toLowerCase() ?? '';

    switch (level) {
      case 'beginner':
      case 'foundational':
      case 'easy':
      case 'مبتدئ':
      case 'تأسيسي':
        return 'beginner';

      case 'intermediate':
      case 'developing':
      case 'moderate':
      case 'متوسط':
        return 'intermediate';

      case 'advanced':
      case 'master':
      case 'mastered':
      case 'hard':
      case 'متقدم':
      case 'متقن':
        return 'advanced';

      default:
        return 'beginner';
    }
  }

  Future<List<PracticeAvailableExercise>> getAvailableExercises({
    required String childId,
    required PracticeExerciseType exerciseType,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    final childSnapshot = await _db.collection('children').doc(childId).get();

    if (!childSnapshot.exists || childSnapshot.data() == null) {
      throw Exception('CHILD_NOT_FOUND');
    }

    final data = childSnapshot.data()!;

    // Child must complete placement before exercises are available.
    if (data['placementDone'] != true) {
      return [];
    }

    final currentLevel = _normalizeLevel(data['level']);

    final rawScores = data['letterScores'];
    final rawExerciseProgress = data['exerciseProgress'];

    if (rawScores is! Map) {
      return [];
    }

    const supportedLetters = ['ض', 'س', 'ص', 'غ', 'خ', 'ق'];

    final List<PracticeAvailableExercise> available = [];

    for (final letter in supportedLetters) {
      final rawScore = rawScores[letter];

      if (rawScore is! num) {
        continue;
      }

      // Same rule used by the normal Exercises screen:
      // only letters that still need training.
      if (rawScore >= 80) {
        continue;
      }

      // Listening is always available for the child's current level.
      if (exerciseType == PracticeExerciseType.listening) {
        available.add(
          PracticeAvailableExercise(letter: letter, level: currentLevel),
        );

        continue;
      }

      // Speaking requires Listening to have already been passed
      // for this letter and current level.
      bool listeningPassed = false;

      if (rawExerciseProgress is Map) {
        final rawLetterProgress = rawExerciseProgress[letter];

        if (rawLetterProgress is Map) {
          final rawLevelProgress = rawLetterProgress[currentLevel];

          if (rawLevelProgress is Map) {
            listeningPassed = rawLevelProgress['listeningPassed'] == true;
          }
        }
      }

      if (listeningPassed) {
        available.add(
          PracticeAvailableExercise(letter: letter, level: currentLevel),
        );
      }
    }

    return available;
  }
  // ---------------------------------------------------------------------------
  // Send invitation
  // ---------------------------------------------------------------------------

  Future<String> sendInvitation({
    required String senderChildId,
    required String receiverChildId,
    required PracticeExerciseType exerciseType,
    required String letter,
    required String level,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    if (senderChildId.isEmpty || receiverChildId.isEmpty) {
      throw Exception('INVALID_CHILD');
    }

    if (senderChildId == receiverChildId) {
      throw Exception('CANNOT_INVITE_SELF');
    }

    final availableExercises = await getAvailableExercises(
      childId: senderChildId,
      exerciseType: exerciseType,
    );

    final bool exerciseIsAvailable = availableExercises.any(
      (exercise) => exercise.letter == letter && exercise.level == level,
    );

    if (!exerciseIsAvailable) {
      throw Exception('EXERCISE_NOT_AVAILABLE');
    }
    final pairId = _buildPairId(senderChildId, receiverChildId);

    final friendshipRef = _db.collection('friendships').doc(pairId);

    final sessionRef = _db.collection('practice_sessions').doc();

    final notificationRef = _db.collection('notifications').doc();

    await _db.runTransaction((transaction) async {
      // Verify friendship first.
      final friendshipSnapshot = await transaction.get(friendshipRef);

      if (!friendshipSnapshot.exists) {
        throw Exception('NOT_FRIENDS');
      }

      final friendshipData = friendshipSnapshot.data();

      final rawMembers = friendshipData?['memberIds'];

      final members = rawMembers is List
          ? rawMembers.map((e) => e.toString()).toList()
          : <String>[];

      if (!members.contains(senderChildId) ||
          !members.contains(receiverChildId)) {
        throw Exception('INVALID_FRIENDSHIP');
      }

      // Create the invitation/session.
      transaction.set(sessionRef, {
        'senderId': senderChildId,
        'receiverId': receiverChildId,

        'memberIds': [senderChildId, receiverChildId],

        'pairId': pairId,

        'exerciseType': exerciseType.firestoreValue,

        // This is the SENDER'S exercise only.
        'senderLetter': letter,
        'senderLevel': level,

        'status': 'pending',

        'createdAt': FieldValue.serverTimestamp(),
      });

      transaction.set(notificationRef, {
        'receiverId': receiverChildId,
        'senderId': senderChildId,
        'type': 'practice_invitation',
        'referenceId': sessionRef.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

      final callable = functions.httpsCallable('sendPushNotification');

      final result = await callable.call({
        'receiverId': receiverChildId,
        'senderId': senderChildId,
        'type': 'practice_invitation',
        'referenceId': sessionRef.id,
      });

      print('🔔 PRACTICE PUSH RESULT: ${result.data}');
    } catch (e) {
      // Session is already created, so push failure
      // should not cancel the invitation.
      print('❌ PRACTICE PUSH ERROR: $e');
    }

    return sessionRef.id;
  }

  // ---------------------------------------------------------------------------
  // Incoming invitations
  // ---------------------------------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> incomingInvitations({
    required String childId,
  }) {
    return _db
        .collection('practice_sessions')
        .where('receiverId', isEqualTo: childId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // ---------------------------------------------------------------------------
  // Watch one session
  // ---------------------------------------------------------------------------

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSession({
    required String sessionId,
  }) {
    return _db.collection('practice_sessions').doc(sessionId).snapshots();
  }

  // ---------------------------------------------------------------------------
  // Accept invitation
  // ---------------------------------------------------------------------------

  Future<void> acceptInvitation({
    required String sessionId,
    required String childId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    final sessionRef = _db.collection('practice_sessions').doc(sessionId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);

      if (!snapshot.exists) {
        throw Exception('SESSION_NOT_FOUND');
      }

      final data = snapshot.data();

      if (data == null) {
        throw Exception('INVALID_SESSION');
      }

      if (data['receiverId'] != childId) {
        throw Exception('NOT_INVITATION_RECEIVER');
      }

      if (data['status'] != 'pending') {
        throw Exception('INVITATION_NOT_PENDING');
      }

      transaction.update(sessionRef, {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Receiver selects their exercise
  // ---------------------------------------------------------------------------

  Future<void> selectReceiverExercise({
    required String sessionId,
    required String childId,
    required String letter,
    required String level,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    final sessionRef = _db.collection('practice_sessions').doc(sessionId);

    final sessionSnapshot = await sessionRef.get();

    if (!sessionSnapshot.exists || sessionSnapshot.data() == null) {
      throw Exception('SESSION_NOT_FOUND');
    }

    final data = sessionSnapshot.data()!;

    if (data['receiverId'] != childId) {
      throw Exception('NOT_INVITATION_RECEIVER');
    }

    if (data['status'] != 'accepted') {
      throw Exception('SESSION_NOT_ACCEPTED');
    }

    final String exerciseTypeRaw = data['exerciseType']?.toString() ?? '';

    final PracticeExerciseType exerciseType;

    if (exerciseTypeRaw == 'listening') {
      exerciseType = PracticeExerciseType.listening;
    } else if (exerciseTypeRaw == 'speaking') {
      exerciseType = PracticeExerciseType.speaking;
    } else {
      throw Exception('INVALID_EXERCISE_TYPE');
    }

    // Make sure B is actually allowed to use this exercise.
    final availableExercises = await getAvailableExercises(
      childId: childId,
      exerciseType: exerciseType,
    );

    final bool exerciseIsAvailable = availableExercises.any(
      (exercise) => exercise.letter == letter && exercise.level == level,
    );

    if (!exerciseIsAvailable) {
      throw Exception('EXERCISE_NOT_AVAILABLE');
    }

    await _db.runTransaction((transaction) async {
      final freshSnapshot = await transaction.get(sessionRef);

      if (!freshSnapshot.exists || freshSnapshot.data() == null) {
        throw Exception('SESSION_NOT_FOUND');
      }

      final freshData = freshSnapshot.data()!;

      if (freshData['receiverId'] != childId) {
        throw Exception('NOT_INVITATION_RECEIVER');
      }

      if (freshData['status'] != 'accepted') {
        throw Exception('SESSION_NOT_ACCEPTED');
      }

      transaction.update(sessionRef, {
        'receiverLetter': letter,
        'receiverLevel': level,

        // Both children start the lobby as not ready.
        'senderReady': false,
        'receiverReady': false,

        'status': 'lobby',

        'receiverSelectedAt': FieldValue.serverTimestamp(),

        'lobbyStartedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Mark child as ready in the lobby
  // ---------------------------------------------------------------------------

  Future<void> markReady({
    required String sessionId,
    required String childId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    final sessionRef = _db.collection('practice_sessions').doc(sessionId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('SESSION_NOT_FOUND');
      }

      final data = snapshot.data()!;

      final String status = data['status']?.toString() ?? '';

      // Another device may already have started the countdown.
      if (status == 'countdown' || status == 'active') {
        return;
      }

      if (status != 'lobby') {
        throw Exception('SESSION_NOT_IN_LOBBY');
      }

      final String senderId = data['senderId']?.toString() ?? '';

      final String receiverId = data['receiverId']?.toString() ?? '';

      if (childId != senderId && childId != receiverId) {
        throw Exception('NOT_SESSION_MEMBER');
      }

      final bool isSender = childId == senderId;

      final String ownReadyKey = isSender ? 'senderReady' : 'receiverReady';

      final String otherReadyKey = isSender ? 'receiverReady' : 'senderReady';

      // Already ready — nothing else to do.
      if (data[ownReadyKey] == true) {
        return;
      }

      final bool otherChildReady = data[otherReadyKey] == true;

      final Map<String, dynamic> updates = {ownReadyKey: true};

      // This child is the second player to become ready.
      // Start one shared countdown for both devices.
      if (otherChildReady) {
        updates['status'] = 'countdown';
        updates['countdownStartedAt'] = FieldValue.serverTimestamp();
      }

      transaction.update(sessionRef, updates);
    });
  }

  // ---------------------------------------------------------------------------
  // Cancel lobby if both children do not become ready within 60 seconds
  // ---------------------------------------------------------------------------

  Future<bool> cancelLobbyAfterTimeout({
    required String sessionId,
    required String childId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    final sessionRef = _db.collection('practice_sessions').doc(sessionId);

    return _db.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(sessionRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('SESSION_NOT_FOUND');
      }

      final data = snapshot.data()!;

      final String senderId = data['senderId']?.toString() ?? '';

      final String receiverId = data['receiverId']?.toString() ?? '';

      if (childId != senderId && childId != receiverId) {
        throw Exception('NOT_SESSION_MEMBER');
      }

      // Someone may have become ready at the last moment.
      if (data['status'] != 'lobby') {
        return false;
      }

      final Timestamp? lobbyStartedAt = data['lobbyStartedAt'] as Timestamp?;

      if (lobbyStartedAt == null) {
        throw Exception('MISSING_LOBBY_START_TIME');
      }

      final elapsed = DateTime.now().difference(lobbyStartedAt.toDate());

      if (elapsed < const Duration(seconds: 60)) {
        return false;
      }

      transaction.update(sessionRef, {
        'status': 'cancelled',
        'cancelReason': 'ready_timeout',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  // ---------------------------------------------------------------------------
  // Start session after the shared 3-second countdown
  // ---------------------------------------------------------------------------

  Future<bool> startSessionAfterCountdown({
    required String sessionId,
    required String childId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    final sessionRef = _db.collection('practice_sessions').doc(sessionId);

    return _db.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(sessionRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('SESSION_NOT_FOUND');
      }

      final data = snapshot.data()!;

      final String senderId = data['senderId']?.toString() ?? '';

      final String receiverId = data['receiverId']?.toString() ?? '';

      if (childId != senderId && childId != receiverId) {
        throw Exception('NOT_SESSION_MEMBER');
      }

      // The other device may already have activated it.
      if (data['status'] == 'active') {
        return true;
      }

      if (data['status'] != 'countdown') {
        return false;
      }

      final Timestamp? countdownStartedAt =
          data['countdownStartedAt'] as Timestamp?;

      if (countdownStartedAt == null) {
        throw Exception('MISSING_COUNTDOWN_START_TIME');
      }

      final elapsed = DateTime.now().difference(countdownStartedAt.toDate());

      if (elapsed < const Duration(seconds: 3)) {
        return false;
      }

      transaction.update(sessionRef, {
        'status': 'active',
        'startedAt': FieldValue.serverTimestamp(),
      });

      return true;
    });
  }

  // ---------------------------------------------------------------------------
  // Decline invitation
  // ---------------------------------------------------------------------------

  Future<void> declineInvitation({
    required String sessionId,
    required String childId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    final sessionRef = _db.collection('practice_sessions').doc(sessionId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);

      if (!snapshot.exists) {
        throw Exception('SESSION_NOT_FOUND');
      }

      final data = snapshot.data();

      if (data == null) {
        throw Exception('INVALID_SESSION');
      }

      if (data['receiverId'] != childId) {
        throw Exception('NOT_INVITATION_RECEIVER');
      }

      if (data['status'] != 'pending') {
        throw Exception('INVITATION_NOT_PENDING');
      }

      transaction.update(sessionRef, {
        'status': 'declined',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------------------
  // Cancel invitation
  // ---------------------------------------------------------------------------

  Future<void> cancelInvitation({
    required String sessionId,
    required String childId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    final sessionRef = _db.collection('practice_sessions').doc(sessionId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);

      if (!snapshot.exists) {
        throw Exception('SESSION_NOT_FOUND');
      }

      final data = snapshot.data();

      if (data == null) {
        throw Exception('INVALID_SESSION');
      }

      if (data['senderId'] != childId) {
        throw Exception('NOT_INVITATION_SENDER');
      }

      if (data['status'] != 'pending') {
        throw Exception('INVITATION_NOT_PENDING');
      }

      transaction.update(sessionRef, {
        'status': 'cancelled',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
