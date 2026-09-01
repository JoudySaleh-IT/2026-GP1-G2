import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'my_friend_qr_screen.dart';
import 'scan_friend_qr_screen.dart';
import '../services/friend_service.dart';
import 'style_constants.dart';

class AddFriendScreen extends StatefulWidget {
  final String childId;

  const AddFriendScreen({
    super.key,
    required this.childId,
  });

  @override
  State<AddFriendScreen> createState() =>
      _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  String _enteredFasehId = '';
  bool _loading = false;

  // ─────────────────────────────────────────────
  // Standard App SnackBar
  // ─────────────────────────────────────────────
  void _showAppSnackBar(
    String message, {
    Color backgroundColor = _purple,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.fixed,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              message,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Send Friend Request Using Faseh ID
  // ─────────────────────────────────────────────
  Future<void> _sendFriendRequest() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    try {
      await FriendService().sendFriendRequestByFasehId(
        currentChildId: widget.childId,
        enteredFasehId: _enteredFasehId,
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showAppSnackBar(
        'تم إرسال طلب الصداقة بنجاح 🎉',
      );
    }

    // Firestore errors
    on FirebaseException catch (e) {
      if (!mounted) return;

      String message =
          'تعذّر إرسال طلب الصداقة، حاول مرة أخرى';

      if (e.code == 'permission-denied') {
        message =
            'تم إرسال طلب صداقة لهذا الطفل مسبقًا أو أنكما أصدقاء بالفعل';
      }

      setState(() {
        _loading = false;
      });

      _showAppSnackBar(
        message,
        backgroundColor: _coral,
      );
    }

    // FriendService custom errors
    catch (e) {
      if (!mounted) return;

      final String error = e.toString();

      String message =
          'تعذّر إرسال طلب الصداقة، حاول مرة أخرى';

      if (error.contains('CANNOT_ADD_SELF')) {
        message = 'لا يمكنك إضافة نفسك كصديق';
      } else if (error.contains('FASEH_ID_NOT_FOUND')) {
        message = 'لم يتم العثور على طفل بهذا المعرّف';
      } else if (error.contains('INVALID_FASEH_ID')) {
        message = 'يرجى إدخال معرّف فصيح صحيح';
      } else if (error.contains('NOT_AUTHENTICATED')) {
        message = 'يجب تسجيل الدخول أولًا';
      } else if (error.contains('PUBLIC_PROFILE_NOT_FOUND')) {
        message = 'تعذّر العثور على ملف الطفل';
      }

      setState(() {
        _loading = false;
      });

      _showAppSnackBar(
        message,
        backgroundColor: _coral,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,

        body: Column(
          children: [
            // ─────────────────────────────────────────
            // Header
            // نفس ترتيب هيدر مستويات الحرف
            // رجوع ← أيقونة الصفحة ← النص
            // ─────────────────────────────────────────
            const _AddFriendHeader(),

            // ─────────────────────────────────────────
            // Body
            // ─────────────────────────────────────────
            Expanded(
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      // ─────────────────────────────────────
                      // Introduction
                      // ─────────────────────────────────────
                      const Text(
                        'أضف صديقك وتمرّنوا معًا!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _purple,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'استخدم رمز QR لإضافة صديق بسرعة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontFamily: 'Tajawal',
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ─────────────────────────────────────
                      // Scan Friend QR
                      // PRIMARY METHOD
                      // ─────────────────────────────────────
                      _AddFriendOption(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'مسح رمز QR',
                        subtitle:
                            'امسح رمز صديقك لإرسال طلب صداقة',
                        color: _coral,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ScanFriendQrScreen(
                                childId: widget.childId,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      // ─────────────────────────────────────
                      // Show My QR
                      // ─────────────────────────────────────
                      _AddFriendOption(
                        icon: Icons.qr_code_2_rounded,
                        title: 'رمزي الخاص',
                        subtitle:
                            'اعرض رمزك ليقوم صديقك بمسحه',
                        color: _purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MyFriendQrScreen(
                                childId: widget.childId,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 30),

                      // ─────────────────────────────────────
                      // OR Divider
                      // ─────────────────────────────────────
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            child: Text(
                              'أو',
                              style: TextStyle(
                                color: Colors.grey,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ─────────────────────────────────────
                      // Faseh ID Fallback
                      // ─────────────────────────────────────
                      const Text(
                        'إضافة بواسطة معرّف فصيح',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _purple,
                          fontFamily: 'Tajawal',
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        enabled: !_loading,
                        textDirection: TextDirection.ltr,
                        textCapitalization:
                            TextCapitalization.characters,
                        onChanged: (value) {
                          setState(() {
                            _enteredFasehId = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'FSH-XXXX-XXXX',
                          prefixIcon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: _purple,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _purple.withOpacity(0.15),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: _purple,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // ─────────────────────────────────────
                      // Send Request Button
                      // ─────────────────────────────────────
                      ElevatedButton(
                        onPressed:
                            _loading ? null : _sendFriendRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _coral,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              _coral.withOpacity(0.6),
                          disabledForegroundColor:
                              Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'إرسال طلب صداقة',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight.bold,
                                  fontFamily: 'Tajawal',
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
}

// ─────────────────────────────────────────────
// Add Friend Header
// نفس ترتيب وشكل LetterLevelsHeader
// ─────────────────────────────────────────────
class _AddFriendHeader extends StatelessWidget {
  const _AddFriendHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: FaseehStyle.headerDecoration,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16,
        right: 16,
        left: 16,
      ),
      child: Row(
        children: [
          // ─────────────────────────────────
          // Back Button
          // نفس المستخدم في LetterLevelsScreen
          // في RTL يظهر باتجاه اليمين
          // ─────────────────────────────────
          _HeaderIconBtn(
            icon: Icons.arrow_back,
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const SizedBox(width: 12),

          // ─────────────────────────────────
          // Page Icon
          // بنفس مكان حرف "ق" في صفحة المستويات
          // ─────────────────────────────────
          const SizedBox(
  width: 48,
  height: 48,
  child: Center(
    child: Icon(
      Icons.person_add_alt_1_rounded,
      color: Colors.white,
      size: 30,
    ),
  ),
),

          const SizedBox(width: 12),

          // ─────────────────────────────────
          // Title + Subtitle
          // ─────────────────────────────────
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إضافة صديق',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'أضف صديقًا جديدًا إلى قائمتك',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Header Icon Button
// نفس منطق LetterLevelsScreen
// ─────────────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(
          icon,
          color: Colors.white,
          size: 25,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Add Friend Option Card
// ─────────────────────────────────────────────
class _AddFriendOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AddFriendOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}