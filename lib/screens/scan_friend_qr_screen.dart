import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/friend_service.dart';

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

class _ScanFriendQrScreenState
    extends State<ScanFriendQrScreen> {
  static const Color _purple =
      Color(0xFF511281);
  static const Color _coral =
      Color(0xFFFF6969);
  static const Color _background =
      Color(0xFFFCF9EA);

  final MobileScannerController
      _scannerController =
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
    final messenger =
        ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        backgroundColor:
            backgroundColor,
        behavior:
            SnackBarBehavior.fixed,
        elevation: 0,
        duration:
            const Duration(
          seconds: 3,
        ),
        content: Directionality(
          textDirection:
              TextDirection.rtl,
          child: Align(
            alignment:
                Alignment.centerRight,
            child: Text(
              message,
              textAlign:
                  TextAlign.right,
              style:
                  const TextStyle(
                fontFamily:
                    'Tajawal',
                fontSize: 14,
                color:
                    Colors.white,
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
    if (_processing ||
        _success) {
      return;
    }

    if (capture.barcodes.isEmpty) {
      return;
    }

    final String? rawValue =
        capture
            .barcodes
            .first
            .rawValue;

    if (rawValue == null ||
        rawValue.isEmpty) {
      return;
    }

    const String prefix =
        'faseh://friend/';

    // QR ليس خاصًا بفصيح
    if (!rawValue.startsWith(prefix)) {
      _showAppSnackBar(
        'هذا الرمز غير صالح لإضافة صديق',
        backgroundColor: _coral,
      );

      return;
    }

    final String fasehId =
        rawValue
            .substring(
              prefix.length,
            )
            .trim();

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
    await _scannerController
        .stop();

    try {
      await FriendService()
          .sendFriendRequestByFasehId(
        currentChildId:
            widget.childId,
        enteredFasehId:
            fasehId,
      );

      if (!mounted) return;

      setState(() {
        _processing = false;
        _success = true;
      });
    }

    // Firestore errors
    on FirebaseException catch (e) {
      if (!mounted) return;

      String message =
          'تعذّر إرسال طلب الصداقة. حاول مرة أخرى';

      if (e.code ==
          'permission-denied') {
        message =
            'تم إرسال طلب صداقة لهذا الطفل مسبقًا أو أنكما أصدقاء بالفعل';
      }

      setState(() {
        _processing = false;
      });

      _showAppSnackBar(
        message,
        backgroundColor:
            _coral,
      );

      await _restartScanner();
    }

    // FriendService errors
    catch (e) {
      if (!mounted) return;

      final String error =
          e.toString();

      String message =
          'تعذّر إرسال طلب الصداقة. حاول مرة أخرى';

      if (error.contains(
        'CANNOT_ADD_SELF',
      )) {
        message =
            'لا يمكنك إضافة نفسك كصديق';
      } else if (error.contains(
        'FASEH_ID_NOT_FOUND',
      )) {
        message =
            'لم يتم العثور على هذا الصديق';
      } else if (error.contains(
        'INVALID_FASEH_ID',
      )) {
        message =
            'هذا الرمز غير صالح لإضافة صديق';
      } else if (error.contains(
        'PUBLIC_PROFILE_NOT_FOUND',
      )) {
        message =
            'تعذّر العثور على هذا الصديق';
      } else if (error.contains(
        'NOT_AUTHENTICATED',
      )) {
        message =
            'يجب تسجيل الدخول أولًا';
      }

      setState(() {
        _processing = false;
      });

      _showAppSnackBar(
        message,
        backgroundColor:
            _coral,
      );

      await _restartScanner();
    }
  }

  Future<void>
      _restartScanner() async {
    if (!mounted ||
        _success) {
      return;
    }

    try {
      await _scannerController
          .start();
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
  Widget build(
    BuildContext context,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor:
            _background,

        appBar: AppBar(
          backgroundColor: _purple,
          foregroundColor:
              Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'مسح رمز صديق',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
              fontFamily:
                  'Tajawal',
            ),
          ),
        ),

        body: _success
            ? _buildSuccessView()
            : _buildScannerView(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Scanner
  // ─────────────────────────────────────────────

  Widget _buildScannerView() {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(
            height: 22,
          ),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Text(
              'وجّه الكاميرا نحو رمز صديقك',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: _purple,
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
                fontFamily:
                    'Tajawal',
              ),
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          const Padding(
            padding:
                EdgeInsets.symmetric(
              horizontal: 30,
            ),
            child: Text(
              'سيتم إرسال طلب الصداقة بعد قراءة الرمز',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey,
                fontSize: 13,
                fontFamily:
                    'Tajawal',
              ),
            ),
          ),

          const SizedBox(
            height: 24,
          ),

          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 22,
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius
                        .circular(
                  28,
                ),
                child: Stack(
                  fit:
                      StackFit.expand,
                  children: [
                    MobileScanner(
                      controller:
                          _scannerController,
                      onDetect:
                          _handleBarcode,
                    ),

                    // Dark overlay
                    Container(
                      decoration:
                          BoxDecoration(
                        border:
                            Border.all(
                          color: Colors
                              .white
                              .withOpacity(
                            0.15,
                          ),
                          width: 2,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          28,
                        ),
                      ),
                    ),

                    // QR target frame
                    Center(
                      child:
                          Container(
                        width: 235,
                        height: 235,
                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            26,
                          ),
                          border:
                              Border.all(
                            color:
                                _coral,
                            width: 4,
                          ),
                        ),
                      ),
                    ),

                    if (_processing)
                      Container(
                        color: Colors
                            .black38,
                        child:
                            const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors
                                    .white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Success
  // ─────────────────────────────────────────────

  Widget _buildSuccessView() {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.all(
          28,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration:
                  BoxDecoration(
                color: Colors.green
                    .withOpacity(
                  0.10,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .check_circle_rounded,
                size: 76,
                color:
                    Colors.green,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'تم إرسال الطلب!',
              style: TextStyle(
                color: _purple,
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
                fontFamily:
                    'Tajawal',
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              'سيظهر صديقك في قائمة الأصدقاء بعد قبول الطلب',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey,
                fontSize: 14,
                fontFamily:
                    'Tajawal',
              ),
            ),

            const SizedBox(
              height: 32,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
                style:
                    ElevatedButton
                        .styleFrom(
                  backgroundColor:
                      _coral,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 15,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                  ),
                ),
                child:
                    const Text(
                  'تم',
                  style:
                      TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight
                            .bold,
                    fontFamily:
                        'Tajawal',
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