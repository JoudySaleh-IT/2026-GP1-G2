import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import 'childSession.dart';

class FcmService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<String> _getDeviceId() async {
  final prefs = await SharedPreferences.getInstance();

  String? deviceId = prefs.getString('faseh_device_id');

  if (deviceId != null && deviceId.isNotEmpty) {
    return deviceId;
  }

  final random = Random.secure();

  final randomPart = List.generate(
    16,
    (_) => random.nextInt(256)
        .toRadixString(16)
        .padLeft(2, '0'),
  ).join();

  deviceId =
      'device_${DateTime.now().microsecondsSinceEpoch}_$randomPart';

  await prefs.setString(
    'faseh_device_id',
    deviceId,
  );

  print('📱 NEW FASEH DEVICE ID CREATED: $deviceId');

  return deviceId;
}

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

    final String deviceId = await _getDeviceId();

print('📱 CHILD DEVICE ID = $deviceId');

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
.doc(deviceId)
    .set({
  'token': token,

  // This device is currently being used in child mode.
  'activeMode': 'child',

  // Which child is currently using the device.
  'activeChildId': childId,

  'updatedAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));


print('🔥 DEVICE MODE SAVED');
print('🔥 activeMode = child');
print('🔥 activeChildId = $childId');
print('🔥 deviceUid = $currentUid');
print('🔥 parentId = $parentId');
  print('✅ FAMILY FCM TOKEN SAVED');
print('👨‍👩‍👧 Parent: $parentId');
print('📱 DEVICE ID: $deviceId');
}

// 👇👇👇 حطيها هنا
Future<void> saveTokenForParent() async {
  final String? token = await _messaging.getToken();

  if (token == null || token.isEmpty) {
    print('❌ Parent FCM token is null');
    return;
  }

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    print('❌ Parent user is not signed in');
    return;
  }

  final String parentId = user.uid;
  final String deviceId = await _getDeviceId();

print('📱 PARENT DEVICE ID = $deviceId');

  await _db
      .collection('parent_fcm_tokens')
      .doc(parentId)
      .collection('devices')
      .doc(deviceId)
      .set({
    'token': token,
    'activeMode': 'parent',
    'activeChildId': null,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  print('👨‍👩‍👧 PARENT DEVICE MODE SAVED');
  print('🔥 activeMode = parent');
  print('🔥 activeChildId = null');
print('📱 deviceId = $deviceId');
}


}