import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class ExerciseListeningResultScreen extends StatelessWidget {
  const ExerciseListeningResultScreen({super.key});

  String _resultMessage(int score, int total) {
    final ratio = score / total;

    if (ratio == 1) {
      return 'ممتاز! أتقنت جميع الأسئلة';
    }

    if (ratio >= 0.8) {
      return 'رائع! أداء متميز جدًا';
    }

    if (ratio >= 0.6) {
      return 'أحسنت! استمر وستتقدم أكثر';
    }

    return 'استمر في التدريب، أنت تتحسن';
  }

  @override
  Widget build(BuildContext context) {
    // ───────────────────────────────────────────────────────────────────────
    // نفس الـ arguments الحالية
    // ───────────────────────────────────────────────────────────────────────
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    final int score = args['score'] as int;
    final int total = args['total'] as int;

    final List<Map<String, String>> answers = List<Map<String, String>>.from(
      args['answers'] as List,
    );

    final int percentage = ((score / total) * 100).round();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),

        body: Column(
          children: [
            // ==============================================================
            // HEADER
            // نفس الهيدر
            // ==============================================================
            const _ResultHeader(),

            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(child: _SimpleResultBackground()),
                  ),

                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

                    child: Column(
                      children: [
                        // ─── Result Summary
                        // ─── Result Summary
                        _ResultHeroCard(
                          score: score,
                          total: total,
                          percentage: percentage,
                          resultMessage: _resultMessage(score, total),
                        ),

                        const SizedBox(height: 12),

                        // ─── Points
                        _PointsCard(score: score, total: total),

                        const SizedBox(height: 14),

                        // ─── Answers
                        _AnswersCard(answers: answers),

                        const SizedBox(height: 18),

                        // ==================================================
                        // HOME BUTTON
                        // نفس الـ functionality
                        // ==================================================
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/child/home',
                              (route) => false,
                              arguments: args['childId'] ?? '',
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple Result Card
// ─────────────────────────────────────────────────────────────────────────────
class _ResultHeroCard extends StatelessWidget {
  final int score;
  final int total;
  final int percentage;
  final String resultMessage;

  const _ResultHeroCard({
    required this.score,
    required this.total,
    required this.percentage,
    required this.resultMessage,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = total == 0 ? 0 : score / total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
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
            // دائرة موف خفيفة
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

            // دائرة وردية خفيفة
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
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                children: [
                  Row(
                    children: [
                      // ─── Score Circle
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
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$percentage%',
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF511281),
                                    ),
                                  ),

                                  Text(
                                    '$score من $total',
                                    style: const TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 9.5,
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

                      // ─── Result message
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
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12.5,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      // الأرنب الحالي المصحح
                      const SizedBox(
                        width: 65,
                        height: 92,
                        child: _SimpleCuteBunny(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ─── Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(total, (index) {
                      final bool correct = index < score;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: correct
                              ? const Color(0xFFFFE9AE)
                              : Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          correct ? Icons.star_rounded : Icons.circle_outlined,
                          color: correct
                              ? const Color(0xFFECAF28)
                              : const Color(0xFFD4CADB),
                          size: correct ? 18 : 11,
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

// ─────────────────────────────────────────────────────────────────────────────
// Points Card
// نفس حساب النقاط
// ─────────────────────────────────────────────────────────────────────────────
class _PointsCard extends StatelessWidget {
  final int score;
  final int total;

  const _PointsCard({required this.score, required this.total});

  int get _earnedPoints {
    final ratio = score / total;

    if (ratio == 1) return 1000;
    if (ratio >= 0.8) return 800;
    if (ratio >= 0.6) return 500;

    return 200;
  }

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
              fontSize: 12,
              color: Color(0xFF666666),
              fontFamily: 'Tajawal',
            ),
          ),

          const SizedBox(width: 5),

          Text(
            '+$_earnedPoints نقطة',
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF511281),
              fontWeight: FontWeight.w700,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Answers Card
// ─────────────────────────────────────────────────────────────────────────────
class _AnswersCard extends StatelessWidget {
  final List<Map<String, String>> answers;

  const _AnswersCard({required this.answers});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
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
          // ─── Title ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1E8FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fact_check_rounded,
                    color: Color(0xFF7B4AAD),
                    size: 20,
                  ),
                ),

                const SizedBox(width: 9),

                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إجاباتك',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF511281),
                      ),
                    ),

                    SizedBox(height: 1),

                    Text(
                      'شاهد كيف كان أداؤك',
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

          ...answers.asMap().entries.map((entry) {
            final int index = entry.key;
            final Map<String, String> answer = entry.value;

            final bool isCorrect = answer['selected'] == answer['correct'];

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AnswerResultTile(
                number: index + 1,
                answer: answer,
                isCorrect: isCorrect,
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Answer Result Tile
// ─────────────────────────────────────────────────────────────────────────────
class _AnswerResultTile extends StatelessWidget {
  final int number;
  final Map<String, String> answer;
  final bool isCorrect;

  const _AnswerResultTile({
    required this.number,
    required this.answer,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    // ألوان pastel هادئة بدل الأخضر والأحمر القوي
    final Color accentColor = isCorrect
        ? const Color(0xFF78B997)
        : const Color(0xFFE7A267);

    final Color cardColor = isCorrect
        ? const Color(0xFFF1F9F4)
        : const Color(0xFFFFF5EC);

    final Color bubbleColor = isCorrect
        ? const Color(0xFFDDF1E5)
        : const Color(0xFFFFE5CF);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────────────────
          // Question row
          // ─────────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // رقم السؤال
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bubbleColor,
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

              const SizedBox(width: 10),

              // السؤال
              Expanded(
                child: Text(
                  answer['instruction'] ?? '',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3F3F3F),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // الحالة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_rounded : Icons.refresh_rounded,
                      size: 14,
                      color: accentColor,
                    ),

                    const SizedBox(width: 3),

                    Text(
                      isCorrect ? 'صحيح' : 'راجعها',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ─────────────────────────────────────────────────────────
          // Wrong-answer details
          // تظهر فقط إذا الإجابة خطأ
          // ─────────────────────────────────────────────────────────
          if (!isCorrect) ...[
            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.only(right: 44),
              child: Column(
                children: [
                  // إجابة الطفل
                  _SmallAnswerBubble(
                    icon: Icons.person_outline_rounded,
                    title: 'إجابتك',
                    value: answer['selected'] ?? '',
                    color: const Color(0xFFD1905C),
                    backgroundColor: const Color(0xFFFFFBF7),
                  ),

                  const SizedBox(height: 6),

                  // الإجابة الصحيحة
                  _SmallAnswerBubble(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'الإجابة الصحيحة',
                    value: answer['correct'] ?? '',
                    color: const Color(0xFF669E7E),
                    backgroundColor: const Color(0xFFF8FCF9),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small Answer Bubble
// ─────────────────────────────────────────────────────────────────────────────
class _SmallAnswerBubble extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color backgroundColor;

  const _SmallAnswerBubble({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 15),
          ),

          const SizedBox(width: 8),

          Text(
            '$title:',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: Color(0xFF777777),
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER
// نفس الهيدر الحالي
// ─────────────────────────────────────────────────────────────────────────────
class _ResultHeader extends StatelessWidget {
  const _ResultHeader();

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
        bottom: 14,
        right: 16,
        left: 16,
      ),

      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'نتيجة تمرين الاستماع',
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

// ─────────────────────────────────────────────────────────────────────────────
// Simple Background
// أقل زحمة
// ─────────────────────────────────────────────────────────────────────────────
class _SimpleResultBackground extends StatelessWidget {
  const _SimpleResultBackground();

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

// ─────────────────────────────────────────────────────────────────────────────
// Simple Cute Bunny
// أذنين فقط فوق الرأس
// بدون أذرع أو أشكال إضافية
// ─────────────────────────────────────────────────────────────────────────────
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
        // ─── Right Ear
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

        // ─── Left Ear
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

        // ─── Body
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

        // ─── Head
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
