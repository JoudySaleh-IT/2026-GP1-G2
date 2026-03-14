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
  const LetterIntroductionScreen({super.key, required this.letter});

  @override
  State<LetterIntroductionScreen> createState() =>
      _LetterIntroductionScreenState();
}

class _LetterIntroductionScreenState extends State<LetterIntroductionScreen>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  String get _sampleWord =>
      _sampleWords[widget.letter] ?? 'خَرُوف';

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bounceAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

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
      arguments: {'letter': widget.letter},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: Column(
          children: [
            _IntroHeader(letter: widget.letter),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
                          offset: Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'مخرج الحرف ${widget.letter}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFF511281).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF511281).withOpacity(0.25),
                            width: 2,
                          ),
                        ),
                        child: const _DashedBorderBox(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_rounded,
                                size: 64,
                                color: Color(0xFF511281),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'صورة مخرج الحرف',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AnimatedBuilder(
                        animation: _bounceAnim,
                        builder: (_, child) => Transform.scale(
                          scale: _bounceAnim.value,
                          child: child,
                        ),
                        child: Text(
                          _sampleWord,
                          style: const TextStyle(
                            fontSize: 52,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _handlePlayAudio,
                        icon: Icon(
                          _isPlaying
                              ? Icons.volume_up_rounded
                              : Icons.volume_up_outlined,
                          color: const Color(0xFFFF6969),
                          size: 18,
                        ),
                        label: Text(
                          _isPlaying
                              ? 'جاري التشغيل...'
                              : 'استمع إلى الكلمة',
                          style: const TextStyle(
                            color: Color(0xFFFF6969),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFFF6969), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6969),
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                                vertical: 18),
                            elevation: 4,
                            shadowColor: const Color(0xFFFF6969)
                                .withOpacity(0.4),
                          ),
                          child: const Text(
                            'ابدأ التمرين',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
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
          BoxShadow(
              color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
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
              child: Container(
                width: 34,
                height: 34,
                child: const Icon(Icons.arrow_back,
                    color: Colors.white, size: 25),
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

class _DashedBorderBox extends StatelessWidget {
  final Widget child;
  const _DashedBorderBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: child,
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF511281).withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 8.0;
    const dashSpace = 5.0;
    const radius = Radius.circular(16);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2), radius));

    final ui.PathMetrics pathMetrics = path.computeMetrics();
    for (final ui.PathMetric pm in pathMetrics) {
      double distance = 0;
      while (distance < pm.length) {
        canvas.drawPath(
          pm.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}