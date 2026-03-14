import 'package:flutter/material.dart';

class ParentSettingsScreen extends StatefulWidget {
  const ParentSettingsScreen({super.key});

  @override
  State<ParentSettingsScreen> createState() => _ParentSettingsScreenState();
}

class _ParentSettingsScreenState extends State<ParentSettingsScreen> {
  // ── Profile state ──────────────────────────────────────────────────────
  String _profileName = 'أحمد محمد';
  bool _showProfileForm = false;
  String _profileMessage = '';
  late TextEditingController _nameController;

  // ── Password state ─────────────────────────────────────────────────────
  bool _showPasswordForm = false;
  String _passwordMessage = '';
  bool _isPasswordMessageError = false;
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ── Visibility toggles ─────────────────────────────────────────────────
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  static const _pink = Color(0xFFFF6969);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _profileName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ── Profile update ─────────────────────────────────────────────────────
  void _handleProfileUpdate() {
    setState(() {
      _profileName = _nameController.text;
      _profileMessage = 'تم تحديث الملف الشخصي بنجاح!';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _profileMessage = '';
          _showProfileForm = false;
        });
      }
    });
  }

  // ── Password change ────────────────────────────────────────────────────
  void _handlePasswordChange() {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (newPass != confirmPass) {
      setState(() {
        _passwordMessage = 'كلمات المرور غير متطابقة';
        _isPasswordMessageError = true;
      });
      return;
    }
    if (newPass.length < 6) {
      setState(() {
        _passwordMessage = 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
        _isPasswordMessageError = true;
      });
      return;
    }

    setState(() {
      _passwordMessage = 'تم تغيير كلمة المرور بنجاح!';
      _isPasswordMessageError = false;
    });
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _passwordMessage = '';
          _showPasswordForm = false;
        });
      }
    });
  }

  // ── Logout dialog ──────────────────────────────────────────────────────
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'تأكيد تسجيل الخروج',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'هل أنت متأكد أنك تريد تسجيل الخروج من حسابك؟',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
        backgroundColor: const Color(0xFFF3F4F6),
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 12),
                      _buildPasswordCard(),
                      const SizedBox(height: 12),
                      _buildLogoutCard(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              _HeaderIconBtn(
                icon: Icons.arrow_back,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإعدادات',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'إدارة الحساب والتفضيلات',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile card ───────────────────────────────────────────────────────
  Widget _buildProfileCard() {
    return _buildCard(
      child: Column(
        children: [
          // Card header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _iconCircle(Icons.person_outline),
                  const SizedBox(width: 10),
                  const Text(
                    'تعديل الملف الشخصي',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _showProfileForm = !_showProfileForm),
                child: Text(
                  _showProfileForm ? 'إلغاء' : 'تعديل',
                  style: const TextStyle(color: _pink, fontSize: 13),
                ),
              ),
            ],
          ),

          // Expandable form
          if (_showProfileForm) ...[
            const Divider(height: 16),
            const SizedBox(height: 4),

            // Avatar row
            Row(
              children: [
                // Avatar circle
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey.shade200,
                  child: const Icon(Icons.person, size: 36, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                // Upload button (placeholder — real file picking needs image_picker package)
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Add image_picker package for real image upload
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'يحتاج رفع الصور إلى إضافة image_picker في pubspec.yaml',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.upload, size: 16, color: _pink),
                  label: const Text(
                    'رفع صورة',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Name field
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الاسم',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              textAlign: TextAlign.right,
              decoration: _inputDecoration(''),
            ),

            const SizedBox(height: 12),

            // Success message
            if (_profileMessage.isNotEmpty)
              _buildMessage(_profileMessage, isError: false),

            const SizedBox(height: 12),

            // Save button
            _buildFullButton('حفظ التغييرات', _handleProfileUpdate),
          ],
        ],
      ),
    );
  }

  // ── Password card ──────────────────────────────────────────────────────
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
                  const Text(
                    'تغيير كلمة المرور',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              TextButton(
                onPressed: () =>
                    setState(() => _showPasswordForm = !_showPasswordForm),
                child: Text(
                  _showPasswordForm ? 'إلغاء' : 'تغيير',
                  style: const TextStyle(color: _pink, fontSize: 13),
                ),
              ),
            ],
          ),

          if (_showPasswordForm) ...[
            const Divider(height: 16),
            const SizedBox(height: 4),

            _passwordField(
              controller: _currentPasswordController,
              hint: 'كلمة المرور الحالية',
              show: _showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: _newPasswordController,
              hint: 'كلمة المرور الجديدة',
              show: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 12),
            _passwordField(
              controller: _confirmPasswordController,
              hint: 'تأكيد كلمة المرور',
              show: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
            ),

            if (_passwordMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMessage(_passwordMessage, isError: _isPasswordMessageError),
            ],

            const SizedBox(height: 12),
            _buildFullButton('تغيير كلمة المرور', _handlePasswordChange),
          ],
        ],
      ),
    );
  }

  // ── Logout card ────────────────────────────────────────────────────────
  Widget _buildLogoutCard() {
    return _buildCard(
      child: InkWell(
        onTap: _showLogoutDialog,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            _iconCircle(Icons.logout_rounded),
            const SizedBox(width: 10),
            const Text(
              'تسجيل الخروج',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _pink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reusable helpers ───────────────────────────────────────────────────
  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _iconCircle(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _pink.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: _pink),
    );
  }

  Widget _buildFullButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _pink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: !show,
      textAlign: TextAlign.right,
      decoration: _inputDecoration(hint).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            show ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _pink, width: 2),
      ),
    );
  }

  Widget _buildMessage(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: isError ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isError ? Colors.red : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 34,
      height: 34,
      child: Icon(icon, color: Colors.white, size: 25),
    ),
  );
}
