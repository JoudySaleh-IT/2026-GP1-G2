import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ تم إضافة هذا السطر لحل الخطأ
import '../services/auth_service.dart'; // تأكدي من صحة المسار

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final AuthService _authService = AuthService(); // ✅ تعريف الخدمة
  
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ── دالة إرسال رابط إعادة تعيين كلمة المرور ──
  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      // 1. إظهار دائرة التحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF511281)),
        ),
      );

      try {
        // 2. استدعاء الـ Service
        await _authService.sendPasswordReset(_emailController.text.trim());

        if (mounted) {
          Navigator.pop(context); // إغلاق التحميل
          setState(() => _isSubmitted = true); // عرض واجهة النجاح
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) Navigator.pop(context); // إغلاق التحميل
        
        String message;
        if (e.code == 'user-not-found' || e.code == 'invalid-email') {
          message = 'عذراً، البريد الإلكتروني غير مسجل لدينا أو غير صحيح.';
        } else {
          message = 'حدث خطأ أثناء الإرسال، حاول لاحقاً.';
        }
        _showErrorDialog(message);
      } catch (e) {
        if (mounted) Navigator.pop(context);
        _showErrorDialog('حدث خطأ غير متوقع');
      }
    }
  }

  // ── دالة إظهار التنبيهات ──
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تنبيه', textAlign: TextAlign.right),
        content: Text(message, textAlign: TextAlign.right),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  // ── Shared UI Components ──
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF511281).withOpacity(0.1), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }

  Widget _buildIconCircle(IconData icon) {
    return Center(
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF511281).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 40, color: const Color(0xFF511281)),
      ),
    );
  }

  // ── واجهة النجاح بعد الإرسال ──
  Widget _buildSuccessView() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIconCircle(Icons.check_circle_outline_rounded),
          const SizedBox(height: 16),
          const Text(
            'تم الإرسال!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF511281)),
          ),
          const SizedBox(height: 8),
          const Text(
            'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني بنجاح.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF511281).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _emailController.text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF511281)),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/parent/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF511281),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('العودة لتسجيل الدخول'),
            ),
          ),
        ],
      ),
    );
  }

  // ── واجهة إدخال البريد ──
  Widget _buildFormView() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF511281)),
          ),
        ),
        const SizedBox(height: 8),
        _buildCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIconCircle(Icons.mail_outline_rounded),
                const SizedBox(height: 16),
                const Text(
                  'نسيت كلمة المرور؟',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF511281)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة المرور',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 28),
                const Text('البريد الإلكتروني', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                    if (!v.contains('@')) return 'صيغة البريد الإلكتروني غير صحيحة';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'parent@example.com',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: const Color(0xFF511281).withOpacity(0.3))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF511281), width: 2)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF511281),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('إرسال الرابط'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _isSubmitted ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }
}