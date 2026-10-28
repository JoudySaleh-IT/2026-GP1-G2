import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/arabic_numbers.dart';

class CertificateScreen extends StatefulWidget {
  final String childId;

  const CertificateScreen({
    super.key,
    required this.childId,
  });

  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  // Used to capture ONLY the certificate as an image
  final GlobalKey _certificateKey = GlobalKey();

  // ==========================================================================
  // Format completion date
  // ==========================================================================
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return toArabicDigits('$day / $month / $year');
  }

  // ==========================================================================
  // Generate PDF from the exact certificate shown on screen
  // ==========================================================================
  Future<Uint8List> _generateCertificatePdf() async {
    // Make sure the certificate has finished rendering
    await WidgetsBinding.instance.endOfFrame;

    final context = _certificateKey.currentContext;

    if (context == null) {
      throw Exception('تعذر العثور على الشهادة');
    }

    final renderObject = context.findRenderObject();

    if (renderObject is! RenderRepaintBoundary) {
      throw Exception('تعذر تجهيز الشهادة للحفظ');
    }

    final ui.Image image = await renderObject.toImage(
      pixelRatio: 4.0,
    );

    final byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    image.dispose();

    if (byteData == null) {
      throw Exception('تعذر إنشاء صورة الشهادة');
    }

    final Uint8List pngBytes = byteData.buffer.asUint8List();

    final pdf = pw.Document();

    final certificateImage = pw.MemoryImage(pngBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Center(
            child: pw.Image(
              certificateImage,
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // ==========================================================================
  // Save / Print PDF
  // ==========================================================================
  Future<void> _saveCertificatePdf() async {
    try {
      final pdfBytes = await _generateCertificatePdf();

      await Printing.layoutPdf(
        name: 'Faseh_Certificate.pdf',
        onLayout: (_) async => pdfBytes,
      );
    } catch (e) {
      debugPrint('Certificate save error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر حفظ الشهادة، حاول مرة أخرى',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
        ),
      );
    }
  }

  // ==========================================================================
  // Share PDF
  // ==========================================================================
  Future<void> _shareCertificatePdf() async {
    try {
      final pdfBytes = await _generateCertificatePdf();

      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'Faseh_Certificate.pdf',
      );
    } catch (e) {
      debugPrint('Certificate share error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر مشاركة الشهادة، حاول مرة أخرى',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
        ),
      );
    }
  }

  // ==========================================================================
  // UI
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),

        appBar: AppBar(
          backgroundColor: const Color(0xFF511281),
          foregroundColor: Colors.white,
          title: const Text(
            'شهادتي',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('children')
              .doc(widget.childId)
              .collection('certificates')
              .doc('completion')
              .get(),

          builder: (context, snapshot) {
            // =================================================================
            // Loading
            // =================================================================
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF511281),
                ),
              );
            }

            // =================================================================
            // Error
            // =================================================================
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'تعذر تحميل الشهادة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                  ),
                ),
              );
            }

            // =================================================================
            // Certificate not issued yet
            // =================================================================
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'لم يتم إصدار الشهادة بعد',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                  ),
                ),
              );
            }

            // =================================================================
            // Certificate Data
            // =================================================================
            final data = snapshot.data!.data()!;

            final String fullName =
                data['fullNameAtIssue']?.toString() ?? '';

            final String templateType =
                data['templateType']?.toString() ?? 'young';

            final List<String> completedLetters = List<String>.from(
              data['completedLetters'] ?? [],
            );

            final Timestamp? completionDate =
                data['completionDate'] as Timestamp?;

            final String dateText = completionDate == null
                ? ''
                : _formatDate(completionDate);

            final bool isYoung = templateType == 'young';

            final String templatePath = isYoung
                ? 'assets/images/certificates/certificate_young.png'
                : 'assets/images/certificates/certificate_older.png';

            // =================================================================
            // Certificate + buttons
            // =================================================================
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 24,
              ),

              child: Column(
                children: [
                  // ===========================================================
                  // ONLY THIS PART WILL BE CAPTURED IN THE PDF
                  // ===========================================================
                  RepaintBoundary(
                    key: _certificateKey,

                    child: AspectRatio(
                      aspectRatio: 2048 / 1448,

                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final height = constraints.maxHeight;

                          return Stack(
                            children: [
                              // ===============================================
                              // Certificate Background
                              // ===============================================
                              Positioned.fill(
                                child: Image.asset(
                                  templatePath,
                                  fit: BoxFit.contain,
                                ),
                              ),

                              // ===============================================
                              // Child Name
                              // ===============================================
                              Positioned(
                                left: isYoung
                                    ? width * 0.378
                                    : width * 0.255,

                                right: isYoung
                                    ? width * 0.195
                                    : width * 0.255,

                                top: isYoung
                                    ? height * 0.426
                                    : height * 0.310,

                                height: isYoung
                                    ? height * 0.103
                                    : height * 0.095,

                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,

                                    child: Text(
                                      fullName,
                                      textAlign: TextAlign.center,
                                      textDirection: TextDirection.rtl,

                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: width * 0.030,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF511281),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // ===============================================
                              // Completed Letters
                              // ===============================================
                              Positioned(
                                left: width * 0.27,
                                right: width * 0.12,

                                top: isYoung
                                    ? height * 0.61
                                    : height * 0.565,

                                height: height * 0.12,

                                child: Center(
                                  child: _DynamicLetters(
                                    letters: completedLetters,
                                    isYoung: isYoung,
                                  ),
                                ),
                              ),

                              // ===============================================
                              // Completion Date
                              // ===============================================
                              Positioned(
                                left: isYoung
                                    ? width * 0.494
                                    : width * 0.700,

                                top: isYoung
                                    ? height * 0.814
                                    : height * 0.812,

                                width: isYoung
                                    ? width * 0.194
                                    : width * 0.205,

                                height: isYoung
                                    ? height * 0.058
                                    : height * 0.055,

                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,

                                    child: Text(
                                      dateText,
                                      textAlign: TextAlign.center,
                                      textDirection: TextDirection.rtl,

                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: isYoung
                                            ? width * 0.018
                                            : width * 0.016,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF7656A3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===========================================================
                  // PDF Actions
                  // ===========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveCertificatePdf,

                          icon: const Icon(
                            Icons.download_rounded,
                          ),

                          label: const Text(
                            'حفظ PDF',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF511281),
                            foregroundColor: Colors.white,

                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shareCertificatePdf,

                          icon: const Icon(
                            Icons.share_rounded,
                          ),

                          label: const Text(
                            'مشاركة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF511281),

                            side: const BorderSide(
                              color: Color(0xFF511281),
                              width: 1.5,
                            ),

                            padding: const EdgeInsets.symmetric(
                              vertical: 13,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// Dynamic Letter Shapes
// ============================================================================

class _DynamicLetters extends StatelessWidget {
  final List<String> letters;
  final bool isYoung;

  const _DynamicLetters({
    required this.letters,
    required this.isYoung,
  });

  // ==========================================================================
  // Young Template Colors
  // ==========================================================================
  static const List<Color> _youngColors = [
    Color(0xFFEADFFA),
    Color(0xFFFFE1E8),
    Color(0xFFFFF0CC),
    Color(0xFFD9F0E6),
    Color(0xFFEADFFA),
    Color(0xFFFFE1E8),
  ];

  // ==========================================================================
  // Older Template Colors
  // ==========================================================================
  static const List<Color> _olderColors = [
    Color(0xFFEADFFA),
    Color(0xFFFFE1E8),
    Color(0xFFFFF0CC),
    Color(0xFFD9F0E6),
    Color(0xFFEADFFA),
    Color(0xFFFFE1E8),
  ];

  @override
  Widget build(BuildContext context) {
    if (letters.isEmpty) {
      return const SizedBox.shrink();
    }

    return FittedBox(
      fit: BoxFit.scaleDown,

      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,

        children: List.generate(
          letters.length,
          (index) {
            final Color color = isYoung
                ? _youngColors[index % _youngColors.length]
                : _olderColors[index % _olderColors.length];

            return Container(
              // ==============================================================
              // Spacing
              // ==============================================================
              margin: EdgeInsets.symmetric(
                horizontal: isYoung ? 7 : 5,
              ),

              // ==============================================================
              // Size
              // Young → rounded squares
              // Older → small circles
              // ==============================================================
              width: isYoung ? 72 : 30,
              height: isYoung ? 66 : 30,

              alignment: Alignment.center,

              decoration: BoxDecoration(
                color: color,

                borderRadius: isYoung
                    ? BorderRadius.circular(22)
                    : null,

                shape: isYoung
                    ? BoxShape.rectangle
                    : BoxShape.circle,
              ),

              // ==============================================================
              // Letter
              // ==============================================================
              child: Text(
                letters[index],
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: isYoung ? 31 : 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF511281),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}