import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/friend_service.dart';
import 'style_constants.dart';

class ScanFriendQrScreen extends StatefulWidget {
  final String childId;

  const ScanFriendQrScreen({
    super.key,
    required this.childId,
  });

  @override
  State<ScanFriendQrScreen> createState() =>
      _ScanFriendQrScreenState();
}

class _ScanFriendQrScreenState extends State<ScanFriendQrScreen> {
  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  final MobileScannerController _scannerController =
      MobileScannerController();

  bool _processing = false;
  bool _success = false;

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
  // Read QR
  // ─────────────────────────────────────────────
  Future<void> _handleBarcode(
    BarcodeCapture capture,
  ) async {
    if (_processing || _success) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    final String? rawValue =
        capture.barcodes.first.rawValue;

    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    const String prefix = 'faseh://friend/';

    // QR ليس خاصًا بفصيح
    if (!rawValue.startsWith(prefix)) {
      _showAppSnackBar(
        'هذا الرمز غير صالح لإضافة صديق',
        backgroundColor: _coral,
      );

      return;
    }

    final String fasehId =
        rawValue.substring(prefix.length).trim();

    if (fasehId.isEmpty) {
      _showAppSnackBar(
        'تعذّر قراءة الرمز. حاول مرة أخرى',
        backgroundColor: _coral,
      );

      return;
    }

    setState(() {
      _processing = true;
    });

    // إيقاف المسح حتى لا يُقرأ الرمز أكثر من مرة
    await _scannerController.stop();

    try {
      await FriendService().sendFriendRequestByFasehId(
        currentChildId: widget.childId,
        enteredFasehId: fasehId,
      );

      if (!mounted) return;

      setState(() {
        _processing = false;
        _success = true;
      });

      // عرض شاشة النجاح لمدة مناسبة حتى يستطيع الطفل قراءتها
      await Future.delayed(
        const Duration(milliseconds: 3500),
      );

      if (!mounted) return;

      // العودة تلقائيًا إلى صفحة إضافة صديق
      Navigator.pop(context, true);
    }

    // Firestore errors
    on FirebaseException catch (e) {
      if (!mounted) return;

      String message =
          'تعذّر إرسال طلب الصداقة. حاول مرة أخرى';

      if (e.code == 'permission-denied') {
        message =
            'تم إرسال طلب صداقة لهذا الطفل مسبقًا أو أنكما أصدقاء بالفعل';
      }

      setState(() {
        _processing = false;
      });

      _showAppSnackBar(
        message,
        backgroundColor: _coral,
      );

      await _restartScanner();
    }

    // FriendService errors
    catch (e) {
      if (!mounted) return;

      final String error = e.toString();

      String message =
          'تعذّر إرسال طلب الصداقة. حاول مرة أخرى';

      if (error.contains('CANNOT_ADD_SELF')) {
        message = 'لا يمكنك إضافة نفسك كصديق';
      } else if (error.contains('FASEH_ID_NOT_FOUND')) {
        message = 'لم يتم العثور على هذا الصديق';
      } else if (error.contains('INVALID_FASEH_ID')) {
        message = 'هذا الرمز غير صالح لإضافة صديق';
      } else if (error.contains(
        'PUBLIC_PROFILE_NOT_FOUND',
      )) {
        message = 'تعذّر العثور على هذا الصديق';
      } else if (error.contains('NOT_AUTHENTICATED')) {
        message = 'يجب تسجيل الدخول أولًا';
      }

      setState(() {
        _processing = false;
      });

      _showAppSnackBar(
        message,
        backgroundColor: _coral,
      );

      await _restartScanner();
    }
  }

