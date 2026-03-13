import 'package:flutter/material.dart';

class ParentRegisterScreen extends StatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  State<ParentRegisterScreen> createState() => _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends State<ParentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers hold the text typed into each field
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Toggles for showing/hiding passwords
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    // Always dispose controllers to free memory
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // Mock registration — navigate to create-child screen
      Navigator.pushNamed(context, '/parent/create-child');
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
                // ── Back Button Row ──────────────────────────────
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
                            'تسجيل ولي الأمر',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF511281),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'أنشئ حسابك لإدارة ملفات أطفالك',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Full Name Field ────────────────────
                          _buildLabel('الاسم الكامل'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _fullNameController,
                            hint: 'أدخل اسمك الكامل',
                            validator: (v) =>
                            v == null || v.isEmpty ? 'الرجاء إدخال الاسم الكامل' : null,
                          ),

                          const SizedBox(height: 16),

                          // ── Email Field ────────────────────────
                          _buildLabel('البريد الإلكتروني'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'parent@example.com',
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                              if (!v.contains('@')) return 'البريد الإلكتروني غير صحيح';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ── Password Field ─────────────────────
                          _buildLabel('كلمة المرور'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _passwordController,
                            hint: '••••••••',
                            obscure: !_showPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF511281),
                              ),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الرجاء إدخال كلمة المرور';
                              if (v.length < 6) return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // ── Confirm Password Field ─────────────
                          _buildLabel('تأكيد كلمة المرور'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint: '••••••••',
                            obscure: !_showConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF511281),
                              ),
                              onPressed: () => setState(
                                      () => _showConfirmPassword = !_showConfirmPassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الرجاء تأكيد كلمة المرور';
                              if (v != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
                              return null;
                            },
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
                                'إنشاء حساب',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Login Link ─────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'لديك حساب بالفعل؟',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              const SizedBox(width: 8), // 👈 مسافة بسيطة بين النص والرابط
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/parent/login'),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Reusable Label Widget ──────────────────────────────────────────────────
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

  // ── Reusable Text Field Widget ─────────────────────────────────────────────
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextDirection textDirection = TextDirection.rtl,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      textDirection: textDirection,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        suffixIcon: suffixIcon,
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
      ),
    );
  }
}