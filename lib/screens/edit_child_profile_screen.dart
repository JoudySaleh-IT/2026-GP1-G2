import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; // تأكدي من مسار الملف

class EditChildProfileScreen extends StatefulWidget {
  final String childId; // نمرر الـ ID الخاص بالطفل من صفحة الداشبورد
  const EditChildProfileScreen({super.key, required this.childId});

  @override
  State<EditChildProfileScreen> createState() => _EditChildProfileScreenState();
}

class _EditChildProfileScreenState extends State<EditChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // المتحكمات
  late final TextEditingController _nameController = TextEditingController();
  late final TextEditingController _ageController = TextEditingController();
  late final TextEditingController _gradeController = TextEditingController();

  String _selectedAvatar = '🦁';
  bool _isSaving = false;
  bool _showSuccess = false;
  bool _isLoadingData = true; // لتحميل البيانات لأول مرة

  final List<String> _availableAvatars = [
    '🦁',
    '🦊',
    '🐼',
    '🐨',
    '🦋',
    '🚀',
    '🌸',
    '⭐',
    '🎨',
    '🎯',
    '🏆',
    '🎭',
  ];

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

  // ── جلب بيانات الطفل الحالية من Firestore ──
  Future<void> _loadChildData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _gradeController.text = data['gradeLevel'] ?? '';
          _selectedAvatar = data['avatar'] ?? '🦁';
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading child data: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('خطأ في تحميل البيانات')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  // ── حفظ التغييرات في Firestore ──
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _authService.updateChildProfile(
        childId: widget.childId,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        gradeLevel: _gradeController.text.trim(),
        avatar: _selectedAvatar,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _showSuccess = true;
        });

        // العودة للداشبورد بعد ثانية ونصف
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل التحديث، حاول مرة أخرى')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: _isLoadingData
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF511281)),
              )
            : Column(
                children: [
                  _EditHeader(onBack: () => Navigator.pop(context)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF511281).withOpacity(0.1),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'المعلومات الشخصية',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF222222),
                                ),
                              ),
                              const Divider(height: 24),

                              _FieldLabel('اسم الطفل'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                decoration: _inputDecoration('أدخل اسم الطفل'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'يرجى إدخال اسم الطفل'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              _FieldLabel('العمر'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _ageController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: _inputDecoration('٥ – ١٨'),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'يرجى إدخال العمر';
                                  final age = int.tryParse(v);
                                  if (age == null || age < 5 || age > 18)
                                    return 'العمر بين ٥ و ١٨';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              _FieldLabel('اختر صورة رمزية'),
                              const SizedBox(height: 10),
                              _buildAvatarGrid(),
                              const SizedBox(height: 20),

                              if (_showSuccess) _buildSuccessBanner(),
                              const SizedBox(height: 12),

                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- Widgets مساعدة ---

  Widget _buildAvatarGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _availableAvatars.length,
      itemBuilder: (_, i) {
        final emoji = _availableAvatars[i];
        final isSelected = _selectedAvatar == emoji;
        return GestureDetector(
          onTap: () => setState(() => _selectedAvatar = emoji),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFF6969).withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF6969)
                    : const Color(0xFFDDDDDD),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7ED),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: Color(0xFF4CAF50), size: 18),
          SizedBox(width: 8),
          Text(
            'تم تحديث الملف الشخصي بنجاح!',
            style: TextStyle(color: Color(0xFF2E7D32), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _handleSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6969),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('حفظ التغييرات'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF511281),
              side: const BorderSide(color: Color(0xFF511281), width: 2),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('إلغاء'),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: const Color(0xFF511281).withOpacity(0.2),
        width: 2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFFF6969), width: 2),
    ),
  );
}

// مكونات الهيدر والعناوين
class _EditHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _EditHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        right: 16,
        left: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تعديل ملف الطفل',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'تحديث المعلومات الشخصية',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFF444444),
    ),
  );
}
