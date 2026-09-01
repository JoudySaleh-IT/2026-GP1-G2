import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ChildSession.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../utils/arabic_numbers.dart';

class ChildEnterCodeScreen extends StatefulWidget {
  const ChildEnterCodeScreen({super.key});

  @override
  State<ChildEnterCodeScreen> createState() => _ChildEnterCodeScreenState();
}

class _ChildEnterCodeScreenState extends State<ChildEnterCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _isLoading = false;

  // ─────────────────────────────────────────────────────────────────────────
  // FUNCTIONALITY - بدون تغيير
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _verifyCode(String enteredCode) async {
    setState(() => _isLoading = true);

    try {
      // ─── 1. Make sure this is an anonymous child account ───
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        final credential = await FirebaseAuth.instance.signInAnonymously();

        user = credential.user;
      }

      if (user == null || !user.isAnonymous) {
        _showError('تعذر تسجيل دخول جهاز الطفل.');
        return;
      }

      final FirebaseFirestore db = FirebaseFirestore.instance;

      final codeRef = db.collection('pairing_codes').doc(enteredCode);

      final deviceLinkRef = db.collection('child_device_links').doc(user.uid);

      // ─── 2. Validate code + securely bind device to child ───
      final result = await db.runTransaction<Map<String, String>>((
        transaction,
      ) async {
        // ALL READS FIRST
        final codeSnapshot = await transaction.get(codeRef);

        final deviceLinkSnapshot = await transaction.get(deviceLinkRef);

        if (!codeSnapshot.exists) {
          throw Exception('INVALID_PAIRING_CODE');
        }

        final data = codeSnapshot.data()!;

        final Timestamp? expiresAt = data['expiresAt'] as Timestamp?;

        if (expiresAt == null || expiresAt.toDate().isBefore(DateTime.now())) {
          throw Exception('INVALID_PAIRING_CODE');
        }

        if (deviceLinkSnapshot.exists) {
          throw Exception('DEVICE_ALREADY_LINKED');
        }

        final String childId = data['childId'] as String;

        final String parentId = data['parentId'] as String;

        final String childName = data['childName'] as String? ?? 'بطلنا';

        // ALL WRITES AFTER READS

        transaction.set(deviceLinkRef, {
          'childId': childId,
          'parentId': parentId,
          'pairingCode': enteredCode,
          'createdAt': FieldValue.serverTimestamp(),
        });

        transaction.delete(codeRef);

        return {
          'childId': childId,
          'parentId': parentId,
          'childName': childName,
        };
      });

      final String childId = result['childId']!;
      final String parentId = result['parentId']!;
      final String childName = result['childName']!;

      // ─── 3. Save local child session ───
      ChildSession.currentChildId = childId;
      ChildSession.currentParentId = parentId;

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('saved_childId', childId);

      await prefs.setString('saved_parentId', parentId);

      await prefs.setBool('isChildLoggedIn', true);

      if (!mounted) return;

      NotificationService.showSuccessSnackBar(
        'اهلًا $childName! جاهز تكون فصيح؟',
      );

      Navigator.pushReplacementNamed(
        context,
        '/child/home',
        arguments: childId,
      );
    } catch (e) {
      print('Pairing error: $e');

      if (!mounted) return;

      if (e.toString().contains('INVALID_PAIRING_CODE')) {
        _showError('الكود غير صحيح أو انتهت صلاحيته');
      } else if (e.toString().contains('DEVICE_ALREADY_LINKED')) {
        _showError('هذا الجهاز مرتبط بطفل بالفعل');
      } else {
        _showError('حدث خطأ أثناء التحقق من الكود. حاول مرة أخرى.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: const Color(0xFFFCF9EA),
        body: Stack(
          children: [
            // ===============================================================
            // Pastel background
            // ===============================================================
            const Positioned.fill(
              child: IgnorePointer(child: _CodeBackground()),
            ),

            // ===============================================================
            // Content
            // ===============================================================
            SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
                child: Column(
                  children: [
                    // =======================================================
                    // Back
                    // =======================================================
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.82),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF511281).withOpacity(0.07),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x09000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Color(0xFF511281),
                            size: 23,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =======================================================
                    // Cute bunny
                    // =======================================================
                    const SizedBox(
                      width: 125,
                      height: 128,
                      child: _CuteCodeBunny(),
                    ),

                    const SizedBox(height: 7),

                    // =======================================================
                    // Title
                    // =======================================================
                    const Text(
                      'أدخل رمز الدخول',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF511281),
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 26),
                      child: Text(
                        'اطلب من ولي أمرك رمز الدخول المكوّن من ٦ أرقام',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12.5,
                          height: 1.55,
                          color: Color(0xFF777777),
                        ),
                      ),
                    ),

                    const SizedBox(height: 21),

                    // =======================================================
                    // Code card
                    // =======================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.93),
                        borderRadius: BorderRadius.circular(27),
                        border: Border.all(
                          color: const Color(0xFF511281).withOpacity(0.08),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // =================================================
                          // Card instruction
                          // =================================================
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EEFA),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.dialpad_rounded,
                                  color: Color(0xFF7B4AAD),
                                  size: 17,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'اكتب الأرقام هنا',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    color: Color(0xFF6F4595),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // =================================================
                          // Code fields
                          // نفس الـfunctionality
                          // =================================================
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Opacity(
                                  opacity: 0,
                                  child: TextField(
                                    controller: _codeController,
                                    focusNode: _focusNode,
                                    keyboardType: TextInputType.number,
                                    maxLength: 6,
                                    onChanged: (value) {
                                      setState(() {});

                                      if (value.length == 6) {
                                        _verifyCode(value);
                                      }
                                    },
                                  ),
                                ),

                                GestureDetector(
                                  onTap: () => _focusNode.requestFocus(),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(6, (index) {
                                      String char = '';

                                      if (_codeController.text.length > index) {
                                        char = _codeController.text[index];
                                      }

                                      final bool hasValue =
                                          _codeController.text.length > index;

                                      final bool isFocused =
                                          _codeController.text.length == index;

                                      return AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        width: 43,
                                        height: 56,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: hasValue
                                              ? const Color(0xFFF7F0FF)
                                              : const Color(0xFFFFFCFD),
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border: Border.all(
                                            color: isFocused
                                                ? const Color(0xFFFF6969)
                                                : hasValue
                                                ? const Color(0xFFB996D3)
                                                : const Color(0xFFE6DDEC),
                                            width: isFocused ? 2.2 : 1.3,
                                          ),
                                          boxShadow: [
                                            if (isFocused)
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFFF6969,
                                                ).withOpacity(0.13),
                                                blurRadius: 8,
                                              ),
                                          ],
                                        ),
                                        child: Text(
                                          toArabicDigits(char),
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF511281),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // =================================================
                          // Status
                          // =================================================
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            constraints: const BoxConstraints(minHeight: 46),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 13,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _isLoading
                                  ? const Color(0xFFFFF1F3)
                                  : const Color(0xFFF4F8F2),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Color(0xFFFF6969),
                                        ),
                                      ),
                                      SizedBox(width: 9),
                                      Text(
                                        'جاري التحقق من الرمز...',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 11.5,
                                          color: Color(0xFF777777),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 26,
                                        height: 26,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFDFF1E4),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.lock_open_rounded,
                                          color: Color(0xFF69A57D),
                                          size: 14,
                                        ),
                                      ),

                                      const SizedBox(width: 8),

                                      Text(
                                        _codeController.text.length == 6
                                            ? 'جاري التحقق...'
                                            : 'أدخل رمزك المكوّن من ٦ أرقام',
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 11.5,
                                          color: Color(0xFF777777),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =======================================================
                    // Small parent hint
                    // =======================================================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E5),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.family_restroom_rounded,
                            size: 16,
                            color: Color(0xFFC38D2A),
                          ),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'ستجد الرمز عند ولي أمرك',
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
                    const SizedBox(height: 12),

                    // =======================================================
                    // Bottom pastel decorations
                    // تظهر فعلًا في آخر الصفحة
                    // =======================================================
                    SizedBox(
                      height: 95,
                      width: double.infinity,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // دائرة كبيرة بنفسجية - يسار
                          Positioned(
                            bottom: -45,
                            left: -55,
                            child: Container(
                              width: 135,
                              height: 135,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFDCC9F5,
                                ).withOpacity(0.22),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                          // دائرة وردية - يمين
                          Positioned(
                            bottom: -28,
                            right: -28,
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFFDDE4,
                                ).withOpacity(0.28),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                          // دائرة خضراء صغيرة
                          Positioned(
                            bottom: 28,
                            right: 62,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFDDF2E3,
                                ).withOpacity(0.65),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),

                          // دائرة بنفسجية صغيرة
                          Positioned(
                            bottom: 16,
                            left: 75,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFCDB1E2,
                                ).withOpacity(0.55),
                                shape: BoxShape.circle,
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
    );
  }
}

