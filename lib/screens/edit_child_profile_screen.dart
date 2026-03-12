import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Mock Data ────────────────────────────────────────────────────────────────
const _mockChildren = {
  '1': (name: 'أحمد', avatar: '🦁', age: 10, gradeLevel: 'الصف الرابع'),
  '2': (name: 'فاطمة', avatar: '🦊', age: 8, gradeLevel: 'الصف الثاني'),
  '3': (name: 'سارة', avatar: '🐼', age: 12, gradeLevel: 'الصف السادس'),
};

const _availableAvatars = [
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

// ─── Screen ──────────────────────────────────────────────────────────────────
class EditChildProfileScreen extends StatefulWidget {
  final String? childId;
  const EditChildProfileScreen({super.key, this.childId});

  @override
  State<EditChildProfileScreen> createState() => _EditChildProfileScreenState();
}

class _EditChildProfileScreenState extends State<EditChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late final TextEditingController _gradeController;
  late String _selectedAvatar;

  bool _showSuccess = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final child = widget.childId != null ? _mockChildren[widget.childId] : null;

    _nameController = TextEditingController(text: child?.name ?? '');
    _ageController = TextEditingController(
      text: child != null ? '${child.age}' : '',
    );
    _gradeController = TextEditingController(text: child?.gradeLevel ?? '');
    _selectedAvatar = child?.avatar ?? '🦁';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // TODO: persist to backend / state management
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isSaving = false;
      _showSuccess = true;
    });

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // Navigate back to child profile management
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            _EditHeader(childId: widget.childId),

            // ── Scrollable form ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card header
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text(
                          'المعلومات الشخصية',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Divider(indent: 16, endIndent: 16),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Child name ─────────────────────────
                              _FieldLabel('اسم الطفل'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _nameController,
                                textAlign: TextAlign.right,
                                decoration: _inputDecoration('أدخل اسم الطفل'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'يرجى إدخال اسم الطفل'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // ── Age ────────────────────────────────
                              _FieldLabel('العمر'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _ageController,
                                textAlign: TextAlign.right,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  _AgeRangeFormatter(),
                                ],
                                decoration: _inputDecoration('٥ – ١٨'),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'يرجى إدخال العمر';
                                  }
                                  final age = int.tryParse(v);
                                  if (age == null || age < 5 || age > 18) {
                                    return 'العمر يجب أن يكون بين ٥ و ١٨';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Grade level ────────────────────────
                              _FieldLabel('المستوى الدراسي'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _gradeController,
                                textAlign: TextAlign.right,
                                decoration: _inputDecoration(
                                  'مثل: الصف الرابع',
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'يرجى إدخال المستوى الدراسي'
                                    : null,
                              ),
                              const SizedBox(height: 20),

                              // ── Avatar grid ────────────────────────
                              _FieldLabel('اختر صورة رمزية'),
                              const SizedBox(height: 10),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 6,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 1,
                                    ),
                                itemCount: _availableAvatars.length,
                                itemBuilder: (_, i) {
                                  final emoji = _availableAvatars[i];
                                  final isSelected = _selectedAvatar == emoji;
                                  return GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedAvatar = emoji),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(
                                                0xFFFF6969,
                                              ).withOpacity(0.1)
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
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // ── Success message ────────────────────
                              if (_showSuccess) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF7ED),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF4CAF50,
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xFF4CAF50),
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'تم تحديث الملف الشخصي بنجاح!',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // ── Save + Cancel buttons ──────────────
                              Row(
                                children: [
                                  // Save
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isSaving ? null : _handleSave,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFFF6969,
                                        ),
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: const Color(
                                          0xFFFF6969,
                                        ).withOpacity(0.5),
                                        elevation: 3,
                                        shadowColor: const Color(
                                          0xFFFF6969,
                                        ).withOpacity(0.4),
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: _isSaving
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('حفظ التغييرات'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Cancel
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF511281,
                                        ),
                                        side: BorderSide(
                                          color: const Color(
                                            0xFF511281,
                                          ).withOpacity(0.3),
                                          width: 2,
                                        ),
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      child: const Text('إلغاء'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: const Color(0xFF511281).withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: const Color(0xFF511281).withOpacity(0.3),
        width: 2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFFF6969), width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
    ),
  );
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _EditHeader extends StatelessWidget {
  final String? childId;
  const _EditHeader({this.childId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A3A9E), Color(0xFF511281)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_forward, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تعديل ملف الطفل',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
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

// ─── Field Label ──────────────────────────────────────────────────────────────
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

// ─── Age Range Formatter ──────────────────────────────────────────────────────
class _AgeRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final age = int.tryParse(newValue.text);
    if (age == null || age > 18) return oldValue;
    return newValue;
  }
}
