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

  // ── الحالة (State) ──
  String _profileName = '';
  bool _showProfileForm = false;
  String _profileMessage = '';
  bool _isProfileLoading = false;
  late TextEditingController _nameController;

  bool _showPasswordForm = false;
  String _passwordMessage = '';
  bool _isPasswordMessageError = false;
  bool _isPasswordLoading = false;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showNew = false;
  bool _showConfirm = false;

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

  void _loadUserData() async {
    final User? user = _authService.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('parents').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _profileName = doc.data()?['fullName'] ?? 'ولي أمر';
          _nameController.text = _profileName;
        });
      }
    }
  }

  void _handleProfileUpdate() async {
    if (_nameController.text.trim().isEmpty) return;
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

  void _handlePasswordChange() async {
    final newPass = _newPasswordController.text;
    if (newPass != _confirmPasswordController.text) {
      setState(() { _passwordMessage = 'كلمات المرور غير متطابقتين'; _isPasswordMessageError = true; });
      return;
    }
    setState(() => _isPasswordLoading = true);
    try {
      await _authService.currentUser!.updatePassword(newPass);
      setState(() { _passwordMessage = 'تم تغيير كلمة المرور بنجاح!'; _isPasswordMessageError = false; });
      _newPasswordController.clear(); _confirmPasswordController.clear();
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _showPasswordForm = false); });
    } catch (e) {
      setState(() { _isPasswordMessageError = true; _passwordMessage = 'حدث خطأ، حاول مرة أخرى'; });
    } finally {
      if (mounted) setState(() => _isPasswordLoading = false);
    }
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

  // ── الهيدر الجديد (سهم العودة بجانب النص) ──
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_deepPurple, Color(0xFF7A3FA8)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        right: 16,
        left: 16,
      ),
      child: Row(
        children: [
          _HeaderIconBtn(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الإعدادات',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
              ),
              Text(
                'إدارة الحساب والتفضيلات',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Tajawal'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── بطاقة الملف الشخصي (التصميم الأصلي) ──
  Widget _buildProfileCard() {
    return _buildCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _iconCircle(Icons.person_outline),
                  const SizedBox(width: 10),
                  const Text('تعديل الملف الشخصي', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _showProfileForm = !_showProfileForm),
                child: Text(_showProfileForm ? 'إلغاء' : 'تعديل', style: const TextStyle(color: _pink)),
              ),
            ],
          ),
          if (_showProfileForm) ...[
            const Divider(),
            const SizedBox(height: 8),
            const Align(alignment: Alignment.centerRight, child: Text('الاسم الكامل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
            const SizedBox(height: 6),
            TextField(controller: _nameController, textAlign: TextAlign.right, decoration: _inputDecoration('')),
            const SizedBox(height: 12),
            if (_profileMessage.isNotEmpty) _buildMessage(_profileMessage, isError: false),
            const SizedBox(height: 12),
            _buildFullButton('حفظ التغييرات', _handleProfileUpdate, _isProfileLoading),
          ],
        ],
      ),
    );
  }

  // ── بطاقة كلمة المرور (التصميم الأصلي) ──
  Widget _buildPasswordCard() {
    return _buildCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _iconCircle(Icons.lock_outline),
                  const SizedBox(width: 10),
                  const Text('تغيير كلمة المرور', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              TextButton(
                onPressed: () => setState(() => _showPasswordForm = !_showPasswordForm),
                child: Text(_showPasswordForm ? 'إلغاء' : 'تغيير', style: const TextStyle(color: _pink)),
              ),
            ],
          ),
          if (_showPasswordForm) ...[
            const Divider(),
            _passwordField(_newPasswordController, 'كلمة المرور الجديدة', _showNew, () => setState(() => _showNew = !_showNew)),
            const SizedBox(height: 12),
            _passwordField(_confirmPasswordController, 'تأكيد كلمة المرور', _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
            if (_passwordMessage.isNotEmpty) ...[const SizedBox(height: 12), _buildMessage(_passwordMessage, isError: _isPasswordMessageError)],
            const SizedBox(height: 12),
            _buildFullButton('تغيير كلمة المرور', _handlePasswordChange, _isPasswordLoading),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoutCard() {
    return _buildCard(
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
        child: Row(
          children: [
            _iconCircle(Icons.logout_rounded),
            const SizedBox(width: 10),
            const Text('تسجيل الخروج', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _pink)),
          ],
        ),
      ),
    );
  }

  // ── Helpers ──
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)]),
      child: child,
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _pink.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 20, color: _pink));
  }

  Widget _buildFullButton(String label, VoidCallback onTap, bool isLoading) {
    return SizedBox(width: double.infinity, height: 46, child: ElevatedButton(onPressed: isLoading ? null : onTap, style: ElevatedButton.styleFrom(backgroundColor: _pink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(label)));
  }

  Widget _passwordField(TextEditingController controller, String hint, bool show, VoidCallback onToggle) {
    return TextField(
      controller: controller,
      obscureText: !show,
      textAlign: TextAlign.right,
      decoration: _inputDecoration(hint).copyWith(suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 20), onPressed: onToggle)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(hintText: hint, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _pink, width: 2)));
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