// =============================================================================
// Background
// دوائر pastel فقط
// =============================================================================

class _CodeBackground extends StatelessWidget {
  const _CodeBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // دائرة بنفسجية أعلى اليسار
        Positioned(
          top: -45,
          left: -45,
          child: _circle(150, const Color(0xFFDCC9F5).withOpacity(0.24)),
        ),

        // دائرة وردية يمين
        Positioned(
          top: 190,
          right: -55,
          child: _circle(145, const Color(0xFFFFDDE4).withOpacity(0.25)),
        ),

        // دائرة خضراء يسار
        Positioned(
          top: 470,
          left: -55,
          child: _circle(150, const Color(0xFFDDF2E3).withOpacity(0.27)),
        ),

        // دائرة صغيرة بنفسجية
        Positioned(
          top: 355,
          left: 35,
          child: _circle(19, const Color(0xFFCDB1E2).withOpacity(0.35)),
        ),

        // الدائرة السفلية
        // كانت bottom: -80 وهذا سبب القص
        Positioned(
          bottom: 20,
          right: -35,
          child: _circle(145, const Color(0xFFF3E1BA).withOpacity(0.22)),
        ),

        // دائرة صغيرة أسفل اليسار
        Positioned(
          bottom: 65,
          left: 28,
          child: _circle(22, const Color(0xFFFFC8D4).withOpacity(0.32)),
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
// Cute Code Bunny
// نفس عائلة الشخصية المستخدمة بباقي الصفحات
// لكن هنا معه بطاقة أرقام تناسب صفحة تسجيل الدخول
// =============================================================================

class _CuteCodeBunny extends StatelessWidget {
  const _CuteCodeBunny();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);
    const Color bodyColor = Color(0xFF8B55B3);
    const Color innerEarColor = Color(0xFFFFA1B7);
    const Color detailsColor = Color(0xFF4D3855);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // -------------------------------------------------------------------
        // Small code card
        // -------------------------------------------------------------------
        Positioned(
          right: 0,
          top: 44,
          child: Transform.rotate(
            angle: 0.08,
            child: Container(
              width: 44,
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD6C0E8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_TinyCodeDot(), _TinyCodeDot(), _TinyCodeDot()],
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_TinyCodeDot(), _TinyCodeDot(), _TinyCodeDot()],
                  ),
                ],
              ),
            ),
          ),
        ),

        // -------------------------------------------------------------------
        // Right ear
        // -------------------------------------------------------------------
        Positioned(
          top: 0,
          right: 31,
          child: Container(
            width: 21,
            height: 43,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 28,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(13),
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
          left: 31,
          child: Container(
            width: 21,
            height: 43,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 28,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ),

        // -------------------------------------------------------------------
        // Body
        // -------------------------------------------------------------------
        Positioned(
          bottom: 2,
          child: Container(
            width: 56,
            height: 38,
            decoration: const BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
          ),
        ),

        // -------------------------------------------------------------------
        // Head
        // -------------------------------------------------------------------
        Positioned(
          top: 33,
          child: Container(
            width: 72,
            height: 67,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Eyes
                Positioned(
                  top: 24,
                  right: 17,
                  child: Container(
                    width: 7,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 24,
                  left: 17,
                  child: Container(
                    width: 7,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Eye shine
                Positioned(
                  top: 25,
                  right: 18,
                  child: Container(
                    width: 2.5,
                    height: 2.5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 25,
                  left: 18,
                  child: Container(
                    width: 2.5,
                    height: 2.5,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 39,
                  right: 8,
                  child: Container(
                    width: 12,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 39,
                  left: 8,
                  child: Container(
                    width: 12,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.48),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 34,
                  left: 32,
                  child: Container(
                    width: 8,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Smile
                Positioned(
                  top: 41,
                  left: 27,
                  child: Container(
                    width: 18,
                    height: 9,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: detailsColor, width: 1.5),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // -------------------------------------------------------------------
        // Left hand
        // -------------------------------------------------------------------
        Positioned(
          left: 29,
          bottom: 11,
          child: Transform.rotate(
            angle: 0.25,
            child: Container(
              width: 11,
              height: 24,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // -------------------------------------------------------------------
        // Right hand toward code card
        // -------------------------------------------------------------------
        Positioned(
          right: 27,
          bottom: 17,
          child: Transform.rotate(
            angle: -0.65,
            child: Container(
              width: 11,
              height: 25,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Tiny dots used inside the card held by the bunny
// =============================================================================

class _TinyCodeDot extends StatelessWidget {
  const _TinyCodeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFF8B55B3),
        shape: BoxShape.circle,
      ),
    );
  }
}
