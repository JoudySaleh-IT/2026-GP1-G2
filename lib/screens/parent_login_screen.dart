import 'package:flutter/material.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // Mock login — navigate to parent dashboard
      Navigator.pushNamed(context, '/parent/dashboard');
    }
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
            child: Column(
              children: [
                // ── Back Button ──────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF511281)),
                  ),
                ),

                const SizedBox(height: 8),

                // ── Card ─────────────────────────────────────────
                Container(
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          // ── Card Header ────────────────────────
                          const Text(
                            'تسجيل دخول ولي الأمر',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF511281),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'سجل دخولك للوصول إلى لوحة التحكم',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),

                          const SizedBox(height: 28),

                          // ── Email Field ────────────────────────
                          _buildLabel('البريد الإلكتروني'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                              if (!v.contains('@')) return 'البريد الإلكتروني غير صحيح';
                              return null;
                            },
                            decoration: _inputDecoration('parent@example.com'),
                          ),

                          const SizedBox(height: 16),

                          // ── Password Field ─────────────────────
                          _buildLabel('كلمة المرور'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_showPassword,
                            validator: (v) =>
                            v == null || v.isEmpty ? 'الرجاء إدخال كلمة المرور' : null,
                            decoration: _inputDecoration('••••••••').copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFF511281),
                                ),
                                onPressed: () =>
                                    setState(() => _showPassword = !_showPassword),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ── Forgot Password ────────────────────
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                  context, '/parent/forgot-password'),
                              child: const Text(
                                'نسيت كلمة المرور؟',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF511281),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ── Submit Button ──────────────────────
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
                                'تسجيل الدخول',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Register Link ──────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'ليس لديك حساب؟ ',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, '/parent/register'),
                                child: const Text(
                                  'إنشاء حساب',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF333333),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: const Color(0xFF511281).withOpacity(0.3),
          width: 2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF511281), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }
}
