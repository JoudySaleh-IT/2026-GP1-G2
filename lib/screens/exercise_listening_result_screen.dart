import 'package:flutter/material.dart';

// ─── Screen ──────────────────────────────────────────────────────────────────
class ExerciseListeningResultScreen extends StatelessWidget {
  const ExerciseListeningResultScreen({super.key});

  String _resultMessage(int score, int total) {
    final ratio = score / total;
    if (ratio == 1)   return 'ممتاز! أتقنت جميع الأسئلة! 🏆';
    if (ratio >= 0.8) return 'رائع! أداء متميز جداً! 🌟';
    if (ratio >= 0.6) return 'جيد! يمكنك تحسين أدائك! 💪';
    return 'استمر في التدريب، ستتحسن! 🌱';
  }

  Color _resultColor(int score, int total) {
    final ratio = score / total;
    if (ratio == 1)   return const Color(0xFFB45309); // amber
    if (ratio >= 0.8) return const Color(0xFF16A34A); // green
    if (ratio >= 0.6) return const Color(0xFF2563EB); // blue
    return const Color(0xFFEA580C);                    // orange
  }

  @override
  Widget build(BuildContext context) {
    // ── Read arguments passed from ExerciseListeningScreen ─────────────────
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final int score    = args['score'] as int;
    final int total    = args['total'] as int;
    final String letter = args['letter'] as String? ?? '';
    final List<Map<String, String>> answers =
        List<Map<String, String>>.from(args['answers'] as List);

    final int percentage = ((score / total) * 100).round();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: Column(
          children: [
            // ── Header ────────────────────────────────────────────
            _ResultHeader(),

            // ── Content ───────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  children: [
                    // ── Score hero card ──────────────────────────
                    Container(
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
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // Purple gradient top
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 28, horizontal: 16),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6A3A9E), Color(0xFF511281)],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Stars row
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(total, (i) {
                                    final filled = i < score;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child: Icon(
                                        Icons.star_rounded,
                                        size: 30,
                                        color: filled
                                            ? const Color(0xFFFBBF24)
                                            : Colors.white.withOpacity(0.3),
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 16),
                                // Big score number
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$score',
                                        style: const TextStyle(
                                          fontSize: 64,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '/$total',
                                        style: TextStyle(
                                          fontSize: 32,
                                          color:
                                              Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$percentage% إجابات صحيحة',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Result message
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _resultMessage(score, total),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: _resultColor(score, total),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Answers breakdown ────────────────────────
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'تفاصيل الإجابات',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...answers.asMap().entries.map((entry) {
                            final i = entry.key;
                            final ans = entry.value;
                            final isCorrect =
                                ans['selected'] == ans['correct'];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? Colors.green.withOpacity(0.06)
                                      : Colors.red.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isCorrect
                                        ? Colors.green.withOpacity(0.3)
                                        : Colors.red.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Question number + instruction
                                    Row(
                                      children: [
                                        Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: isCorrect
                                                ? Colors.green
                                                : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            ans['instruction'] ?? '',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Show wrong + correct only if incorrect
                                    if (!isCorrect) ...[
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 34),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'إجابتك: ${ans['selected']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFFDC2626),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'الإجابة الصحيحة: ${ans['correct']}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF16A34A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Action buttons ───────────────────────────
                    Row(
                      children: [
                       
                        // Home
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/child/home',
                              (r) => false,
                            ),
                            icon: const Icon(Icons.home_rounded, size: 18),
                            label: const Text('الرئيسية'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6969),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
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

// ─── Header ───────────────────────────────────────────────────────────────────
class _ResultHeader extends StatelessWidget {
  const _ResultHeader();

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
      child: const Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('نتيجة تمرين الاستماع',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('ملخص أدائك',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}