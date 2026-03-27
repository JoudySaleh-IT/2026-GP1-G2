import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// --- تسجيل ولي الأمر ---
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
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
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

  /// --- تسجيل الدخول ---
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

  /// --- إضافة ملف طفل جديد ---
  /// [dob] تاريخ الميلاد — يُحفظ كـ Timestamp في Firestore
  /// [age]  يُحسب تلقائياً من tاريخ الميلاد عند الإنشاء
  Future<bool> createChildProfile({
    required String name,
    required int age,
    required DateTime dob,   // ← تاريخ الميلاد
    required String gender,
    required String avatar,
  }) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // التحقق من قيد الطفل الواحد
      final existing = await _db
          .collection('children')
          .where('parentId', isEqualTo: userId)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('limit-reached');
      }

      // حفظ بيانات الطفل
      await _db.collection('children').add({
        'parentId': userId,
        'name': name,
        'dob': Timestamp.fromDate(dob),   // ← تاريخ الميلاد كـ Timestamp
        'age': age,                        // ← العمر وقت التسجيل
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

  /// --- تحديث العمر تلقائياً من تاريخ الميلاد ---
  /// استدعِها عند فتح التطبيق أو في Cloud Function
  Future<void> syncChildAge(String childId) async {
    try {
      final doc = await _db.collection('children').doc(childId).get();
      final data = doc.data();
      if (data == null || data['dob'] == null) return;

      final dob = (data['dob'] as Timestamp).toDate();
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }

      await _db.collection('children').doc(childId).update({'age': age});
    } catch (e) {
      print("Error syncing age: $e");
    }
  }

  /// --- تحديث اسم المستخدم ---
  Future<void> updateName(String newName) async {
    String uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).update({'fullName': newName});
  }

  /// --- تحديث كلمة المرور ---
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }

  /// --- إعادة تعيين كلمة المرور ---
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("Error Code: ${e.code}");
      rethrow;
    } catch (e) {
      throw Exception("حدث خطأ غير متوقع");
    }
  }

  /// --- تسجيل الخروج ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// --- المستخدم الحالي ---
  User? get currentUser => _auth.currentUser;

  /// --- تحديث بيانات الطفل ---
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
      print("Error updating child: $e");
      throw Exception("فشل في تحديث بيانات الطفل");
    }
  }

  /// --- حذف ملف الطفل ---
  Future<void> deleteChild(String childId) async {
    await _db.collection('children').doc(childId).delete();
  }

  /// --- جلب ID أول طفل لهذا الأب ---
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