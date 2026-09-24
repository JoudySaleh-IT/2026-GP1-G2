import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class PracticeTogetherService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Creates the same pair ID for A-B and B-A.
  String _buildPairId(String childA, String childB) {
    final ids = [childA, childB]..sort();

    return '${ids[0]}__${ids[1]}';
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

    final pairId = _buildPairId(senderChildId, receiverChildId);

    final friendshipRef = _db.collection('friendships').doc(pairId);

    final sessionRef = _db.collection('practice_sessions').doc();

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
    });

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
