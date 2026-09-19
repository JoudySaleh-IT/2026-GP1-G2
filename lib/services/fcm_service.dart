import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

    await _db.collection('child_fcm_tokens').doc(childId).set({
      'token': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ FCM token saved for child: $childId');
  }
}