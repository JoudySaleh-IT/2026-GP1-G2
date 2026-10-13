import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'childSession.dart';

class FcmService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> saveTokenForChild(String childId) async {
    if (childId.isEmpty) return;

    final String? token = await _messaging.getToken();

    if (token == null || token.isEmpty) {
      print('❌ FCM token is null');
      return;
    }

    // 1. Keep existing child token
    await _db.collection('child_fcm_tokens').doc(childId).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ FCM token saved for child: $childId');

    // 2. Get current authenticated UID
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

    if (currentUid == null || currentUid.isEmpty) {
      print('❌ Current UID is not available');
      return;
    }

    String? parentId;

    // 3. First try the parent session.
    // This works when the parent logs in and selects a child.
    if (ChildSession.currentParentId != null &&
        ChildSession.currentParentId!.isNotEmpty) {
      parentId = ChildSession.currentParentId;

      print('✅ Parent found from current session: $parentId');
    } else {
      // 4. Otherwise try the device link.
      // This works when the child enters using the 6-digit pairing code.
      final deviceLink = await _db
          .collection('child_device_links')
          .doc(currentUid)
          .get();

      if (deviceLink.exists) {
        parentId = deviceLink.data()?['parentId']?.toString();

        if (parentId != null && parentId.isNotEmpty) {
          ChildSession.currentParentId = parentId;

          print('✅ Parent found from device link: $parentId');
        }
      }
    }

    if (parentId == null || parentId.isEmpty) {
      print('❌ Could not determine parentId');
      return;
    }

    // 5. Register this device for the family
    await _db
        .collection('parent_fcm_tokens')
        .doc(parentId)
        .collection('devices')
        .doc(currentUid)
        .set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ FAMILY FCM TOKEN SAVED');
    print('👨‍👩‍👧 Parent: $parentId');
    print('📱 UID: $currentUid');
  }
}