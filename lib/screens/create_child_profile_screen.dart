import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── Available avatars ────────────────────────────────────────────────────────
const _avatars = ['🦁', '🐯', '🐼', '🦊', '🐻', '🐨', '🦝', '🐰'];

// ─── Screen ──────────────────────────────────────────────────────────────────
class CreateChildProfileScreen extends StatefulWidget {
  const CreateChildProfileScreen({super.key});

  @override
  State<CreateChildProfileScreen> createState() =>
      _CreateChildProfileScreenState();
}

class _CreateChildProfileScreenState extends State<CreateChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

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

  void _handleSubmit() {
    setState(() {
      _genderError = _gender.isEmpty;
      _avatarError = _selectedAvatar.isEmpty;
    });

    if (_formKey.currentState!.validate() && !_genderError && !_avatarError) {
      // TODO: Save child profile to backend / state
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/parent/dashboard',
        (route) => false,
      );
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
            // ── Header ──────────────────────────────────────────────
            _CreateChildHeader(),

            // ── Scrollable form ─────────────────────────────────────
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
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
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Avatar preview icon ──────────────────────
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF511281).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: _selectedAvatar.isEmpty
                                  ? const Icon(
                                      Icons.person_add_alt_1_rounded,
                                      size: 52,
                                      color: Color(0xFF511281),
                                    )
                                  : Text(
                                      _selectedAvatar,
                                      style: const TextStyle(fontSize: 52),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Child name ───────────────────────────────
                          _FieldLabel('اسم الطفل'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _nameController,
                            textAlign: TextAlign.right,
                            decoration: _inputDecoration('أدخل اسم الطفل'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'يرجى إدخال اسم الطفل'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // ── Age ──────────────────────────────────────
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
                            decoration: _inputDecoration('أدخل العمر (٥–١٣)'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'يرجى إدخال العمر';
                              }
                              final age = int.tryParse(v);
                              if (age == null || age < 5 || age > 13) {
                                return 'العمر يجب أن يكون بين ٥ و ١٣';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Gender ───────────────────────────────────
                          _FieldLabel('الجنس'),
                          const SizedBox(height: 6),
                          _GenderSelector(
                            selected: _gender,
                            hasError: _genderError,
                            onChanged: (v) => setState(() {
                              _gender = v;
                              _genderError = false;
                            }),
                          ),
                          if (_genderError)
                            const Padding(
                              padding: EdgeInsets.only(top: 6, right: 4),
                              child: Text(
                                'يرجى اختيار الجنس',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),

                          // ── Avatar grid ──────────────────────────────
                          _FieldLabel('اختر الصورة الرمزية'),
                          const SizedBox(height: 8),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 1,
                                ),
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
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_avatarError)
                            const Padding(
                              padding: EdgeInsets.only(top: 6, right: 4),
                              child: Text(
                                'يرجى اختيار صورة رمزية',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFE53935),
                                ),
                              ),
                            ),
                          const SizedBox(height: 28),

                          // ── Submit button ────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6969),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: const Color(
                                  0xFFFF6969,
                                ).withOpacity(0.4),
                                shape: const StadiumBorder(),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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

// ─── Gender Selector ──────────────────────────────────────────────────────────
class _GenderSelector extends StatelessWidget {
  final String selected;
  final bool hasError;
  final ValueChanged<String> onChanged;

  const _GenderSelector({
    required this.selected,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GenderOption(
            label: 'ذكر',
            icon: '👦',
            isSelected: selected == 'boy',
            hasError: hasError,
            onTap: () => onChanged('boy'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GenderOption(
            label: 'أنثى',
            icon: '👧',
            isSelected: selected == 'girl',
            hasError: hasError,
            onTap: () => onChanged('girl'),
          ),
        ),
      ],
    );
  }
}

class _GenderOption extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final bool hasError;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF6969).withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF6969)
                : hasError
                ? const Color(0xFFE53935)
                : const Color(0xFF511281).withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? const Color(0xFFFF6969)
                    : const Color(0xFF444444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _CreateChildHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            child: _HeaderIconBtn(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إنشاء ملف الطفل',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'أضف طفلاً جديداً إلى حسابك',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Age Range Formatter ──────────────────────────────────────────────────────
// Prevents typing values outside 5–13 in real time
class _AgeRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final age = int.tryParse(newValue.text);
    if (age == null || age > 13) return oldValue;
    return newValue;
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
