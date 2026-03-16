import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // 1. تهيئة نسخ Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// --- منطق تسجيل ولي الأمر ---
  /// هذه الدالة تقوم بإنشاء الحساب (Auth) وحفظ بيانات الملف الشخصي (Firestore)
  Future<User?> registerParent({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // الخطوة أ: إنشاء المستخدم في Firebase Authentication
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;

      // الخطوة ب: إذا تم إنشاء المستخدم بنجاح، احفظ بياناته الإضافية في Firestore
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'email': email,
          'role': 'parent', 
          'createdAt': FieldValue.serverTimestamp(), // وقت إنشاء الحساب تلقائياً
        });
      }
      return user;

    } on FirebaseAuthException catch (e) {
      // التعامل مع أخطاء Firebase المعروفة
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
  // دالة تسجيل الدخول
  Future<User?> loginParent(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // طباعة الخطأ في الـ Console للمبرمج
      print("Login Error Code: ${e.code}");
      rethrow; // نعيد إرسال الخطأ لكي تتعامل معه شاشة الـ UI
    } catch (e) {
      print("Unexpected Login Error: $e");
      return null;
    }
  }
// --- منطق التعامل مع ملفات الأطفال ---

  // 1. الدالة المسؤولة عن إضافة طفل جديد مع التحقق من القيد
  Future<bool> createChildProfile({
    required String name,
    required int age,
    required String gender,
    required String avatar,
  }) async {
    try {
      final String? userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      // أ: التحقق من وجود أطفال سابقين (قيد الطفل الواحد)
      final existing = await _db
          .collection('children')
          .where('parentId', isEqualTo: userId)
          .get();

      if (existing.docs.isNotEmpty) {
        throw Exception('limit-reached'); // وصلنا للحد الأقصى
      }

      // ب: إضافة الطفل في Firestore
      await _db.collection('children').add({
        'parentId': userId,
        'name': name,
        'age': age,
        'gender': gender,
        'avatar': avatar,
        'progress': 0,
        'level': 'مبتدئ',
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      rethrow; // نعيد إرسال الخطأ لكي تظهره الشاشة
    }
  }

  //  تحديث اسم المستخدم في Firestore
  Future<void> updateName(String newName) async {
    String uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).update({'fullName': newName});
  }

  //  تحديث كلمة المرور في Authentication
  Future<void> updatePassword(String newPassword) async {
    await _auth.currentUser!.updatePassword(newPassword);
  }
// إرسال رابط إعادة تعيين كلمة المرور
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("Error Code: ${e.code}");
      rethrow; // نمرر الخطأ للـ UI للتعامل معه
    } catch (e) {
      throw Exception("حدث خطأ غير متوقع");
    }
  }
  
  /// --- منطق تسجيل الخروج ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// --- الحصول على المستخدم الحالي ---
  User? get currentUser => _auth.currentUser;
}