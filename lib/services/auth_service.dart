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
        //  تغيير اسم المجموعة إلى parents والحقل إلى parentId
        await _db.collection('parents').doc(user.uid).set({
          'parentId': user.uid, // استخدام المعرف الفريد كـ parentId
          'fullName': fullName,
          'email': email,
          'role': 'parent',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print("البريد الإلكتروني مستخدم بالفعل.");
      } else if (e.code == 'weak-password') {
        print("كلمة المرور ضعيفة جداً.");
      }
      return null;
    } catch (e) {
      print("حدث خطأ أثناء التسجيل: $e");
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

  // ─── إضافة ملف طفل جديد (Create Child Profile) ───
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

      // التحقق من قيد الطفل الواحد للأب الحالي
      final existing = await _db
          .collection('children')
          .where('parentId', isEqualTo: currentParentId)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('limit-reached');
      }

      // حفظ بيانات الطفل وربطها بـ parentId
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
    String parentId = _auth.currentUser!.uid;
    // ✅ التحديث في مجموعة parents
    await _db.collection('parents').doc(parentId).update({'fullName': newName});
  }

  // ─── تحديث كلمة المرور ───
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
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

  // ─── تحديث بيانات الطفل ───
  Future<void> updateChildProfile({
    required String childId,
    required String name,
    required int age,
    required String gradeLevel,
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
      throw Exception("فشل في تحديث بيانات الطفل");
    }
  }

  // ─── حذف ملف الطفل ───
  Future<void> deleteChild(String childId) async {
    await _db.collection('children').doc(childId).delete();
  }

  // ─── جلب ID أول طفل لولي الأمر الحالي ───
  Future<String?> getFirstChildId() async {
    try {
      String parentId = _auth.currentUser!.uid;
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