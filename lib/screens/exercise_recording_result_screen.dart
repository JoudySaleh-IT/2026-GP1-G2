import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ExerciseRecordingResultScreen extends StatelessWidget {
  const ExerciseRecordingResultScreen({super.key});

  // ── Helpers (mirrors listening result logic) ───────────────────────────────

  String _resultMessage(int pct) {
    if (pct == 100) return 'ممتاز! أتقنت جميع التمارين! 🏆';
    if (pct >= 80) return 'رائع! أداء متميز جداً! 🌟';
    if (pct >= 60) return 'جيد! يمكنك تحسين أدائك! 💪';
    return 'استمر في التدريب، ستتحسن! 🌱';
  }

  Color _resultColor(int pct) {
    if (pct == 100) return const Color(0xFFB45309); // amber
    if (pct >= 80) return const Color(0xFF16A34A); // green
    if (pct >= 60) return const Color(0xFF2563EB); // blue
    return const Color(0xFFEA580C); // orange
  }

  Color _scoreColor(int s) {
    if (s >= 90) return Colors.green;
    if (s >= 70) return const Color(0xFF2563EB);
    if (s >= 50) return const Color(0xFFCA8A04);
    return Colors.red;
  }

  Color _scoreBg(int s) {
    if (s >= 90) return const Color(0xFFDCFCE7);
    if (s >= 70) return const Color(0xFFDBEAFE);
    if (s >= 50) return const Color(0xFFFEF9C3);
    return const Color(0xFFFFE4E4);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};

    final int score = args['score'] ?? 85;
    final int total = args['total'] ?? 100;
    final List questions = args['questions'] ?? _defaultQuestions;

    final int pct = ((score / total) * 100).round();
    final int pts = score * 10;
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
            // ── Header ───────────────────────────────────────────────────────
            _RecordingResultHeader(
              onBack: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/child/exercises',
                (r) => false,
              ),
            ),

            // ── Scrollable content ────────────────────────────────────────────
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Column(
                    children: [
                      // ── Score hero card ────────────────────────────────────
                      _buildScoreCard(pct: pct, stars: stars),

                      const SizedBox(height: 12),

                      // ── Result message card ────────────────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
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
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _resultMessage(pct),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: _resultColor(pct),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Earned points card (recording-only) ────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
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
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.trending_up_rounded,
                              color: Color(0xFFFF6969),
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '+$pts',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF511281),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'نقطة مكتسبة',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Details breakdown card ─────────────────────────────
                      _buildDetailsCard(questions),

                      const SizedBox(height: 20),

                      // ── Home button ────────────────────────────────────────
                      Row(
                        children: [
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
                                  vertical: 14,
                                ),
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
            ),
          ],
        ),
      ),
    );
  }

  // ── Score hero card ────────────────────────────────────────────────────────

  Widget _buildScoreCard({required int pct, required int stars}) {
    return Container(
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
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
        ),
        child: Column(
          children: [
            // Stars row — gold filled, white empty (same as listening)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                final filled = i < stars;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
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

            // Big percentage number
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$pct',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '%',
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'متوسط درجات النطق',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Details breakdown card ─────────────────────────────────────────────────

  Widget _buildDetailsCard(List questions) {
    return Container(
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
            offset: Offset(0, 2),
          ),
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
          if (questions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'لا توجد تفاصيل لكل سؤال',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...questions.asMap().entries.map((entry) {
              final idx = entry.key;
              final q = entry.value as Map;
              final qTxt = q['questionText'] as String? ?? '';
              final qScr = q['score'] as int? ?? 0;
              final bool good = qScr >= 70;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: good
                        ? Colors.green.withOpacity(0.06)
                        : Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: good
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Numbered circle — green/red like listening
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: good ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Exercise text
                      Expanded(
                        child: Text(
                          qTxt,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Score circle (kept from recording result)
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _scoreBg(qScr),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$qScr%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _scoreColor(qScr),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — mirrors _ResultHeader from listening result
// ---------------------------------------------------------------------------

class _RecordingResultHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _RecordingResultHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: _HeaderIconBtn(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نتيجة تمرين التسجيل',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'ملخص أدائك',
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
// Default fallback data
// ---------------------------------------------------------------------------

const List<Map<String, dynamic>> _defaultQuestions = [
  {'questionText': 'ض', 'score': 85},
  {'questionText': 'قَلَم', 'score': 78},
  {'questionText': 'مَدْرَسَة', 'score': 92},
  {'questionText': 'عَيْن', 'score': 70},
  {'questionText': 'الطَّالِبُ يَدْرُسُ', 'score': 88},
];

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 34,
      height: 34,
      child: Icon(icon, color: Colors.white, size: 25),
    ),
  );
}
