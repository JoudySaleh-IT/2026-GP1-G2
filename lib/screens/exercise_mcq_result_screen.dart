import 'package:flutter/material.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _purple  = Color(0xFF511281);
const _purple2 = Color(0xFF6A3A9E);
const _coral   = Color(0xFFFF6969);
const _bgColor = Color(0xFFFCF9EA);

// ─── Result Message ───────────────────────────────────────────────────────────
({String text, Color color}) _getResultMessage(int score, int total) {
  final ratio = score / total;
  if (ratio == 1)   return (text: 'ممتاز! أتقنت جميع الأسئلة! 🏆', color: const Color(0xFFB45309));
  if (ratio >= 0.8) return (text: 'رائع! أداء متميز جداً! 🌟',       color: const Color(0xFF16A34A));
  if (ratio >= 0.6) return (text: 'جيد! يمكنك تحسين أدائك! 💪',      color: const Color(0xFF2563EB));
  return                   (text: 'استمر في التدريب، ستتحسن! 🌱',      color: const Color(0xFFEA580C));
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ExerciseMCQResultScreen extends StatelessWidget {
  final int score;
  final int total;
  final List<Map<String, dynamic>> answers;
  final List<Map<String, dynamic>> questions;
  final String letter;

  const ExerciseMCQResultScreen({
    super.key,
    required this.score,
    required this.total,
    required this.answers,
    required this.questions,
    required this.letter,
  });

  @override
  Widget build(BuildContext context) {
    final result     = _getResultMessage(score, total);
    final percentage = (score / total * 100).round();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildScoreCard(percentage, result),
                    const SizedBox(height: 16),
                    _buildBreakdownCard(),
                    const SizedBox(height: 24),
                    _buildHomeButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────
 // ── Header ──────────────────────────────────────────────────────────────────
Widget _buildHeader(BuildContext context) {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black26,
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 8,
      bottom: 12,
      right: 16,
      left: 16,
    ),
    child: Row(
      textDirection: TextDirection.rtl,
      children: const [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نتيجة التمرين',
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
      ],
    ),
  );
}

  // ── Score Card ──────────────────────────────────────────────────────────────
  Widget _buildScoreCard(
      int percentage, ({String text, Color color}) result) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withOpacity(0.1), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Purple gradient section
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_purple2, _purple],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              children: [
                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) {
                    final filled = i < score;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: filled
                            ? const Color(0xFFFFD700)
                            : Colors.white30,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Big score
                RichText(
                  textDirection: TextDirection.ltr,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$score',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      TextSpan(
                        text: '/$total',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white54,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$percentage% إجابات صحيحة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),

          // Result message
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Text(
              result.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: result.color,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Breakdown Card ──────────────────────────────────────────────────────────
  Widget _buildBreakdownCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withOpacity(0.1), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              'تفاصيل الإجابات',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: List.generate(questions.length, (i) {
                final ans        = answers[i];
                final isCorrect  = ans['selected'] == ans['correct'];
                final opts       = List<String>.from(questions[i]['options']);
                final selectedText = opts[ans['selected'] as int];
                final correctText  = opts[ans['correct'] as int];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? Colors.green.withOpacity(0.06)
                        : Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question row
                      Row(
                        textDirection: TextDirection.rtl,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? Colors.green.shade500
                                  : Colors.red.shade500,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              questions[i]['question'] as String,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF444444),
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Wrong answer details
                      if (!isCorrect) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.only(start: 40),
                          child: RichText(
                            textDirection: TextDirection.rtl,
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'إجابتك: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFDC2626),
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                TextSpan(
                                  text: selectedText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDC2626),
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.only(start: 40),
                          child: RichText(
                            textDirection: TextDirection.rtl,
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'الإجابة الصحيحة: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                TextSpan(
                                  text: correctText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF16A34A),
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // ── Home Button ─────────────────────────────────────────────────────────────
  Widget _buildHomeButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/child/home'),
        icon: const Icon(Icons.home_rounded, size: 20),
        label: const Text(
          'الرئيسية',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _coral,
          foregroundColor: Colors.white,
          elevation: 3,
          shadowColor: _coral.withOpacity(0.4),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}