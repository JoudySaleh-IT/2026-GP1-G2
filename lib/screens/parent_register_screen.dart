import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ParentRegisterScreen extends StatefulWidget {
  const ParentRegisterScreen({super.key});

  @override
  State<ParentRegisterScreen> createState() => _ParentRegisterScreenState();
}

class _ParentRegisterScreenState extends State<ParentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final AuthService _authService = AuthService();

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── دالة إرسال البيانات ───
  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF511281))),
      );

      // استخدام trim() لضمان عدم وجود مسافات فارغة في البداية والنهاية
      var user = await _authService.registerParent(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _fullNameController.text.trim(),
      );

      if (mounted) Navigator.pop(context); // إغلاق التحميل

      if (user != null) {
        if (mounted) Navigator.pushNamed(context, '/parent/create-child');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل التسجيل. ربما البريد مستخدم مسبقاً.')),
          );
        }
      }
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
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF511281)),
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF511281).withOpacity(0.1), width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'تسجيل ولي الأمر',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF511281)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'أنشئ حسابك لإدارة ملفات أطفالك',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 28),

                          // ── الاسم الكامل (مع قيد الاسمين) ──
                // ── الاسم الكامل (يدعم العربية والإنجليزية) ──
// ── الاسم الكامل (نسخة محسنة تدعم العربي والإنجليزي) ──
_buildLabel('الاسم الكامل'),
const SizedBox(height: 6),
_buildTextField(
  controller: _fullNameController,
  hint: 'الاسم الأول والعائلة',
  validator: (v) {
    // 1. تنظيف المدخل من المسافات الزائدة
    final val = v?.trim() ?? '';

    if (val.isEmpty) {
      return 'الرجاء إدخال الاسم الكامل';
    }

    // 2. التأكد من وجود اسمين على الأقل (نقسم النص ونتأكد من وجود كلمتين)
    final parts = val.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.length < 2) {
      return 'يرجى إدخال اسمين على الأقل (الأول والعائلة)';
    }

    // 3. التعبير النمطي الشامل (عربي + إنجليزي + مسافات)
    // النطاق \u0600-\u06FF يغطي الحروف العربية كاملة
    final nameRegExp = RegExp(r'^[a-zA-Z\s\u0600-\u06FF]+$');

    if (!nameRegExp.hasMatch(val)) {
      return 'يرجى استخدام الحروف فقط (عربي أو إنجليزي)';
    }

    return null; // كل شيء تمام
  },
),
                          const SizedBox(height: 16),

                          // ── البريد الإلكتروني (مع قيد RegEx) ──
                          _buildLabel('البريد الإلكتروني'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'parent@example.com',
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الرجاء إدخال البريد الإلكتروني';
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(v.trim())) return 'صيغة البريد الإلكتروني غير صحيحة';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── كلمة المرور ──
                          _buildLabel('كلمة المرور'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _passwordController,
                            hint: '••••••••',
                            obscure: !_showPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF511281)),
                              onPressed: () => setState(() => _showPassword = !_showPassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الرجاء إدخال كلمة المرور';
                              if (v.length < 8) return 'يجب أن تكون 8 خانات على الأقل';
                              if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) return 'يجب أن تحتوي على رمز واحد على الأقل (@، #، !)';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── تأكيد كلمة المرور ──
                          _buildLabel('تأكيد كلمة المرور'),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint: '••••••••',
                            obscure: !_showConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF511281)),
                              onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'الرجاء تأكيد كلمة المرور';
                              if (v != _passwordController.text) return 'كلمتا المرور غير متطابقتين';
                              return null;
                            },
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
                              child: const Text('إنشاء حساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('لديك حساب بالفعل؟', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/parent/login'),
                                child: const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(fontSize: 14, color: Color(0xFF511281), fontWeight: FontWeight.w600),
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

  // --- Widgets مساعدة ---
  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)));
  }

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
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: const Color(0xFF511281).withOpacity(0.3), width: 2),
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