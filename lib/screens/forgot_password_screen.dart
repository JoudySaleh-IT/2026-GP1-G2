import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitted = true);
    }
  }

  // ── Shared card wrapper ──────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF511281).withOpacity(0.1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }

  // ── Purple circle icon ───────────────────────────────────────────────────
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

  // ── SUCCESS STATE ────────────────────────────────────────────────────────
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF511281),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),

          const SizedBox(height: 20),

          // Info box with email
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF511281).withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF511281).withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'يرجى التحقق من بريدك الإلكتروني واتباع التعليمات لإعادة تعيين كلمة المرور الخاصة بك',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  _emailController.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Resend link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'لم تستلم الرسالة؟ ',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              GestureDetector(
                onTap: () => setState(() => _isSubmitted = false),
                child: const Text(
                  'إعادة الإرسال',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF511281),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Back to login button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/parent/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF511281),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'العودة لتسجيل الدخول',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FORM STATE ───────────────────────────────────────────────────────────
  Widget _buildFormView() {
    return Column(
      children: [
        // Back button
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF511281),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'أدخل بريدك الإلكتروني وسنرسل لك رابط لإعادة تعيين كلمة المرور',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 28),

                // Email label
                const Text(
                  'البريد الإلكتروني',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 6),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                    if (!v.contains('@')) return 'البريد الإلكتروني غير صحيح';
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'parent@example.com',
                    hintStyle: const TextStyle(color: Colors.grey),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: const Color(0xFF511281).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      const BorderSide(color: Color(0xFF511281), width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      const BorderSide(color: Colors.red, width: 2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                      const BorderSide(color: Colors.red, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF511281),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'إرسال رابط إعادة التعيين',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back to login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'تذكرت كلمة المرور؟ ',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/parent/login'),
                      child: const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF511281),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
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
            // Swap between form and success view based on _isSubmitted
            child: _isSubmitted ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }
}
