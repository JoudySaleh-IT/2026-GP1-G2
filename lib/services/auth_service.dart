import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  Future<bool> createChildProfile({
    required String name,
    required int age,
    required DateTime dob,
    required String gender,
    required String avatar,
  }) async {
    try {
      final String? currentParentId = _auth.currentUser?.uid;
      if (currentParentId == null) return false;

      // تم إزالة شرط "الطفل الواحد" للسماح بإضافة أكثر من طفل
      await _db.collection('children').add({
        'parentId': currentParentId, 
        'name': name,
        'dob': Timestamp.fromDate(dob),
        'age': age,
        'gender': gender,
        'avatar': avatar,
        'progress': 0,
        'level': 'مبتدئ',
        'placementDone': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print("Error creating child: $e");
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
      await _db.collection('children').doc(childId).update({
        'name': name,
        'age': age,
        'dob': Timestamp.fromDate(dob),
        'avatar': avatar,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error updating child: $e");
      throw Exception("فشل في تحديث بيانات الطفل");
    }
  }

  // ─── حذف ملف الطفل ───
  Future<void> deleteChild(String childId) async {
    try {
      await _db.collection('children').doc(childId).delete();
    } catch (e) {
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