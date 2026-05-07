import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'style_constants.dart';

// ── حساب العمر من تاريخ الميلاد ──
int _calcAge(DateTime dob) {
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}

class EditChildProfileScreen extends StatefulWidget {
  final String childId;
  const EditChildProfileScreen({super.key, required this.childId});

  @override
  State<EditChildProfileScreen> createState() => _EditChildProfileScreenState();
}

class _EditChildProfileScreenState extends State<EditChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late final TextEditingController _nameController = TextEditingController();

  String _selectedAvatar = '🦁';
  DateTime? _dob;
  bool _dobError = false;

  // ── متغيرات التحكم في ثبات اللون الأحمر ──
  bool _isNameActive = false; // هل تم لمس أو تعديل حقل الاسم؟
  bool _isDobActive = false; // هل تم لمس أو تعديل حقل التاريخ؟

  bool _isSaving = false;
  bool _isLoadingData = true;

  final List<String> _availableAvatars = [
    '🦁',
    '🐯',
    '🐼',
    '🦊',
    '🐻',
    '🐨',
    '🦝',
    '🐰',
  ];

  @override
  void initState() {
    super.initState();
    _loadChildData();
  }

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
          _selectedAvatar = data['avatar'] ?? '🦁';
          if (data['dob'] != null) {
            _dob = (data['dob'] as Timestamp).toDate();
          }
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // You can also change this one to your new NotificationService if you want!
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('خطأ في تحميل البيانات')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _dobError = _dob == null);
    if (!_formKey.currentState!.validate() || _dob == null) return;

    setState(() => _isSaving = true);
    try {
      final age = _calcAge(_dob!);
      await _authService.updateChildProfile(
        childId: widget.childId,
        name: _nameController.text.trim(),
        age: age,
        avatar: _selectedAvatar,
        dob: _dob!,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isNameActive = false;
          _isDobActive = false;
        });

        // 1. Show the global snackbar
        NotificationService.showSuccessSnackBar(
          'تم تحديث ملف الطفل الشخصي بنجاح!',
        );

        // 2. Immediately pop back to the previous screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
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
                                ),
                              ),
                              const Divider(height: 24),

                              // ── حقل اسم الطفل ──
                              const _FieldLabel('اسم الطفل'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                // تفعيل اللون الأحمر عند البدء بالكتابة أو اللمس
                                onChanged: (v) =>
                                    setState(() => _isNameActive = true),
                                onTap: () =>
                                    setState(() => _isNameActive = true),
                                decoration: _inputDecoration(
                                  'أدخل اسم الطفل',
                                  _isNameActive,
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'يرجى إدخال اسم الطفل'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // ── حقل تاريخ الميلاد ──
                              const _FieldLabel('تاريخ الميلاد'),
                              const SizedBox(height: 6),
                              _DobPicker(
                                selectedDate: _dob,
                                isActive: _isDobActive || _dobError,
                                onTap: () =>
                                    setState(() => _isDobActive = true),
                                onChanged: (date) => setState(() {
                                  _dob = date;
                                  _dobError = false;
                                  _isDobActive = true;
                                }),
                              ),
                              const SizedBox(height: 16),

                              const _FieldLabel('اختر صورة رمزية'),
                              const SizedBox(height: 10),
                              _buildAvatarGrid(),
                              const SizedBox(height: 20),
                              // Removed the inline success banner from here
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

  // تعديل الـ Decoration ليدعم اللون الأحمر الثابت
  InputDecoration _inputDecoration(String hint, bool isActive) {
    // اللون يكون أحمر إذا كان الحقل نشطاً، وإلا بنفسجي شفاف
    final Color currentColor = isActive
        ? const Color(0xFFFF6969)
        : const Color(0xFF511281).withOpacity(0.2);

    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      // الحدود العادية (تتغير للأحمر إذا صار isActive)
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: currentColor, width: 2),
      ),
      // الحدود وقت التركيز
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF6969), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

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
}

// ─── DOB Picker المطور ───
class _DobPicker extends StatelessWidget {
  final DateTime? selectedDate;
  final bool isActive;
  final ValueChanged<DateTime> onChanged;
  final VoidCallback onTap;

  const _DobPicker({
    required this.selectedDate,
    required this.isActive,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;
    // اللون أحمر إذا كان isActive، وإلا بنفسجي شفاف
    final Color currentColor = isActive
        ? const Color(0xFFFF6969)
        : const Color(0xFF511281).withOpacity(0.2);

    return GestureDetector(
      onTap: () async {
        onTap();
        final picked = await showDatePicker(
          context: context,
          initialDate:
              selectedDate ??
              DateTime.now().subtract(const Duration(days: 365 * 8)),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: currentColor, width: 2),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: isActive
                  ? const Color(0xFFFF6969)
                  : const Color(0xFF511281),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasDate
                    ? "${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}"
                    : 'اختر تاريخ الميلاد',
                style: TextStyle(
                  fontSize: 14,
                  color: hasDate ? Colors.black : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _EditHeader({required this.onBack});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 8,
      bottom: 12,
      right: 16,
      left: 16,
    ),
    decoration: FaseehStyle.headerDecoration,
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: onBack,
        ),
        const Text(
          'تعديل ملف الطفل',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
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