  Future<void> _restartScanner() async {
    if (!mounted || _success) {
      return;
    }

    try {
      await _scannerController.start();
    } catch (_) {
      // لا نعرض رسالة تقنية للطفل
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        body: Column(
          children: [
            // ─────────────────────────────────────
            // Unified Header
            // بدون تغيير
            // ─────────────────────────────────────
            FaseehStyle.buildLargeHeader(
              context: context,
              title: 'مسح رمز صديق',
              subtitle: 'امسح رمز صديقك لإرسال طلب صداقة',
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─────────────────────────────────────
            // Page Content
            // ─────────────────────────────────────
            Expanded(
              child: _success
                  ? _buildSuccessView()
                  : _buildScannerView(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Scanner
  // ─────────────────────────────────────────────
  Widget _buildScannerView() {
    return SafeArea(
      top: false,
      child: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: _ScanPageBackground(),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 14),

              // =====================================================
              // Bunny card
              // =====================================================
              const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: _ScanHeroCard(),
              ),

              const SizedBox(height: 14),

              // =====================================================
              // Scanner
              // =====================================================
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    0,
                    18,
                    20,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: _purple.withOpacity(0.08),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10000000),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MobileScanner(
                            controller: _scannerController,
                            onDetect: _handleBarcode,
                          ),

                          // Soft border
                          Container(
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white
                                    .withOpacity(0.18),
                                width: 2,
                              ),
                            ),
                          ),

                          // Soft camera overlay
                          Container(
                            color: Colors.black.withOpacity(0.14),
                          ),

                          // =================================================
                          // QR target frame
                          // =================================================
                          Center(
                            child: Container(
                              width: 235,
                              height: 235,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(28),
                                border: Border.all(
                                  color: _coral,
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _coral.withOpacity(0.15),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: _cornerDot(),
                                  ),
                                  Positioned(
                                    top: 12,
                                    left: 12,
                                    child: _cornerDot(),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: _cornerDot(),
                                  ),
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    child: _cornerDot(),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // =================================================
                          // Small simple instruction
                          // =================================================
                          Positioned(
                            top: 14,
                            left: 14,
                            right: 14,
                            child: Center(
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white
                                      .withOpacity(0.90),
                                  borderRadius:
                                      BorderRadius.circular(18),
                                ),
                                child: const Text(
                                  'ضع الرمز داخل الإطار',
                                  style: TextStyle(
                                    color: _purple,
                                    fontSize: 11.2,
                                    fontWeight:
                                        FontWeight.w700,
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (_processing)
                            Container(
                              color: Colors.black38,
                              child: const Center(
                                child:
                                    CircularProgressIndicator(
                                  color: Colors.white,
                                ),
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
        ],
      ),
    );
  }

  Widget _cornerDot() {
    return Container(
      width: 11,
      height: 11,
      decoration: const BoxDecoration(
        color: Color(0xFFFFB4BF),
        shape: BoxShape.circle,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Success
  // ─────────────────────────────────────────────
Widget _buildSuccessView() {
  return SafeArea(
    top: false,
    child: Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: _ScanPageBackground(),
          ),
        ),

        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              width: double.infinity,

              // نفس حجم ومسافات كارد طلبات الصداقة
              padding: const EdgeInsets.fromLTRB(
                20,
                24,
                20,
                22,
              ),

              decoration: BoxDecoration(
                color: const Color(0xFFF7F0FF),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF511281)
                      .withOpacity(0.07),
                ),
              ),

              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // =================================================
                  // Signature Bunny
                  // =================================================
                  SizedBox(
                    width: 120,
                    height: 118,
                    child: _SuccessBunny(),
                  ),

                  SizedBox(height: 9),

                  // =================================================
                  // Title
                  // =================================================
                  Text(
                    'تم إرسال الطلب!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF511281),
                      fontFamily: 'Tajawal',
                    ),
                  ),

                  SizedBox(height: 6),

                  // =================================================
                  // Message
                  // =================================================
                  Text(
                    'سيظهر صديقك في قائمة الأصدقاء بعد قبول الطلب',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF858085),
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

// =============================================================================
// HERO CARD
// =============================================================================

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 128,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF511281)
              .withOpacity(0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5)
                      .withOpacity(0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              left: 28,
              bottom: -48,
              child: Container(
                width: 125,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9E2)
                      .withOpacity(0.42),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 105,
                    height: 105,
                    child: _SignatureScanBunny(),
                  ),

                  SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'امسح رمز صديقك',
                          style: TextStyle(
                            color: Color(0xFF511281),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'وجّه الكاميرا إلى الرمز داخل الإطار',
                          style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 11.4,
                            height: 1.45,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        SizedBox(height: 8),

                        Row(
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Color(0xFFFF7890),
                              size: 15,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'بسيطة وسريعة',
                              style: TextStyle(
                                color: Color(0xFF8B55B3),
                                fontSize: 9.8,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Tajawal',
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
// BACKGROUND
// =============================================================================

class _ScanPageBackground extends StatelessWidget {
  const _ScanPageBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 40,
          right: -50,
          child: _circle(
            145,
            const Color(0xFFDCC9F5)
                .withOpacity(0.18),
          ),
        ),

        Positioned(
          top: 255,
          left: -58,
          child: _circle(
            145,
            const Color(0xFFDDF2E3)
                .withOpacity(0.24),
          ),
        ),

        Positioned(
          top: 520,
          right: -42,
          child: _circle(
            120,
            const Color(0xFFFFDCE3)
                .withOpacity(0.22),
          ),
        ),

        Positioned(
          top: 390,
          left: 30,
          child: _circle(
            18,
            const Color(0xFFD3B7E8)
                .withOpacity(0.35),
          ),
        ),

        Positioned(
          top: 685,
          left: 24,
          child: _circle(
            16,
            const Color(0xFFFFC7D3)
                .withOpacity(0.40),
          ),
        ),
      ],
    );
  }

  Widget _circle(
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// =============================================================================
// SIGNATURE BUNNY FOR SCAN PAGE
// =============================================================================

class _SignatureScanBunny extends StatelessWidget {
  const _SignatureScanBunny();

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
        // صديق صغير
        Positioned(
          left: 0,
          bottom: 10,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF2E3),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: detailsColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: detailsColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 3),

                    Container(
                      width: 11,
                      height: 6,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: detailsColor,
                            width: 1.2,
                          ),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft:
                              Radius.circular(8),
                          bottomRight:
                              Radius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // جهاز سكان
        Positioned(
          right: 0,
          bottom: 12,
          child: Transform.rotate(
            angle: 0.10,
            child: Container(
              width: 34,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: const Color(0xFFE4D6EE),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 17,
                    color: Color(0xFF8B55B3),
                  ),
                  SizedBox(height: 2),
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 12,
                    color: Color(0xFFFF7890),
                  ),
                ],
              ),
            ),
          ),
        ),

        // قلب صغير
        Positioned(
          top: 10,
          left: 6,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF7890),
              size: 13,
            ),
          ),
        ),

