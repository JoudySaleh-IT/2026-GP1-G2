import 'dart:ui' as ui;
import 'package:flutter/material.dart';

const _sampleWords = {
  'ض': 'ضَبْع',
  'ح': 'حَمَام',
  'خ': 'خَرُوف',
  'ص': 'صَقْر',
  'ق': 'قَلَم',
  'ع': 'عَيْن',
  'غ': 'غَزَال',
  'ظ': 'ظَبْي',
  'ط': 'طَاوُوس',
  'س': 'َسَمَك',
};

class LetterIntroductionScreen extends StatefulWidget {
  final String letter;
  final String childId;

  const LetterIntroductionScreen({
    super.key,
    required this.letter,
    required this.childId,
  });

  @override
  State<LetterIntroductionScreen> createState() =>
      _LetterIntroductionScreenState();
}

class _LetterIntroductionScreenState extends State<LetterIntroductionScreen>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  String get _sampleWord => _sampleWords[widget.letter] ?? 'خَرُوف';

  @override
  void initState() {
    super.initState();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _bounceAnim = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Functionality - بدون تغيير
  // -------------------------------------------------------------------------

  void _handlePlayAudio() {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);

    _bounceCtrl.repeat(reverse: true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isPlaying = false);

        _bounceCtrl.stop();
        _bounceCtrl.reset();
      }
    });
  }

  void _handleContinue() {
    Navigator.pushNamed(
      context,
      '/child/exercise/recording',
      arguments: {'letter': widget.letter, 'childId': widget.childId},
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),

        body: Column(
          children: [
            // ===============================================================
            // Header - نفس الهيدر
            // ===============================================================
            _IntroHeader(letter: widget.letter),

            // ===============================================================
            // Content
            // ===============================================================
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(child: _IntroBackground()),
                  ),

                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 35),

                    child: Column(
                      children: [
                        // ===================================================
                        // Welcome card
                        // ===================================================
                        _buildWelcomeCard(),

                        const SizedBox(height: 13),

                        // ===================================================
                        // Mouth placement
                        // ===================================================
                        _buildMouthCard(),

                        const SizedBox(height: 13),

                        // ===================================================
                        // Example word
                        // ===================================================
                        _buildWordCard(),

                        const SizedBox(height: 15),

                        // ===================================================
                        // Continue
                        // ===================================================
                        _buildContinueButton(),
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

  // -------------------------------------------------------------------------
  // Welcome Card
  // -------------------------------------------------------------------------

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 125),

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
            // Purple decoration
            Positioned(
              right: -40,
              top: -55,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5).withOpacity(0.32),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Pink decoration
            Positioned(
              left: 35,
              bottom: -55,
              child: Container(
                width: 125,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9E2).withOpacity(0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),

              child: Row(
                children: [
                  // Character
                  const SizedBox(
                    width: 83,
                    height: 105,
                    child: _CuteIntroCharacter(),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        const Text(
                          'هيا نتعلم النطق!',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF511281),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'شاهد مخرج الحرف، ثم استمع إلى الكلمة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11.5,
                            height: 1.5,
                            color: Color(0xFF777777),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.78),
                            borderRadius: BorderRadius.circular(18),
                          ),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'حرف اليوم',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 10,
                                  color: Color(0xFF888888),
                                ),
                              ),

                              const SizedBox(width: 7),

                              Text(
                                widget.letter,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 21,
                                  height: 1,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF511281),
                                ),
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
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Mouth Placement Card
  // -------------------------------------------------------------------------

  Widget _buildMouthCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: const Color(0xFF511281).withOpacity(0.07)),

        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration: const BoxDecoration(
                  color: Color(0xFFF1E8FA),
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: Color(0xFF7B4AAD),
                  size: 20,
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'مخرج الحرف ${widget.letter}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 1),

                    const Text(
                      'لاحظ مكان خروج الصوت',
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

          const SizedBox(height: 13),

          Container(
            width: double.infinity,
            height: 190,

            decoration: BoxDecoration(
              color: const Color(0xFFF9F5FC),
              borderRadius: BorderRadius.circular(19),
            ),

            child: _DashedBorderBox(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0E5F8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.image_rounded,
                      size: 34,
                      color: Color(0xFF7B4AAD),
                    ),
                  ),

                  const SizedBox(height: 9),

                  const Text(
                    'صورة مخرج الحرف',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 11,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Word Card
  // -------------------------------------------------------------------------

  Widget _buildWordCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),

      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F8),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(color: const Color(0xFFFF6969).withOpacity(0.09)),
      ),

      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hearing_rounded, color: Color(0xFFFF6969), size: 18),

              SizedBox(width: 6),

              Text(
                'استمع ثم حاول نطقها',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          AnimatedBuilder(
            animation: _bounceAnim,

            builder: (_, child) =>
                Transform.scale(scale: _bounceAnim.value, child: child),

            child: Text(
              _sampleWord,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 48,
                color: Color(0xFF511281),
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 14),

          OutlinedButton.icon(
            // نفس الـfunctionality
            onPressed: _handlePlayAudio,

            icon: Icon(
              _isPlaying ? Icons.volume_up_rounded : Icons.volume_up_outlined,
              color: const Color(0xFFFF6969),
              size: 18,
            ),

            label: Text(
              _isPlaying ? 'جاري التشغيل...' : 'استمع إلى الكلمة',

              style: const TextStyle(
                color: Color(0xFFFF6969),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),

            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,

              side: BorderSide(
                color: const Color(0xFFFF6969).withOpacity(0.45),
              ),

              shape: const StadiumBorder(),

              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Continue Button
  // -------------------------------------------------------------------------

  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,

      child: ElevatedButton(
        // نفس الـfunctionality
        onPressed: _handleContinue,

        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6969),
          foregroundColor: Colors.white,
          elevation: 0,

          shape: const StadiumBorder(),

          padding: const EdgeInsets.symmetric(vertical: 14),
        ),

        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,

          children: [
            Text(
              'ابدأ التمرين',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(width: 7),

            Icon(Icons.mic_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// نفس الهيدر الأصلي
// ---------------------------------------------------------------------------

class _IntroHeader extends StatelessWidget {
  final String letter;

  const _IntroHeader({required this.letter});

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
              borderRadius: BorderRadius.circular(8),

              onTap: () => Navigator.pop(context),

              child: const SizedBox(
                width: 34,
                height: 34,

                child: Icon(Icons.arrow_back, color: Colors.white, size: 25),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                'تعلم نطق الحرف $letter',

                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                'شاهد مخرج الحرف واستمع إلى الكلمة',

                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pastel Background
// ---------------------------------------------------------------------------

class _IntroBackground extends StatelessWidget {
  const _IntroBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 45,
          right: -55,

          child: _circle(145, const Color(0xFFDCC9F5).withOpacity(0.18)),
        ),

        Positioned(
          top: 275,
          left: -55,

          child: _circle(145, const Color(0xFFDDF2E3).withOpacity(0.27)),
        ),

        Positioned(
          top: 540,
          right: -45,

          child: _circle(120, const Color(0xFFFFDCE3).withOpacity(0.24)),
        ),

        Positioned(
          top: 720,
          left: 30,

          child: _circle(20, const Color(0xFFD6C1EF).withOpacity(0.35)),
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

// ---------------------------------------------------------------------------
// Cute Character
// نفس ستايل أرنب تمارين النطق
// ---------------------------------------------------------------------------

class _CuteIntroCharacter extends StatelessWidget {
  const _CuteIntroCharacter();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);

    const Color purple = Color(0xFF8B55B3);

    const Color pink = Color(0xFFFF96AC);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,

      children: [
        // Right ear
        Positioned(
          top: 0,
          right: 13,

          child: Container(
            width: 20,
            height: 40,

            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(22),
            ),

            child: Center(
              child: Container(
                width: 8,
                height: 26,

                decoration: BoxDecoration(
                  color: pink.withOpacity(0.48),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),

        // Left ear
        Positioned(
          top: 0,
          left: 13,

          child: Container(
            width: 20,
            height: 40,

            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(22),
            ),

            child: Center(
              child: Container(
                width: 8,
                height: 26,

                decoration: BoxDecoration(
                  color: pink.withOpacity(0.48),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),

        // Body
        Positioned(
          bottom: 0,

          child: Container(
            width: 49,
            height: 31,

            decoration: const BoxDecoration(
              color: purple,

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
          ),
        ),

        // Head
        Positioned(
          top: 30,

          child: Container(
            width: 63,
            height: 59,

            decoration: BoxDecoration(
              color: faceColor,

              borderRadius: BorderRadius.circular(29),

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
                  right: 15,

                  child: Container(
                    width: 7,
                    height: 8,

                    decoration: const BoxDecoration(
                      color: Color(0xFF4D3855),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 20,
                  left: 15,

                  child: Container(
                    width: 7,
                    height: 8,

                    decoration: const BoxDecoration(
                      color: Color(0xFF4D3855),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 34,
                  right: 7,

                  child: Container(
                    width: 10,
                    height: 6,

                    decoration: BoxDecoration(
                      color: pink.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 34,
                  left: 7,

                  child: Container(
                    width: 10,
                    height: 6,

                    decoration: BoxDecoration(
                      color: pink.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 29,
                  left: 28,

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
                  top: 36,
                  left: 23,

                  child: Container(
                    width: 18,
                    height: 8,

                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF4D3855),
                          width: 1.5,
                        ),
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

        // Small sound bubble
        Positioned(
          right: -2,
          bottom: 11,

          child: Container(
            width: 26,
            height: 26,

            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.90),
              shape: BoxShape.circle,

              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 4),
              ],
            ),

            child: const Icon(
              Icons.volume_up_rounded,
              color: Color(0xFFFF6969),
              size: 15,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Dashed border
// نفس الـfunctionality
// ---------------------------------------------------------------------------

class _DashedBorderBox extends StatelessWidget {
  final Widget child;

  const _DashedBorderBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DashedBorderPainter(), child: child);
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF511281).withOpacity(0.18)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    const radius = Radius.circular(19);

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          radius,
        ),
      );

    final ui.PathMetrics pathMetrics = path.computeMetrics();

    for (final ui.PathMetric pm in pathMetrics) {
      double distance = 0;

      while (distance < pm.length) {
        canvas.drawPath(pm.extractPath(distance, distance + dashWidth), paint);

        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
