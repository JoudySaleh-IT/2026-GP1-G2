import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'my_friend_qr_screen.dart';
import 'scan_friend_qr_screen.dart';
import '../services/friend_service.dart';
import 'style_constants.dart';

class AddFriendScreen extends StatefulWidget {
  final String childId;

  const AddFriendScreen({super.key, required this.childId});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  String _enteredFasehId = '';
  bool _loading = false;

  // ─────────────────────────────────────────────
  // Standard App SnackBar
  // بدون تغيير
  // ─────────────────────────────────────────────
  void _showAppSnackBar(String message, {Color backgroundColor = _purple}) {
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
  // بدون تغيير
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

      _showAppSnackBar('تم إرسال طلب الصداقة بنجاح 🎉');
    }
    // Firestore errors
    on FirebaseException catch (e) {
      if (!mounted) return;

      String message = 'تعذّر إرسال طلب الصداقة، حاول مرة أخرى';

      if (e.code == 'permission-denied') {
        message = 'تم إرسال طلب صداقة لهذا الطفل مسبقًا أو أنكما أصدقاء بالفعل';
      }

      setState(() {
        _loading = false;
      });

      _showAppSnackBar(message, backgroundColor: _coral);
    }
    // FriendService custom errors
    catch (e) {
      if (!mounted) return;

      final String error = e.toString();

      String message = 'تعذّر إرسال طلب الصداقة، حاول مرة أخرى';

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

      _showAppSnackBar(message, backgroundColor: _coral);
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
            // ===============================================================
            // HEADER
            // نفس الهيدر بدون تغيير
            // ===============================================================
            const _AddFriendHeader(),

            // ===============================================================
            // BODY
            // ===============================================================
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(child: _AddFriendBackground()),
                  ),

                  SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 15, 18, 35),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // =================================================
                          // Welcome Card
                          // =================================================
                          const _AddFriendWelcomeCard(),

                          const SizedBox(height: 15),

                          // =================================================
                          // QR options
                          // =================================================
                          const Padding(
                            padding: EdgeInsets.only(right: 3, bottom: 9),
                            child: Text(
                              'اختر طريقة الإضافة',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF511281),
                              ),
                            ),
                          ),

                          // Scan QR
                          _AddFriendOption(
                            icon: Icons.qr_code_scanner_rounded,
                            title: 'مسح رمز QR',
                            subtitle: 'امسح رمز صديقك وأرسل له طلب صداقة',
                            color: _coral,
                            backgroundColor: const Color(0xFFFFF0F3),
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

                          const SizedBox(height: 11),

                          // My QR
                          _AddFriendOption(
                            icon: Icons.qr_code_2_rounded,
                            title: 'رمزي الخاص',
                            subtitle: 'دع صديقك يمسح رمزك لإضافتك',
                            color: _purple,
                            backgroundColor: const Color(0xFFF4EEFA),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MyFriendQrScreen(childId: widget.childId),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 20),

                          // =================================================
                          // OR
                          // =================================================
                          const _CuteDivider(),

                          const SizedBox(height: 18),

                          // =================================================
                          // Faseh ID Card
                          // =================================================
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: _purple.withOpacity(0.07),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x08000000),
                                  blurRadius: 7,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1E8FA),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.badge_outlined,
                                        color: Color(0xFF7B4AAD),
                                        size: 20,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'أو استخدم معرّف فصيح',
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF511281),
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'اكتب معرّف صديقك لإرسال الطلب',
                                            style: TextStyle(
                                              fontFamily: 'Tajawal',
                                              fontSize: 10.5,
                                              color: Color(0xFF888888),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // =================================================
                                // Text Field
                                // نفس functionality
                                // =================================================
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
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 14,
                                    color: Color(0xFF511281),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'FSH-XXXX-XXXX',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFFB2A9B8),
                                      fontFamily: 'Tajawal',
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.person_search_rounded,
                                      color: Color(0xFF8B55B3),
                                      size: 21,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFFAF7FC),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(17),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(17),
                                      borderSide: BorderSide(
                                        color: _purple.withOpacity(0.10),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(17),
                                      borderSide: const BorderSide(
                                        color: _coral,
                                        width: 1.7,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // =================================================
                                // Send Button
                                // نفس functionality
                                // =================================================
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _loading
                                        ? null
                                        : _sendFriendRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _coral,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: _coral
                                          .withOpacity(0.6),
                                      disabledForegroundColor: Colors.white,
                                      elevation: 0,
                                      shape: const StadiumBorder(),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'إرسال طلب صداقة',
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w700,
                                                  fontFamily: 'Tajawal',
                                                ),
                                              ),
                                              SizedBox(width: 7),
                                              Icon(
                                                Icons.favorite_rounded,
                                                size: 17,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // =================================================
                          // Small hint
                          // =================================================
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E5),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFC28C2A),
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'رمز QR هو أسرع طريقة لإضافة صديق',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 10.5,
                                      color: Color(0xFF927039),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// HEADER
