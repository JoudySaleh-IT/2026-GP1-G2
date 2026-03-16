import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart'; // تأكدي من صحة المسار لملف الـ Service

// ── القائمة المتاحة للصور الرمزية ──
const _avatars = ['🦁', '🐯', '🐼', '🦊', '🐻', '🐨', '🦝', '🐰'];

class CreateChildProfileScreen extends StatefulWidget {
  const CreateChildProfileScreen({super.key});

  @override
  State<CreateChildProfileScreen> createState() => _CreateChildProfileScreenState();
}

class _CreateChildProfileScreenState extends State<CreateChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  
  // تعريف الـ Service
  final AuthService _authService = AuthService();

  String _gender = '';
  String _selectedAvatar = '';
  bool _genderError = false;
  bool _avatarError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ── منطق الإرسال المحدث ──
  void _handleSubmit() async {
    setState(() {
      _genderError = _gender.isEmpty;
      _avatarError = _selectedAvatar.isEmpty;
    });

    if (_formKey.currentState!.validate() && !_genderError && !_avatarError) {
      // 1. إظهار دائرة تحميل
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF511281))),
      );

      try {
        // 2. استدعاء الدالة من الـ AuthService
        final success = await _authService.createChildProfile(
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text),
          gender: _gender,
          avatar: _selectedAvatar,
        );

        if (mounted) Navigator.pop(context); // إغلاق اللودنق

        if (success && mounted) {
          // 3. الانتقال للداشبورد ومسح الصفحات السابقة
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/parent/dashboard',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); // إغلاق اللودنق
        
        String message = 'حدث خطأ غير متوقع';
        // التحقق من القيد (Exception الذي عرفناه في الـ Service)
        if (e.toString().contains('limit-reached')) {
          message = 'عذراً، يمكنك إضافة طفل واحد فقط في هذه النسخة.';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
            _CreateChildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF511281).withOpacity(0.1), width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // معاينة الصورة المختارة
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: const Color(0xFF511281).withOpacity(0.1), shape: BoxShape.circle),
                            child: _selectedAvatar.isEmpty
                                ? const Icon(Icons.person_add_alt_1_rounded, size: 52, color: Color(0xFF511281))
                                : Text(_selectedAvatar, style: const TextStyle(fontSize: 52)),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── حقل اسم الطفل (يدعم العربي والإنجليزي) ──
const _FieldLabel('اسم الطفل'),
const SizedBox(height: 6),
TextFormField(
  controller: _nameController,
  decoration: _inputDecoration('أدخل اسم الطفل'),
  validator: (v) {
    final val = v?.trim() ?? '';
    if (val.isEmpty) return 'يرجى إدخال اسم الطفل';

    // التعبير النمطي: يسمح بحروف عربي، إنجليزي، ومسافات فقط
    final nameRegExp = RegExp(r'^[a-zA-Z\s\u0600-\u06FF]+$');
    
    if (!nameRegExp.hasMatch(val)) {
      return 'يجب أن يحتوي الاسم على حروف فقط (عربي أو إنجليزي)';
    }
    
    if (val.length < 2) {
      return 'الاسم قصير جداً';
    }
    
    return null;
  },
),
                        const SizedBox(height: 16),

                        const _FieldLabel('العمر'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, _AgeRangeFormatter()],
                          decoration: _inputDecoration('أدخل العمر (٥–١٣)'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'يرجى إدخال العمر';
                            final age = int.tryParse(v);
                            if (age == null || age < 5 || age > 13) return 'العمر يجب أن يكون بين ٥ و ١٣';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        const _FieldLabel('الجنس'),
                        const SizedBox(height: 6),
                        _GenderSelector(
                          selected: _gender,
                          hasError: _genderError,
                          onChanged: (v) => setState(() { _gender = v; _genderError = false; }),
                        ),
                        if (_genderError) const Padding(padding: EdgeInsets.only(top: 4), child: Text('يرجى اختيار الجنس', style: TextStyle(fontSize: 12, color: Colors.red))),
                        const SizedBox(height: 16),

                        const _FieldLabel('اختر الصورة الرمزية'),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                          itemCount: _avatars.length,
                          itemBuilder: (_, i) {
                            final emoji = _avatars[i];
                            final isSelected = _selectedAvatar == emoji;
                            return GestureDetector(
                              onTap: () => setState(() { _selectedAvatar = emoji; _avatarError = false; }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFF6969).withOpacity(0.1) : Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: isSelected ? const Color(0xFFFF6969) : const Color(0xFFDDDDDD), width: 2),
                                ),
                                child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                              ),
                            );
                          },
                        ),
                        if (_avatarError) const Padding(padding: EdgeInsets.only(top: 4), child: Text('يرجى اختيار صورة رمزية', style: TextStyle(fontSize: 12, color: Colors.red))),
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
                            child: const Text('إنشاء الملف'),
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
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: const Color(0xFF511281).withOpacity(0.3), width: 2)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFF6969), width: 2)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 2)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 2)),
  );
}

// ─── المكونات الفرعية (Widgets) ───

class _CreateChildHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF511281), Color(0xFF7A3FA8)]),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
      ),
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 12, right: 16, left: 16),
      child: Row(
        children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إنشاء ملف الطفل', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('أضف طفلاً جديداً إلى حسابك', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF444444)));
}

class _GenderSelector extends StatelessWidget {
  final String selected;
  final bool hasError;
  final ValueChanged<String> onChanged;
  const _GenderSelector({required this.selected, required this.hasError, required this.onChanged});

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
            color: isSelected ? const Color(0xFFFF6969).withOpacity(0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? const Color(0xFFFF6969) : (hasError ? Colors.red : const Color(0xFFDDDDDD)), width: 2),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(icon), const SizedBox(width: 8), Text(label)]),
        ),
      ),
    );
  }
}

class _AgeRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final age = int.tryParse(newValue.text);
    if (age == null || age > 13) return oldValue;
    return newValue;
  }
}