import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'faseh_id_service.dart';

class FriendService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FasehIdService _fasehIdService = FasehIdService();

  // Creates the same ID for A-B and B-A.
  String _buildPairId(String childA, String childB) {
    final ids = [childA, childB]..sort();
    return '${ids[0]}__${ids[1]}';
  }

  Future<void> sendFriendRequestByFasehId({
    required String currentChildId,
    required String enteredFasehId,
  }) async {
    // ─── 1. User must be authenticated ───
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('NOT_AUTHENTICATED');
    }

    // ─── 2. Normalize entered Faseh ID ───
    final String fasehId =
        _fasehIdService.normalizeFasehId(enteredFasehId);

    if (fasehId.isEmpty) {
      throw Exception('INVALID_FASEH_ID');
    }

    // ─── 3. Exact Faseh ID lookup ───
    final fasehIdSnapshot =
        await _db.collection('faseh_ids').doc(fasehId).get();

    if (!fasehIdSnapshot.exists) {
      throw Exception('FASEH_ID_NOT_FOUND');
    }

    final fasehIdData = fasehIdSnapshot.data();

    final String? receiverId =
        fasehIdData?['childId'] as String?;

    if (receiverId == null || receiverId.isEmpty) {
      throw Exception('FASEH_ID_NOT_FOUND');
    }

    // ─── 4. Cannot add yourself ───
    if (receiverId == currentChildId) {
      throw Exception('CANNOT_ADD_SELF');
    }

    final String pairId =
        _buildPairId(currentChildId, receiverId);

    final requestRef =
        _db.collection('friend_requests').doc(pairId);

    

    final receiverPublicProfileRef = _db
        .collection('child_public_profiles')
        .doc(receiverId);

    await _db.runTransaction((transaction) async {
      print('========== FRIEND REQUEST DEBUG ==========');
print('authUid: ${user.uid}');
print('isAnonymous: ${user.isAnonymous}');
print('senderId: $currentChildId');
print('receiverId: $receiverId');
print('pairId: $pairId');

final deviceLink = await _db
    .collection('child_device_links')
    .doc(user.uid)
    .get();

print('deviceLink exists: ${deviceLink.exists}');
print('deviceLink data: ${deviceLink.data()}');

final senderProfile = await _db
    .collection('child_public_profiles')
    .doc(currentChildId)
    .get();

print('sender public profile exists: ${senderProfile.exists}');

print('==========================================');
  // ALL READS FIRST
  final receiverProfileSnapshot =
      await transaction.get(receiverPublicProfileRef);

  if (!receiverProfileSnapshot.exists) {
    throw Exception('PUBLIC_PROFILE_NOT_FOUND');
  }

  // WRITE
  transaction.set(requestRef, {
    'senderId': currentChildId,
    'receiverId': receiverId,
    'createdAt': FieldValue.serverTimestamp(),
  });
});
  }
}