// نفس الهيدر الأصلي
// =============================================================================

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
          _HeaderIconBtn(
            icon: Icons.arrow_back,
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const SizedBox(width: 12),

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

// =============================================================================
// HEADER BUTTON
// =============================================================================

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, color: Colors.white, size: 25),
      ),
    );
  }
}

// =============================================================================
// WELCOME CARD
// =============================================================================

class _AddFriendWelcomeCard extends StatelessWidget {
  const _AddFriendWelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 130),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF511281).withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -45,
              top: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5).withOpacity(0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              left: 35,
              bottom: -55,
              child: Container(
                width: 135,
                height: 105,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9E2).withOpacity(0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  SizedBox(width: 100, height: 105, child: _AddFriendBunny()),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هيا نضيف صديقًا!',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF511281),
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'أضف صديقك واستمتعا بالتدريب معًا',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11.5,
                            height: 1.5,
                            color: Color(0xFF777777),
                          ),
                        ),

                        SizedBox(height: 9),

                        Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              size: 15,
                              color: Color(0xFFFF7890),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'التعلّم أجمل مع الأصدقاء',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B55B3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// ADD FRIEND OPTION
// =============================================================================

class _AddFriendOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _AddFriendOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 91),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.10)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x07000000),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.83),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.10)),
                ),
                child: Icon(icon, color: color, size: 29),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                        fontFamily: 'Tajawal',
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.4,
                        color: Color(0xFF818181),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: color.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CUTE DIVIDER
// =============================================================================

class _CuteDivider extends StatelessWidget {
  const _CuteDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFDCCFE5))),

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF3EBFA),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Text(
            'أو',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B55B3),
            ),
          ),
        ),

        Expanded(child: Container(height: 1, color: const Color(0xFFDCCFE5))),
      ],
    );
  }
}

// =============================================================================
// BACKGROUND
// =============================================================================

class _AddFriendBackground extends StatelessWidget {
  const _AddFriendBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 40,
          right: -55,
          child: _circle(145, const Color(0xFFDCC9F5).withOpacity(0.18)),
        ),

        Positioned(
          top: 290,
          left: -60,
          child: _circle(150, const Color(0xFFDDF2E3).withOpacity(0.26)),
        ),

        Positioned(
          top: 555,
          right: -45,
          child: _circle(120, const Color(0xFFFFDCE3).withOpacity(0.23)),
        ),

        Positioned(
          top: 750,
          left: 35,
          child: _circle(19, const Color(0xFFD4BDEA).withOpacity(0.34)),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// =============================================================================
// BUNNY + FRIEND
// =============================================================================

class _AddFriendBunny extends StatelessWidget {
  const _AddFriendBunny();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);
    const Color bodyColor = Color(0xFF8B55B3);
    const Color innerEar = Color(0xFFFFA1B7);
    const Color details = Color(0xFF4D3855);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // -------------------------------------------------------------------
        // صغير يمثل الصديق
        // -------------------------------------------------------------------
        // -------------------------------------------------------------------
        // صغير يمثل الصديق - الوجه متوسّط بالكامل
        // -------------------------------------------------------------------
        Positioned(
          left: 0,
          bottom: 5,
          child: Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF2E3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 4),
              ],
            ),
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // العيون
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: details,
                            shape: BoxShape.circle,
                          ),
                        ),

                        const SizedBox(width: 7),

                        Container(
                          width: 4,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: details,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    // الابتسامة - في منتصف الوجه تمامًا
                    Container(
                      width: 12,
                      height: 6,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: details, width: 1.2),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // -------------------------------------------------------------------
        // Heart
        // -------------------------------------------------------------------
        Positioned(
          top: 11,
          left: 4,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x09000000), blurRadius: 4)],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF7890),
              size: 14,
            ),
          ),
        ),

        // -------------------------------------------------------------------
        // Right ear
        // -------------------------------------------------------------------
        Positioned(
          top: 0,
          right: 24,
          child: Container(
            width: 19,
            height: 38,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEar.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // -------------------------------------------------------------------
        // Left ear
        // -------------------------------------------------------------------
        Positioned(
          top: 0,
          left: 24,
          child: Container(
            width: 19,
            height: 38,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEar.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // -------------------------------------------------------------------
        // Body
        // -------------------------------------------------------------------
        Positioned(
          bottom: 0,
          child: Container(
            width: 46,
            height: 29,
            decoration: const BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
            ),
          ),
        ),

        // -------------------------------------------------------------------
        // Head
        // -------------------------------------------------------------------
        Positioned(
          top: 27,
          child: Container(
            width: 59,
            height: 55,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Eyes
                Positioned(
                  top: 20,
                  right: 14,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: details,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 20,
                  left: 14,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: details,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 32,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 32,
                  left: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 28,
                  left: 26,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Smile
                Positioned(
                  top: 34,
                  left: 22,
                  child: Container(
                    width: 15,
                    height: 7,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: details, width: 1.4),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // -------------------------------------------------------------------
        // Person add bubble
        // -------------------------------------------------------------------
        Positioned(
          right: 0,
          bottom: 6,
          child: Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2D4EE)),
            ),
            child: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFF8B55B3),
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}