        // الأذن اليمنى
        Positioned(
          top: 0,
          right: 25,
          child: Container(
            width: 19,
            height: 39,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      innerEarColor.withOpacity(0.55),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // الأذن اليسرى
        Positioned(
          top: 0,
          left: 25,
          child: Container(
            width: 19,
            height: 39,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      innerEarColor.withOpacity(0.55),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // الجسم
        Positioned(
          bottom: 2,
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

        // الرأس
        Positioned(
          top: 28,
          child: Container(
            width: 59,
            height: 55,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // العين اليمنى
                Positioned(
                  top: 20,
                  right: 14,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration:
                        const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // العين اليسرى
                Positioned(
                  top: 20,
                  left: 14,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration:
                        const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // الخد الأيمن
                Positioned(
                  top: 32,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFF96AC,
                      ).withOpacity(0.50),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                // الخد الأيسر
                Positioned(
                  top: 32,
                  left: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFF96AC,
                      ).withOpacity(0.50),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                // الأنف
                Positioned(
                  top: 28,
                  left: 26,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration:
                        const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // الابتسامة
                Positioned(
                  top: 34,
                  left: 22,
                  child: Container(
                    width: 15,
                    height: 7,
                    decoration:
                        const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: detailsColor,
                          width: 1.4,
                        ),
                      ),
                      borderRadius:
                          BorderRadius.only(
                        bottomLeft:
                            Radius.circular(10),
                        bottomRight:
                            Radius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // اليد اليسرى
        Positioned(
          left: 27,
          bottom: 14,
          child: Transform.rotate(
            angle: 0.35,
            child: Container(
              width: 10,
              height: 20,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // اليد اليمنى باتجاه الجهاز
        Positioned(
          right: 26,
          bottom: 14,
          child: Transform.rotate(
            angle: -0.45,
            child: Container(
              width: 10,
              height: 20,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SUCCESS BUNNY
// نفس الأرنب الأساسي + علامة صح صغيرة فقط
// =============================================================================

class _SuccessBunny extends StatelessWidget {
  const _SuccessBunny();

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
        // =========================================================
        // علامة الصح بجانب الأرنب
        // =========================================================
        Positioned(
          top: 22,
          right: 8,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF7AC794)
                    .withOpacity(0.38),
                width: 1.4,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF4CAF73),
              size: 24,
            ),
          ),
        ),

        // =========================================================
        // قلب صغير
        // =========================================================
        Positioned(
          top: 15,
          left: 12,
          child: Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF8FA6),
              size: 14,
            ),
          ),
        ),

        // =========================================================
        // الأذن اليمنى
        // =========================================================
        Positioned(
          top: 6,
          right: 41,
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
                height: 27,
                decoration: BoxDecoration(
                  color:
                      innerEarColor.withOpacity(0.55),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),

        // =========================================================
        // الأذن اليسرى
        // =========================================================
        Positioned(
          top: 6,
          left: 41,
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
                height: 27,
                decoration: BoxDecoration(
                  color:
                      innerEarColor.withOpacity(0.55),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),

        // =========================================================
        // الجسم
        // =========================================================
        Positioned(
          bottom: 4,
          child: Container(
            width: 54,
            height: 34,
            decoration: const BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(27),
                topRight: Radius.circular(27),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
          ),
        ),

        // =========================================================
        // الرأس
        // =========================================================
        Positioned(
          top: 39,
          child: Container(
            width: 68,
            height: 63,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(0.04),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // العين اليمنى
                Positioned(
                  top: 22,
                  right: 17,
                  child: Container(
                    width: 7,
                    height: 8,
                    decoration:
                        const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // العين اليسرى
                Positioned(
                  top: 22,
                  left: 17,
                  child: Container(
                    width: 7,
                    height: 8,
                    decoration:
                        const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // الخد الأيمن
                Positioned(
                  top: 37,
                  right: 8,
                  child: Container(
                    width: 10,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFF96AC,
                      ).withOpacity(0.50),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                // الخد الأيسر
                Positioned(
                  top: 37,
                  left: 8,
                  child: Container(
                    width: 10,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFF96AC,
                      ).withOpacity(0.50),
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),
                ),

                // الأنف
                Positioned(
                  top: 32,
                  left: 30,
                  child: Container(
                    width: 8,
                    height: 6,
                    decoration:
                        const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // الابتسامة
                Positioned(
                  top: 40,
                  left: 24,
                  child: Container(
                    width: 20,
                    height: 9,
                    decoration:
                        const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: detailsColor,
                          width: 1.5,
                        ),
                      ),
                      borderRadius:
                          BorderRadius.only(
                        bottomLeft:
                            Radius.circular(10),
                        bottomRight:
                            Radius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}