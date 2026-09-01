import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ExerciseRecordingResultScreen extends StatelessWidget {
  const ExerciseRecordingResultScreen({super.key});

  // -------------------------------------------------------------------------
  // Helpers
  // نفس منطق النتيجة
  // -------------------------------------------------------------------------

  String _resultMessage(int pct) {
    if (pct == 100) {
      return 'ممتاز! أتقنت جميع التمارين';
    }

    if (pct >= 80) {
      return 'رائع! أداء متميز جدًا';
    }

    if (pct >= 60) {
      return 'أحسنت! استمر وستتقدم أكثر';
    }

    return 'استمر في التدريب، أنت تتحسن';
  }

  Color _resultColor(int pct) {
    if (pct == 100) {
      return const Color(0xFFE5A52F);
    }

    if (pct >= 80) {
      return const Color(0xFF68A982);
    }

    if (pct >= 60) {
      return const Color(0xFF7B4AAD);
    }

    return const Color(0xFFE29A5D);
  }

  Color _resultBackground(int pct) {
    if (pct == 100) {
      return const Color(0xFFFFF8E4);
    }

    if (pct >= 80) {
      return const Color(0xFFF0F9F3);
    }

    if (pct >= 60) {
      return const Color(0xFFF7F0FF);
    }

    return const Color(0xFFFFF4E9);
  }

  // نفس الدوال موجودة للحفاظ على منطق عرض الدرجات
  Color _scoreColor(int s) {
    if (s >= 90) {
      return const Color(0xFF5E9D77);
    }

    if (s >= 70) {
      return const Color(0xFF7B4AAD);
    }

    if (s >= 50) {
      return const Color(0xFFC89048);
    }

    return const Color(0xFFD47C68);
  }

  Color _scoreBg(int s) {
    if (s >= 90) {
      return const Color(0xFFE5F4EA);
    }

    if (s >= 70) {
      return const Color(0xFFF0E6F8);
    }

    if (s >= 50) {
      return const Color(0xFFFFF2D7);
    }

    return const Color(0xFFFFE9E4);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};

    final String childId = args['childId'] ?? '';

    final int score = args['score'] ?? 85;

    final int total = args['total'] ?? 100;

    final List questions = args['questions'] ?? _defaultQuestions;

    final int pct = ((score / total) * 100).round();

    // نفس حساب النقاط
    final int pts = score * 10;

    // نفس حساب النجوم
    final int stars = pct >= 90
        ? 3
        : pct >= 70
        ? 2
        : 1;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),

        body: Column(
          children: [
            // ===============================================================
            // Header
            // ===============================================================
            const _RecordingResultHeader(),

            Expanded(
              child: Stack(
                children: [
                  // خلفية مثل نتائج الاستماع
                  const Positioned.fill(
                    child: IgnorePointer(child: _ResultBackground()),
                  ),

                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(overscroll: false),

                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

                      child: Column(
                        children: [
                          // =================================================
                          // Big Result Card
                          // =================================================
                          _ResultHeroCard(
                            pct: pct,
                            stars: stars,
                            resultMessage: _resultMessage(pct),
                            resultColor: _resultColor(pct),
                            resultBackground: _resultBackground(pct),
                          ),

                          const SizedBox(height: 12),

                          // =================================================
                          // Points
                          // =================================================
                          _PointsCard(points: pts),

                          const SizedBox(height: 18),

                          // =================================================
                          // Pronunciation details
                          // =================================================
                          _buildDetailsCard(questions),

                          const SizedBox(height: 18),

                          // =================================================
                          // Home
                          // نفس functionality
                          // =================================================
                          SizedBox(
                            width: double.infinity,

                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    '/child/home',
                                    (r) => false,
                                    arguments: childId,
                                  ),

                              icon: const Icon(Icons.home_rounded, size: 18),

                              label: const Text(
                                'العودة للرئيسية',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6969),

                                foregroundColor: Colors.white,

                                elevation: 0,

                                shape: const StadiumBorder(),

                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
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

  // -------------------------------------------------------------------------
  // Details Card
  // -------------------------------------------------------------------------

  Widget _buildDetailsCard(List questions) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.fromLTRB(14, 15, 14, 7),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: const Color(0xFF511281).withOpacity(0.07),
          width: 1.2,
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // ===============================================================
          // Title
          // ===============================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),

            child: Row(
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

                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      'نتائج نطقك',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF511281),
                      ),
                    ),

                    SizedBox(height: 1),

                    Text(
                      'شاهد أداءك في كل تمرين',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ===============================================================
          // Empty
          // ===============================================================
          if (questions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),

              child: Center(
                child: Text(
                  'لا توجد تفاصيل للتمارين',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            )
          // ===============================================================
          // Questions
          // ===============================================================
          else
            ...questions.asMap().entries.map((entry) {
              final int idx = entry.key;

              final Map q = entry.value as Map;

              final String qTxt = q['questionText'] as String? ?? '';

              final int qScr = q['score'] as int? ?? 0;

              // نفس threshold الحالي
              final bool good = qScr >= 70;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),

                child: _PronunciationResultTile(
                  number: idx + 1,
                  text: qTxt,
                  score: qScr,
                  good: good,
                  scoreColor: _scoreColor(qScr),
                  scoreBackground: _scoreBg(qScr),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Result Card
// نفس أسلوب نتائج الاستماع
// ---------------------------------------------------------------------------

class _ResultHeroCard extends StatelessWidget {
  final int pct;
  final int stars;

  final String resultMessage;

  final Color resultColor;
  final Color resultBackground;

  const _ResultHeroCard({
    required this.pct,
    required this.stars,
    required this.resultMessage,
    required this.resultColor,
    required this.resultBackground,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = pct / 100;

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: resultBackground,

        borderRadius: BorderRadius.circular(28),

        border: Border.all(
          color: const Color(0xFF511281).withOpacity(0.08),
          width: 1.3,
        ),

        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),

        child: Stack(
          children: [
            // Purple background circle
            Positioned(
              right: -45,
              top: -55,

              child: Container(
                width: 145,
                height: 145,

                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5).withOpacity(0.28),

                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Pink background circle
            Positioned(
              left: 40,
              bottom: -60,

              child: Container(
                width: 140,
                height: 110,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9E2).withOpacity(0.35),

                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),

              child: Column(
                children: [
                  Row(
                    children: [
                      // =====================================================
                      // Score
                      // =====================================================
                      SizedBox(
                        width: 105,
                        height: 105,

                        child: Stack(
                          alignment: Alignment.center,

                          children: [
                            SizedBox(
                              width: 96,
                              height: 96,

                              child: CircularProgressIndicator(
                                value: progress,

                                strokeWidth: 8,

                                backgroundColor: Colors.white,

                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF6969),
                                ),
                              ),
                            ),

                            Container(
                              width: 76,
                              height: 76,

                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.90),

                                shape: BoxShape.circle,
                              ),

                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [
                                  Text(
                                    '$pct%',

                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF511281),
                                    ),
                                  ),

                                  const Text(
                                    'نتيجة النطق',
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 8.5,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // =====================================================
                      // Message
                      // =====================================================
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'أحسنت!',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF511281),
                              ),
                            ),

                            const SizedBox(height: 5),

                            Text(
                              resultMessage,

                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12.5,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: resultColor,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.72),

                                borderRadius: BorderRadius.circular(18),
                              ),

                              child: const Text(
                                'متوسط درجات النطق',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 9.5,
                                  color: Color(0xFF777777),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 5),

                      // =====================================================
                      // نفس شخصية نتائج الاستماع
                      // =====================================================
                      const SizedBox(
                        width: 65,
                        height: 92,
                        child: _SimpleCuteBunny(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =========================================================
                  // Stars
                  // =========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: List.generate(3, (index) {
                      final bool filled = index < stars;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),

                        width: 31,
                        height: 31,

                        decoration: BoxDecoration(
                          color: filled
                              ? const Color(0xFFFFE9AE)
                              : Colors.white.withOpacity(0.82),

                          shape: BoxShape.circle,
                        ),

                        child: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,

                          color: filled
                              ? const Color(0xFFECAF28)
                              : const Color(0xFFD4CADB),

                          size: 18,
                        ),
                      );
                    }),
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

// ---------------------------------------------------------------------------
// Points Card
// ---------------------------------------------------------------------------

class _PointsCard extends StatelessWidget {
  final int points;

  const _PointsCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E5),

        borderRadius: BorderRadius.circular(20),

        border: Border.all(color: const Color(0xFFF4C466).withOpacity(0.24)),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: const BoxDecoration(
              color: Color(0xFFFFE8A6),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.star_rounded,
              color: Color(0xFFE9A92E),
              size: 24,
            ),
          ),

          const SizedBox(width: 11),

          const Text(
            'حصلت على',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Color(0xFF666666),
            ),
          ),

          const SizedBox(width: 5),

          Text(
            '+$points نقطة',

            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 17,
              color: Color(0xFF511281),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual pronunciation result
// ---------------------------------------------------------------------------

class _PronunciationResultTile extends StatelessWidget {
  final int number;

  final String text;
  final int score;

  final bool good;

  final Color scoreColor;
  final Color scoreBackground;

  const _PronunciationResultTile({
    required this.number,
    required this.text,
    required this.score,
    required this.good,
    required this.scoreColor,
    required this.scoreBackground,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = good
        ? const Color(0xFFF2F9F4)
        : const Color(0xFFFFF5EC);

    final Color accentColor = good
        ? const Color(0xFF77AD8B)
        : const Color(0xFFDFA064);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),

      decoration: BoxDecoration(
        color: cardColor,

        borderRadius: BorderRadius.circular(18),
      ),

      child: Row(
        children: [
          // Number
          Container(
            width: 34,
            height: 34,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.13),

              shape: BoxShape.circle,
            ),

            child: Text(
              '$number',

              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accentColor,
              ),
            ),
          ),

          const SizedBox(width: 11),

          // Word
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  text,

                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  good ? 'أداء جميل' : 'تحتاج إلى تدريب أكثر',

                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 9.5,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Score
          Container(
            width: 53,
            height: 38,

            alignment: Alignment.center,

            decoration: BoxDecoration(
              color: scoreBackground,

              borderRadius: BorderRadius.circular(15),
            ),

            child: Text(
              '$score%',

              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// نفس التصميم، فقط الاسم الظاهر أصبح "النطق"
// ---------------------------------------------------------------------------

class _RecordingResultHeader extends StatelessWidget {
  const _RecordingResultHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,

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

      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'نتيجة تمرين النطق',

            style: TextStyle(
              color: Colors.white,

              fontSize: 17,

              fontWeight: FontWeight.w600,

              fontFamily: 'Tajawal',
            ),
          ),

          SizedBox(height: 2),

          Text(
            'ملخص أدائك',

            style: TextStyle(
              color: Colors.white70,

              fontSize: 12,

              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Background
// ---------------------------------------------------------------------------

class _ResultBackground extends StatelessWidget {
  const _ResultBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 60,
          right: -55,

          child: _circle(140, const Color(0xFFDCC9F5).withOpacity(0.17)),
        ),

        Positioned(
          top: 350,
          left: -60,

          child: _circle(145, const Color(0xFFDDF2E3).withOpacity(0.25)),
        ),

        Positioned(
          top: 650,
          right: -45,

          child: _circle(115, const Color(0xFFFFDCE3).withOpacity(0.22)),
        ),

        Positioned(
          top: 780,
          left: 35,

          child: _circle(18, const Color(0xFFD6C0EE).withOpacity(0.35)),
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
// SAME BUNNY AS LISTENING RESULT
// أذنين فقط
// ---------------------------------------------------------------------------

class _SimpleCuteBunny extends StatelessWidget {
  const _SimpleCuteBunny();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);

    const Color bodyColor = Color(0xFF8B55B3);

    return Stack(
      alignment: Alignment.center,

      clipBehavior: Clip.none,

      children: [
        // Right Ear
        Positioned(
          top: 0,
          right: 11,

          child: Container(
            width: 18,
            height: 34,

            decoration: BoxDecoration(
              color: faceColor,

              borderRadius: BorderRadius.circular(18),
            ),

            child: Center(
              child: Container(
                width: 7,
                height: 22,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFA1B7).withOpacity(0.55),

                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // Left Ear
        Positioned(
          top: 0,
          left: 11,

          child: Container(
            width: 18,
            height: 34,

            decoration: BoxDecoration(
              color: faceColor,

              borderRadius: BorderRadius.circular(18),
            ),

            child: Center(
              child: Container(
                width: 7,
                height: 22,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFA1B7).withOpacity(0.55),

                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // Body
        Positioned(
          bottom: 0,

          child: Container(
            width: 42,
            height: 27,

            decoration: const BoxDecoration(
              color: bodyColor,

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),

                topRight: Radius.circular(24),

                bottomLeft: Radius.circular(12),

                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ),

        // Head
        Positioned(
          top: 25,

          child: Container(
            width: 55,
            height: 52,

            decoration: BoxDecoration(
              color: faceColor,

              borderRadius: BorderRadius.circular(26),

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
                  top: 19,
                  right: 13,

                  child: Container(
                    width: 6,
                    height: 7,

                    decoration: const BoxDecoration(
                      color: Color(0xFF4D3855),

                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 19,
                  left: 13,

                  child: Container(
                    width: 6,
                    height: 7,

                    decoration: const BoxDecoration(
                      color: Color(0xFF4D3855),

                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 31,
                  right: 6,

                  child: Container(
                    width: 9,
                    height: 5,

                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),

                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 31,
                  left: 6,

                  child: Container(
                    width: 9,
                    height: 5,

                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),

                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 27,
                  left: 24,

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
                  top: 33,
                  left: 20,

                  child: Container(
                    width: 15,
                    height: 7,

                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF4D3855),

                          width: 1.4,
                        ),
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
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Default fallback data
// بدون تغيير
// ---------------------------------------------------------------------------

const List<Map<String, dynamic>> _defaultQuestions = [
  {'questionText': 'ض', 'score': 85},
  {'questionText': 'قَلَم', 'score': 78},
  {'questionText': 'مَدْرَسَة', 'score': 92},
  {'questionText': 'عَيْن', 'score': 70},
  {'questionText': 'الطَّالِبُ يَدْرُسُ', 'score': 88},
];
