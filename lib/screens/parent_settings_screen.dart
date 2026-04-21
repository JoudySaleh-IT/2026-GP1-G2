import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  final AuthService _authService = AuthService();
  
  // ── المفاتيح (Keys) للتحقق من المداخل ──
  final _profileFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  // ── الحالة (State) للملف الشخصي ──
  String _profileName = '';
  bool _showProfileForm = false;
  String _profileMessage = '';
  bool _isProfileLoading = false;
  late TextEditingController _nameController;

  // ── الحالة (State) لكلمة المرور ──
  bool _showPasswordForm = false;
  String _passwordMessage = '';
  bool _isPasswordMessageError = false;
  bool _isPasswordLoading = false;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showNew = false;
  bool _showConfirm = false;

  // ── الألوان الموحدة (نفس الريجستر ولوحة التحكم) ──
  static const _pink = Color(0xFFFF6969);
  static const _deepPurple = Color(0xFF511281);
  static const _bgColor = Color(0xFFFCF9EA);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── جلب بيانات ولي الأمر من كوليكشن parents ──
  void _loadUserData() async {
    final User? user = _authService.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('parents')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _profileName = doc.data()?['fullName'] ?? 'ولي أمر';
          _nameController.text = _profileName;
        });
      }
    }
  }

  // ── تحديث الاسم (مع قيود الاسم الكامل) ──
  void _handleProfileUpdate() async {
    if (_profileFormKey.currentState!.validate()) {
      setState(() => _isProfileLoading = true);
      try {
        final String? uid = _authService.currentUser?.uid;
        await FirebaseFirestore.instance.collection('parents').doc(uid).update({
          'fullName': _nameController.text.trim(),
        });
        setState(() {
          _profileName = _nameController.text.trim();
          _profileMessage = 'تم تحديث الاسم بنجاح!';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showProfileForm = false);
        });
      } catch (e) {
        setState(() => _profileMessage = 'فشل التحديث: تأكد من اتصالك بالإنترنت');
      } finally {
        if (mounted) setState(() => _isProfileLoading = false);
      }
    }
  }

  // ── تغيير كلمة المرور (مع قيود التسجيل الصارمة) ──
  void _handlePasswordChange() async {
    if (_passwordFormKey.currentState!.validate()) {
      setState(() => _isPasswordLoading = true);
      try {
        await _authService.currentUser!.updatePassword(_newPasswordController.text.trim());
        setState(() {
          _passwordMessage = 'تم تغيير كلمة المرور بنجاح!';
          _isPasswordMessageError = false;
        });
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _showPasswordForm = false);
        });
      } on FirebaseAuthException catch (e) {
        setState(() {
          _isPasswordMessageError = true;
          _passwordMessage = e.code == 'requires-recent-login'
              ? 'يرجى إعادة تسجيل الدخول لتغيير كلمة المرور'
              : 'حدث خطأ، حاول مرة أخرى لاحقاً';
        });
      } finally {
        if (mounted) setState(() => _isPasswordLoading = false);
      }
    }
  }

  // ── نافذة تأكيد تسجيل الخروج ──
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('تأكيد تسجيل الخروج', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                await _authService.signOut();
                if (ctx.mounted) {
                  Navigator.of(ctx, rootNavigator: true).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _pink, foregroundColor: Colors.white),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileCard(),
                    const SizedBox(height: 12),
                    _buildPasswordCard(),
                    const SizedBox(height: 12),
                    _buildLogoutCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── الهيدر الرشيق (نفس ستايل اختيار الطفل) ──
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_deepPurple, Color(0xFF7A3FA8)], begin: Alignment.centerRight, end: Alignment.centerLeft),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12, right: 16, left: 16),
      child: Row(
        children: [
          _HeaderIconBtn(icon: Icons.arrow_back, onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('الإعدادات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
              Text('إدارة الحساب والتفضيلات', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Tajawal')),
            ],
          ),
        ],
      ),
    );
  }

  // ── بطاقة تعديل الاسم ──
  Widget _buildProfileCard() {
    return _buildCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [_iconCircle(Icons.person_outline), const SizedBox(width: 10), const Text('تعديل الملف الشخصي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]),
              TextButton(onPressed: () => setState(() => _showProfileForm = !_showProfileForm), child: Text(_showProfileForm ? 'إلغاء' : 'تعديل', style: const TextStyle(color: _pink))),
            ],
          ),
          if (_showProfileForm) ...[
            const Divider(),
            Form(
              key: _profileFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('الاسم الكامل الجديد', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    textAlign: TextAlign.right,
                    decoration: _inputDecoration(''),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'الرجاء إدخال الاسم';
                      if (val.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length < 2) return 'يرجى إدخال اسمين على الأقل';
                      if (!RegExp(r'^[a-zA-Z\s\u0600-\u06FF]+$').hasMatch(val)) return 'الحروف فقط مسموحة (عربي/إنجليزي)';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (_profileMessage.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: _buildMessage(_profileMessage, isError: false)),
            const SizedBox(height: 12),
            _buildFullButton('حفظ التغييرات', _handleProfileUpdate, _isProfileLoading),
          ],
        ],
      ),
    );
  }

  // ── بطاقة كلمة المرور (نظام التحقق الأحمر) ──
  Widget _buildPasswordCard() {
    return _buildCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [_iconCircle(Icons.lock_outline), const SizedBox(width: 10), const Text('تغيير كلمة المرور', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))]),
              TextButton(onPressed: () => setState(() => _showPasswordForm = !_showPasswordForm), child: Text(_showPasswordForm ? 'إلغاء' : 'تغيير', style: const TextStyle(color: _pink))),
            ],
          ),
          if (_showPasswordForm) ...[
            const Divider(),
            Form(
              key: _passwordFormKey,
              child: Column(
                children: [
                  _buildPasswordFormField(
                    controller: _newPasswordController,
                    hint: 'كلمة المرور الجديدة',
                    show: _showNew,
                    onToggle: () => setState(() => _showNew = !_showNew),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'الرجاء إدخال كلمة المرور';
                      List<String> reqs = [];
                      if (v.length < 8) reqs.add('• ٨ خانات على الأقل');
                      if (!RegExp(r'[A-Z]').hasMatch(v)) reqs.add('• حرف كبير واحد (A-Z)');
                      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) reqs.add('• رمز خاص واحد (@، #، !)');
                      if (reqs.isNotEmpty) return 'المطلوب:\n${reqs.join('\n')}';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPasswordFormField(
                    controller: _confirmPasswordController,
                    hint: 'تأكيد كلمة المرور',
                    show: _showConfirm,
                    onToggle: () => setState(() => _showConfirm = !_showConfirm),
                    validator: (v) {
                      if (v != _newPasswordController.text) return 'كلمتا المرور غير متطابقتين';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            if (_passwordMessage.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: _buildMessage(_passwordMessage, isError: _isPasswordMessageError)),
            const SizedBox(height: 16),
            _buildFullButton('تغيير كلمة المرور', _handlePasswordChange, _isPasswordLoading),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return _buildCard(
      child: InkWell(onTap: _showLogoutDialog, child: Row(children: [_iconCircle(Icons.logout_rounded), const SizedBox(width: 10), const Text('تسجيل الخروج  ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _pink))])),
    );
  }

  // ── المكونات المساعدة (Helpers) ──
  Widget _buildCard({required Widget child}) {
    return Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]), child: child);
  }

  Widget _iconCircle(IconData icon) {
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _pink.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 20, color: _pink));
  }

  Widget _buildFullButton(String label, VoidCallback onTap, bool isLoading) {
    return SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: isLoading ? null : onTap, style: ElevatedButton.styleFrom(backgroundColor: _pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(label)));
  }

  Widget _buildPasswordFormField({required TextEditingController controller, required String hint, required bool show, required VoidCallback onToggle, required String? Function(String?)? validator}) {
    return TextFormField(controller: controller, obscureText: !show, textAlign: TextAlign.right, validator: validator, decoration: _inputDecoration(hint).copyWith(suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20), onPressed: onToggle)));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _pink, width: 2)), errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)), focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 2)));
  }

  Widget _buildMessage(String message, {required bool isError}) {
    return Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isError ? Colors.red.shade50 : Colors.green.shade50, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? Colors.red : Colors.green, size: 18), const SizedBox(width: 8), Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: isError ? Colors.red : Colors.green.shade700)))]));
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(8), child: SizedBox(width: 34, height: 34, child: Icon(icon, color: Colors.white, size: 25)));
}