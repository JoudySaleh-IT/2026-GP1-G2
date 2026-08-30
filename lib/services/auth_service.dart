import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'faseh_id_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FasehIdService _fasehIdService = FasehIdService();

  // ─── تسجيل ولي الأمر (Parent Registration) ───
  Future<User?> registerParent({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        await _db.collection('parents').doc(user.uid).set({
          'parentId': user.uid,
          'fullName': fullName,
          'email': email,
          'role': 'parent',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      // طباعة رسائل الخطأ وإعادة رمي الاستثناء لتلتقطه الواجهة
      if (e.code == 'email-already-in-use') {
        print("البريد الإلكتروني مستخدم بالفعل.");
      } else if (e.code == 'weak-password') {
        print("كلمة المرور ضعيفة جداً.");
      } else if (e.code == 'invalid-email') {
        print("البريد الإلكتروني غير صالح.");
      }
      rethrow; 
    } catch (e) {
      print("حدث خطأ غير متوقع أثناء التسجيل: $e");
      return null;
    }
  }

  // ─── تسجيل الدخول (Login) ───
  Future<User?> loginParent(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Login Error Code: ${e.code}");
      rethrow;
    } catch (e) {
      print("Unexpected Login Error: $e");
      return null;
    }
  }

  // ─── إضافة ملف طفل جديد (يدعم تعدد الأطفال) ───
  // ─── إضافة ملف طفل جديد (تحديث القيم الابتدائية) ───
Future<bool> createChildProfile({
  required String name,
  required int age,
  required DateTime dob,
  required String gender,
  required String avatar,
}) async {
  try {
    final String? currentParentId = _auth.currentUser?.uid;

    if (currentParentId == null) {
      return false;
    }

    const int maxAttempts = 10;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      // Generate a candidate public Faseh ID.
      final String fasehId =
          await _fasehIdService.generateUniqueFasehId();

      // Reserve the child document ID before writing anything.
      final DocumentReference<Map<String, dynamic>> childRef =
          _db.collection('children').doc();

      final DocumentReference<Map<String, dynamic>> fasehIdRef =
          _db.collection('faseh_ids').doc(fasehId);

      final DocumentReference<Map<String, dynamic>> publicProfileRef =
          _db.collection('child_public_profiles').doc(childRef.id);

      try {
        await _db.runTransaction((transaction) async {
          // Final uniqueness check inside the transaction.
          final fasehIdSnapshot =
              await transaction.get(fasehIdRef);

          if (fasehIdSnapshot.exists) {
            throw Exception('FASEH_ID_COLLISION');
          }

          // 1. Private child document
          transaction.set(childRef, {
            'parentId': currentParentId,
            'name': name,
            'dob': Timestamp.fromDate(dob),
            'age': age,
            'gender': gender,
            'avatar': avatar,
            'progress': 0,
            'level': 'لم يتم تحديد المستوى ',
            'placementDone': false,
            'fasehId': fasehId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // 2. Faseh ID lookup document
          transaction.set(fasehIdRef, {
            'childId': childRef.id,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // 3. Safe public profile
          transaction.set(publicProfileRef, {
            'fasehId': fasehId,
            'name': name,
            'avatar': avatar,
            'createdAt': FieldValue.serverTimestamp(),
          });
        });

        // Everything was created successfully.
        return true;
      } catch (e) {
        if (e.toString().contains('FASEH_ID_COLLISION')) {
          // Extremely unlikely, but generate another ID and retry.
          continue;
        }

        rethrow;
      }
    }

    throw Exception('Failed to generate a unique Faseh ID.');
  } catch (e) {
    print("Error creating child: $e");
    rethrow;
  }
}

// ─── إنشاء Faseh ID للأطفال الموجودين مسبقاً ───
Future<String> ensureChildFasehIdentity(String childId) async {
  try {
    final String? currentParentId = _auth.currentUser?.uid;

    if (currentParentId == null) {
      throw Exception('Parent is not authenticated.');
    }

    final DocumentReference<Map<String, dynamic>> childRef =
        _db.collection('children').doc(childId);

    // Read the existing child first.
    final childSnapshot = await childRef.get();

    if (!childSnapshot.exists) {
      throw Exception('Child does not exist.');
    }

    final childData = childSnapshot.data()!;

    // Make sure this child belongs to the logged-in parent.
    if (childData['parentId'] != currentParentId) {
      throw Exception('You do not own this child profile.');
    }

    // If the child already has a Faseh ID, do nothing.
    final String? existingFasehId =
        childData['fasehId'] as String?;

    if (existingFasehId != null &&
        existingFasehId.trim().isNotEmpty) {
      return existingFasehId;
    }

    const int maxAttempts = 10;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final String fasehId =
          await _fasehIdService.generateUniqueFasehId();

      final DocumentReference<Map<String, dynamic>> fasehIdRef =
          _db.collection('faseh_ids').doc(fasehId);

      final DocumentReference<Map<String, dynamic>> publicProfileRef =
          _db.collection('child_public_profiles').doc(childId);

      try {
        final String result =
            await _db.runTransaction<String>((transaction) async {
          // Re-read inside the transaction in case something changed.
          final latestChildSnapshot =
              await transaction.get(childRef);

          if (!latestChildSnapshot.exists) {
            throw Exception('Child does not exist.');
          }

          final latestChildData =
              latestChildSnapshot.data()!;

          if (latestChildData['parentId'] != currentParentId) {
            throw Exception(
              'You do not own this child profile.',
            );
          }

          // Another process may have already assigned one.
          final String? currentFasehId =
              latestChildData['fasehId'] as String?;

          if (currentFasehId != null &&
              currentFasehId.trim().isNotEmpty) {
            return currentFasehId;
          }

          // Final uniqueness check.
          final fasehIdSnapshot =
              await transaction.get(fasehIdRef);

          if (fasehIdSnapshot.exists) {
            throw Exception('FASEH_ID_COLLISION');
          }

          final String childName =
              (latestChildData['name'] ?? '').toString();

          final String childAvatar =
              (latestChildData['avatar'] ?? '').toString();

          // 1. Add fasehId to the EXISTING private child document.
          transaction.update(childRef, {
            'fasehId': fasehId,
          });

          // 2. Create lookup document.
          transaction.set(fasehIdRef, {
            'childId': childId,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // 3. Create safe public profile.
          transaction.set(publicProfileRef, {
            'fasehId': fasehId,
            'name': childName,
            'avatar': childAvatar,
            'createdAt': FieldValue.serverTimestamp(),
          });

          return fasehId;
        });

        return result;
      } catch (e) {
        if (e.toString().contains('FASEH_ID_COLLISION')) {
          continue;
        }

        rethrow;
      }
    }

    throw Exception(
      'Failed to generate a unique Faseh ID.',
    );
  } catch (e) {
    print('Error ensuring child Faseh identity: $e');
    rethrow;
  }
}
  // ─── مزامنة عمر الطفل بناءً على تاريخ الميلاد ───
  Future<void> syncChildAge(String childId) async {
    try {
      final doc = await _db.collection('children').doc(childId).get();
      final data = doc.data();
      if (data == null || data['dob'] == null) return;

      final dob = (data['dob'] as Timestamp).toDate();
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      await _db.collection('children').doc(childId).update({'age': age});
    } catch (e) {
      print("Error syncing age: $e");
    }
  }

  // ─── تحديث اسم ولي الأمر ───
  Future<void> updateName(String newName) async {
    try {
      String parentId = _auth.currentUser!.uid;
      await _db.collection('parents').doc(parentId).update({'fullName': newName});
    } catch (e) {
      print("Error updating name: $e");
      rethrow;
    }
  }

  // ─── تحديث كلمة المرور ───
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser!.updatePassword(newPassword);
    } catch (e) {
      rethrow;
    }
  }

  // ─── إعادة تعيين كلمة المرور ───
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      rethrow;
    }
  }

  // ─── تسجيل الخروج ───
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── الحصول على بيانات الأب الحالي ───
  User? get currentUser => _auth.currentUser;

  // ─── تحديث بيانات الطفل (تم حذف gradeLevel تماماً) ───
 Future<void> updateChildProfile({
  required String childId,
  required String name,
  required int age,
  required String avatar,
  required DateTime dob,
}) async {
  try {
    final String? currentParentId = _auth.currentUser?.uid;

    if (currentParentId == null) {
      throw Exception('Parent is not authenticated.');
    }

    final childRef =
        _db.collection('children').doc(childId);

    final publicProfileRef =
        _db.collection('child_public_profiles').doc(childId);

    await _db.runTransaction((transaction) async {
      // ─── ALL READS FIRST ───

      final childSnapshot =
          await transaction.get(childRef);

      final publicProfileSnapshot =
          await transaction.get(publicProfileRef);

      if (!childSnapshot.exists) {
        throw Exception('Child does not exist.');
      }

      final childData = childSnapshot.data()!;

      if (childData['parentId'] != currentParentId) {
        throw Exception(
          'You do not own this child profile.',
        );
      }

      // ─── ALL WRITES AFTER READS ───

      transaction.update(childRef, {
        'name': name,
        'age': age,
        'dob': Timestamp.fromDate(dob),
        'avatar': avatar,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Keep the safe public profile synchronized.
      if (publicProfileSnapshot.exists) {
        transaction.update(publicProfileRef, {
          'name': name,
          'avatar': avatar,
        });
      }
    });
  } catch (e) {
    print("Error updating child: $e");
    throw Exception("فشل في تحديث بيانات الطفل");
  }
}

  // ─── حذف ملف الطفل ───
 Future<void> deleteChild(String childId) async {
  try {
    final String? currentParentId = _auth.currentUser?.uid;

    if (currentParentId == null) {
      throw Exception('Parent is not authenticated.');
    }

    final childRef =
        _db.collection('children').doc(childId);

    final publicProfileRef =
        _db.collection('child_public_profiles').doc(childId);

    await _db.runTransaction((transaction) async {
      // ─── READ FIRST ───
      final childSnapshot =
          await transaction.get(childRef);

      if (!childSnapshot.exists) {
        throw Exception('Child does not exist.');
      }

      final childData = childSnapshot.data()!;

      if (childData['parentId'] != currentParentId) {
        throw Exception(
          'You do not own this child profile.',
        );
      }

      final String? fasehId =
          childData['fasehId'] as String?;

      // ─── WRITES AFTER READ ───

      // Remove public profile.
      transaction.delete(publicProfileRef);

      // Remove Faseh ID lookup if the child has one.
      if (fasehId != null && fasehId.trim().isNotEmpty) {
        final fasehIdRef =
            _db.collection('faseh_ids').doc(fasehId);

        transaction.delete(fasehIdRef);
      }

      // Finally remove the private child document.
      transaction.delete(childRef);
    });
  } catch (e) {
    print('Error deleting child: $e');
    rethrow;
  }
}

  // ─── جلب ID أول طفل (للتوافق) ───
  Future<String?> getFirstChildId() async {
    try {
      String? parentId = _auth.currentUser?.uid;
      if (parentId == null) return null;
      var snapshot = await _db
          .collection('children')
          .where('parentId', isEqualTo: parentId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}