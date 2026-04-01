import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// ── القائمة المتاحة للصور الرمزية ──
const _avatars = ['🦁', '🐯', '🐼', '🦊', '🐻', '🐨', '🦝', '🐰'];

// ── حساب العمر من تاريخ الميلاد ──
int _calcAge(DateTime dob) {
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month ||
      (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}

class CreateChildProfileScreen extends StatefulWidget {
  const CreateChildProfileScreen({super.key});

  @override
  State<CreateChildProfileScreen> createState() =>
      _CreateChildProfileScreenState();
}

class _CreateChildProfileScreenState extends State<CreateChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  final AuthService _authService = AuthService();

  DateTime? _dob;
  String _gender = '';
  String _selectedAvatar = '';
  bool _genderError = false;
  bool _avatarError = false;
  bool _dobError = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    setState(() {
      _genderError = _gender.isEmpty;
      _avatarError = _selectedAvatar.isEmpty;
      _dobError = _dob == null;
    });

    if (_formKey.currentState!.validate() &&
        !_genderError &&
        !_avatarError &&
        !_dobError) {
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF511281))),
      );

      try {
        final age = _calcAge(_dob!);
        final success = await _authService.createChildProfile(
          name: _nameController.text.trim(),
          age: age,
          dob: _dob!,
          gender: _gender,
          avatar: _selectedAvatar,
        );

        if (mounted) Navigator.pop(context); // إغلاق لودينج

        if (success && mounted) {
          Navigator.pushNamedAndRemoveUntil(
              context, '/parent/dashboard', (route) => false);
        }
      } catch (e) {
        if (mounted) Navigator.pop(context);
        String message = 'حدث خطأ أثناء حفظ البيانات، يرجى المحاولة لاحقاً';
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
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
        body: Column(
          children: [
            const _CreateChildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF511281).withOpacity(0.1),
                        width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 8,
                          offset: Offset(0, 2))
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                                color: const Color(0xFF511281).withOpacity(0.1),
                                shape: BoxShape.circle),
                            child: _selectedAvatar.isEmpty
                                ? const Icon(Icons.person_add_alt_1_rounded,
                                    size: 52, color: Color(0xFF511281))
                                : Text(_selectedAvatar,
                                    style: const TextStyle(fontSize: 52)),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const _FieldLabel('اسم الطفل'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('أدخل اسم الطفل'),
                          validator: (v) {
                            final val = v?.trim() ?? '';
                            if (val.isEmpty) return 'يرجى إدخال اسم الطفل';
                            final nameRegExp =
                                RegExp(r'^[a-zA-Z\s\u0600-\u06FF]+$');
                            if (!nameRegExp.hasMatch(val)) {
                              return 'يجب أن يحتوي الاسم على حروف فقط';
                            }
                            if (val.length < 2) return 'الاسم قصير جداً';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const _FieldLabel('تاريخ الميلاد'),
                        const SizedBox(height: 6),
                        _DobPicker(
                          selectedDate: _dob,
                          hasError: _dobError,
                          onChanged: (date) =>
                              setState(() {
                                _dob = date;
                                _dobError = false;
                              }),
                        ),
                        if (_dobError)
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: 4),
                            child: Text('يرجى اختيار تاريخ الميلاد',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red)),
                          ),
                        if (_dob != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, right: 4),
                            child: Text(
                              'العمر: ${_calcAge(_dob!)} سنة',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF511281),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        const _FieldLabel('الجنس'),
                        const SizedBox(height: 6),
                        _GenderSelector(
                          selected: _gender,
                          hasError: _genderError,
                          onChanged: (v) => setState(
                              () {
                                _gender = v;
                                _genderError = false;
                              }),
                        ),
                        if (_genderError)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('يرجى اختيار الجنس',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red)),
                          ),
                        const SizedBox(height: 16),
                        const _FieldLabel('اختر الصورة الرمزية'),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10),
                          itemCount: _avatars.length,
                          itemBuilder: (_, i) {
                            final emoji = _avatars[i];
                            final isSelected = _selectedAvatar == emoji;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _selectedAvatar = emoji;
                                _avatarError = false;
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFFF6969).withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFF6969)
                                          : const Color(0xFFDDDDDD),
                                      width: 2),
                                ),
                                child: Center(
                                    child: Text(emoji,
                                        style:
                                            const TextStyle(fontSize: 28))),
                              ),
                            );
                          },
                        ),
                        if (_avatarError)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('يرجى اختيار صورة رمزية',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red)),
                          ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6969),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                            ),
                            child: const Text('إنشاء الملف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: const Color(0xFF511281).withOpacity(0.3), width: 2)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: Color(0xFFFF6969), width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
      );
}

// ─── DOB Picker ───
class _DobPicker extends StatelessWidget {
  final DateTime? selectedDate;
  final bool hasError;
  final ValueChanged<DateTime> onChanged;

  const _DobPicker({
    required this.selectedDate,
    required this.hasError,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(now.year - 8),
      firstDate: DateTime(now.year - 13),
      lastDate: DateTime(now.year - 5),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = selectedDate != null;
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasError
                ? Colors.red
                : hasDate
                    ? const Color(0xFFFF6969)
                    : const Color(0xFF511281).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: hasError ? Colors.red : const Color(0xFF511281),
                size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasDate
                    ? '${selectedDate!.year}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.day.toString().padLeft(2, '0')}'
                    : 'اختر تاريخ الميلاد',
                style: TextStyle(
                  fontSize: 14,
                  color: hasDate ? const Color(0xFF1A1A1A) : Colors.grey,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                color: hasError ? Colors.red : const Color(0xFF511281)),
          ],
        ),
      ),
    );
  }
}

// ─── Header (تم تعديله ليتطابق مع باقي الصفحات) ───
class _CreateChildHeader extends StatelessWidget {
  const _CreateChildHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [Color(0xFF511281), Color(0xFF7A3FA8)]),
        boxShadow: [
          BoxShadow(
              color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8,
          bottom: 12,
          right: 16,
          left: 16),
      child: Row(
        children: [
          // ✅ تم تغيير الزر ليطابق صفحة المانجمنت وبدون خلفية بيضاء
          _HeaderIconBtn(
            icon: Icons.arrow_back, 
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إنشاء ملف الطفل',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              Text('أضف طفلاً جديداً إلى حسابك',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── زر الأيقونة المخصص (بدون خلفية كما طلبتِ) ───
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

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF444444)));
}

class _GenderSelector extends StatelessWidget {
  final String selected;
  final bool hasError;
  final ValueChanged<String> onChanged;
  const _GenderSelector(
      {required this.selected,
      required this.hasError,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _option('ذكر', 'boy', '👦'),
        const SizedBox(width: 12),
        _option('أنثى', 'girl', '👧'),
      ],
    );
  }

  Widget _option(String label, String value, String icon) {
    final bool isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFF6969).withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFFFF6969)
                    : (hasError ? Colors.red : const Color(0xFFDDDDDD)),
                width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon),
              const SizedBox(width: 8),
              Text(label)
            ],
          ),
        ),
      ),
    );
  }
}