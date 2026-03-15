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

  /// --- منطق تسجيل الخروج ---
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// --- الحصول على المستخدم الحالي ---
  User? get currentUser => _auth.currentUser;
}