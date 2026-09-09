import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/arabic_numbers.dart';

// ─── Letter Name Helper ───────────────────────────────────────────────────────
String _getLetterName(String letter) {
  const names = {
    'ض': 'Dhad',
    'خ': 'Khaa',
    'ص': 'Saad',
    'ق': 'Qaf',
    'ع': 'Ayn',
    'غ': 'Ghayn',
    'ظ': 'Dhaa',
    'ط': 'Taa',
    'س': 'Seen',
    'ل': 'Lam',
    'م': 'Meem',
    'ر': 'Raa',
    'ن': 'Noon',
  };

  return names[letter] ?? letter;
}

// ─── Data Model ───────────────────────────────────────────────────────────────
class LetterScore {
  final String letter;
  final int score;

  const LetterScore({required this.letter, required this.score});
}

// ─── Placement Result Screen ──────────────────────────────────────────────────
class PlacementResultScreen extends StatefulWidget {
  final int score;
  final List<LetterScore> letterScores;
  final String childId;

  const PlacementResultScreen({
    super.key,
    required this.childId,
    required this.score,
    required this.letterScores,
  });

  @override
  State<PlacementResultScreen> createState() => _PlacementResultScreenState();
}

class _PlacementResultScreenState extends State<PlacementResultScreen> {
  String _childName = '';

  // ─── Constants ──────────────────────────────────────────────────────────────
  static const _purple = Color(0xFF511281);
  static const _purple2 = Color(0xFF6A3A9E);
  static const _coral = Color(0xFFFF6969);
  static const _bgColor = Color(0xFFFCF9EA);

  // ─── Final Placement Performance Thresholds ────────────────────────────────
  //
  // 0–50%   = مبتدئ
  // 51–79%  = متوسط
  // 80–100% = متقن
  //
  static const int _beginnerMaxScore = 50;
  static const int _masteryMinScore = 80;

  // ─── Letter Classification ─────────────────────────────────────────────────

  List<LetterScore> get _lettersToPractice =>
      widget.letterScores.where((ls) => ls.score < _masteryMinScore).toList();

  List<LetterScore> get _masteredLetters =>
      widget.letterScores.where((ls) => ls.score >= _masteryMinScore).toList();

  // ─── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _loadChildName();
    _markPlacementDone();
  }

  // ─── Load Child Name ────────────────────────────────────────────────────────
  Future<void> _loadChildName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data();

        setState(() {
          _childName = data?['name'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('خطأ أثناء جلب اسم الطفل: $e');
    }
  }

  // ─── Save Placement Result ──────────────────────────────────────────────────
  Future<void> _markPlacementDone() async {
    try {
      Map<String, int> scoresMap = {
        for (var item in widget.letterScores) item.letter: item.score,
      };

      String levelToSave;

      if (widget.score >= _masteryMinScore) {
        levelToSave = 'متقن';
      } else if (widget.score <= _beginnerMaxScore) {
        levelToSave = 'مبتدئ';
      } else {
        levelToSave = 'متوسط';
      }

      await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .update({
            'placementDone': true,
            'placementScore': widget.score,
            'placementDate': FieldValue.serverTimestamp(),
            'letterScores': scoresMap,
            'level': levelToSave,
          });

      debugPrint('✅ تم حفظ نتائج اختبار تحديد المستوى وحقل level بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ أثناء تحديث بيانات اختبار تحديد المستوى: $e');
    }
  }

  // ─── Overall Child Level ────────────────────────────────────────────────────
  String get _overallLevel {
    if (widget.score >= _masteryMinScore) {
      return 'مستوى متقن';
    }

    if (widget.score <= _beginnerMaxScore) {
      return 'مستوى مبتدئ';
    }

    return 'مستوى متوسط';
  }

  // ─── Encouragement Message ──────────────────────────────────────────────────
  String get _encouragementMessage {
    if (_childName.isEmpty) {
      if (widget.score >= _masteryMinScore) {
        return 'ممتاز!';
      }

      if (widget.score <= _beginnerMaxScore) {
        return 'بداية جميلة! سنتدرّب معًا';
      }

      return 'أحسنت!';
    }

    if (widget.score >= _masteryMinScore) {
      return 'ممتاز يا $_childName!';
    }

    if (widget.score <= _beginnerMaxScore) {
      return 'بداية جميلة يا $_childName! سنتدرّب معًا';
    }

    return 'أحسنت يا $_childName!';
  }

  // ─── Sorted Letter Scores ───────────────────────────────────────────────────
  List<LetterScore> get _sortedScores =>
      [...widget.letterScores]..sort((a, b) => a.score.compareTo(b.score));

  // ===========================================================================
  // BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: _PlacementResultBackground()),
            ),

            SafeArea(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                  child: Column(
                    children: [
                      // ======================================================
                      // HERO
                      // ======================================================
                      _buildHeroCard(),

                      const SizedBox(height: 14),

                      // ======================================================
                      // SCORE
                      // ======================================================
                      _buildScoreCard(),

                      const SizedBox(height: 14),

                      // ======================================================
                      // PRACTICE LETTERS
                      // ======================================================
                      _buildWeakLettersSection(context),

                      const SizedBox(height: 14),

                      // ======================================================
                      // MASTERED LETTERS
                      // ======================================================
                      _buildStrongLettersSection(context),

                      const SizedBox(height: 14),

                      // ======================================================
                      // PER LETTER
                      // ======================================================
                      _buildPerLetterScores(),

                      const SizedBox(height: 18),

                      // ======================================================
                      // ACTIONS
                      // ======================================================
                      _buildActionButtons(context),
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

  // ===========================================================================
  // HERO CARD
  // ===========================================================================
  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 170),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _purple.withOpacity(0.07)),
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
            // Purple background circle
            Positioned(
              right: -55,
              top: -65,
              child: Container(
                width: 165,
                height: 165,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5).withOpacity(0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Pink background circle
            Positioned(
              left: -25,
              bottom: -60,
              child: Container(
                width: 150,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9E2).withOpacity(0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Green hill
            Positioned(
              left: -30,
              bottom: -50,
              child: Container(
                width: 185,
                height: 95,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDF2E3).withOpacity(0.60),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(100),
                    topRight: Radius.circular(100),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 16, 15),
              child: Row(
                children: [
                  // Bunny
                  const SizedBox(
                    width: 112,
                    height: 138,
                    child: _PlacementResultBunny(),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'أحسنت!',
                          style: TextStyle(
                            color: _purple,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'أنهيت اختبار تحديد المستوى',
                          style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 11.5,
                            height: 1.4,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 9),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: Text(
                            _encouragementMessage,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _coral,
                              fontFamily: 'Tajawal',
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

  // ===========================================================================
  // SCORE CARD
  // ===========================================================================
  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _purple.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // =========================================================
          // Score circle
          // =========================================================
          Container(
            width: 105,
            height: 105,
            decoration: BoxDecoration(
              color: const Color(0xFFF4EBFA),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD9C1EA), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${toArabicDigits(widget.score)}٪',
                  style: const TextStyle(
                    color: _purple,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const Text(
                  'درجتك',
                  style: TextStyle(
                    color: Color(0xFF8B55B3),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 17),

          // =========================================================
          // Level
          // =========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFFF3B82F),
                      size: 18,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'مستواك الآن',
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 11,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                Text(
                  _overallLevel,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _purple,
                    fontFamily: 'Tajawal',
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'استمر بالتدريب وتقدّم خطوة بخطوة',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.4,
                    color: Color(0xFF858085),
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LETTERS TO PRACTICE
  // ===========================================================================
  Widget _buildWeakLettersSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFFFD7DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _SectionIcon(
                icon: Icons.record_voice_over_rounded,
                background: Color(0xFFFFE3E7),
                color: Color(0xFFFF6969),
              ),

              SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حروفي للتدريب',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _purple,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'سنتمرّن عليها حتى تصبح أسهل',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF858085),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _lettersToPractice.isEmpty
              ? _emptyState(
                  text: 'رائع! لا توجد حروف تحتاج إلى تدريب الآن',
                  bgColor: const Color(0xFFF1F8F3),
                  borderColor: const Color(0xFFD3EAD9),
                  textColor: const Color(0xFF66997A),
                )
              : _buildDynamicLetterGrid(context, letters: _lettersToPractice),
        ],
      ),
    );
  }

  // ===========================================================================
  // MASTERED LETTERS
  // ===========================================================================
  Widget _buildStrongLettersSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFD5EADB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _SectionIcon(
                icon: Icons.verified_rounded,
                background: Color(0xFFDDF2E3),
                color: Color(0xFF70A884),
              ),

              SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الحروف التي أتقنتها',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _purple,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'أداء رائع في هذه الحروف',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF858085),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _masteredLetters.isEmpty
              ? _emptyState(
                  text:
                      'لا توجد حروف متقنة بعد، استمر بالتدريب مع فصيح وستتحسن وتتقن حروفًا جديدة',
                  bgColor: Colors.white,
                  borderColor: const Color(0xFFD9E8DD),
                  textColor: const Color(0xFF66997A),
                )
              : _buildDynamicLetterGrid(context, letters: _masteredLetters),
        ],
      ),
    );
  }

  // ===========================================================================
  // DYNAMIC LETTER GRID
  // ===========================================================================
  Widget _buildDynamicLetterGrid(
    BuildContext context, {
    required List<LetterScore> letters,
  }) {
    final cardWidth =
        (MediaQuery.of(context).size.width - 32 - 34 - 20) / 3 - 2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: letters.map((item) {
        String badge = 'متقن';

        Color cardColor = const Color(0xFFF1F8F3);

        Color circleColor = const Color(0xFFDDF2E3);

        Color badgeBg = const Color(0xFFDDF2E3);

        Color badgeText = const Color(0xFF66997A);

        Color borderColor = const Color(0xFFCFE5D5);

        // 0–50% = Beginner
        if (item.score <= _beginnerMaxScore) {
          badge = 'مبتدئ';

          cardColor = const Color(0xFFFFF4F4);

          circleColor = const Color(0xFFFFE3E7);

          badgeBg = const Color(0xFFFFE3E7);

          badgeText = _coral;

          borderColor = const Color(0xFFFFD2D8);
        }
        // 51–79% = Intermediate
        else if (item.score < _masteryMinScore) {
          badge = 'متوسط';

          cardColor = const Color(0xFFFFFAEE);

          circleColor = const Color(0xFFFFF1C9);

          badgeBg = const Color(0xFFFFF1C9);

          badgeText = const Color(0xFFB47A17);

          borderColor = const Color(0xFFF2DEAD);
        }

        return SizedBox(
          width: cardWidth,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 7),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 53,
                  height: 53,
                  decoration: BoxDecoration(
                    color: circleColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.letter,
                    style: const TextStyle(
                      fontSize: 28,
                      color: _purple,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  _getLetterName(item.letter),
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF8A858A),
                  ),
                ),

                const SizedBox(height: 7),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: badgeText,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // PER LETTER SCORES
  // ===========================================================================
  Widget _buildPerLetterScores() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _purple.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _SectionIcon(
                icon: Icons.bar_chart_rounded,
                background: Color(0xFFE8D8F4),
                color: Color(0xFF8B55B3),
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  'كيف كان أداؤك في كل حرف؟',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _purple,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          ..._sortedScores.map((item) => _buildScoreRow(item)),
        ],
      ),
    );
  }

  // ===========================================================================
  // INDIVIDUAL SCORE ROW
  // ===========================================================================
  Widget _buildScoreRow(LetterScore item) {
    final String label = item.score >= _masteryMinScore
        ? 'متقن'
        : item.score <= _beginnerMaxScore
        ? 'مبتدئ'
        : 'متوسط';

    Color badgeColor;
    Color badgeBackground;

    if (item.score >= _masteryMinScore) {
      badgeColor = const Color(0xFF66997A);

      badgeBackground = const Color(0xFFE5F3E9);
    } else if (item.score <= _beginnerMaxScore) {
      badgeColor = _coral;

      badgeBackground = const Color(0xFFFFE7EC);
    } else {
      badgeColor = const Color(0xFFB47A17);

      badgeBackground = const Color(0xFFFFF1C9);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _purple.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          // Letter
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFEDE0FA),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              item.letter,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: _purple,
                fontFamily: 'Tajawal',
              ),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLetterName(item.letter),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF555555),
                  ),
                ),

                const SizedBox(height: 4),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: badgeColor,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EEFA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              '${toArabicDigits(item.score)}٪',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _purple,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ACTION BUTTONS
  // نفس الـfunctionality الأصلية
  // ===========================================================================
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/child/exercises',
              arguments: widget.childId,
            ),
            icon: const Icon(Icons.record_voice_over_rounded, size: 21),
            label: const Text(
              'ابدأ التدريب',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Tajawal',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _coral,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/child/home',
              (route) => false,
              arguments: widget.childId,
            ),
            icon: const Icon(Icons.home_rounded, size: 20),
            style: OutlinedButton.styleFrom(
              foregroundColor: _purple,
              backgroundColor: Colors.white.withOpacity(0.72),
              side: BorderSide(color: _purple.withOpacity(0.14), width: 1.5),
              shape: const StadiumBorder(),
            ),
            label: const Text(
              'العودة للرئيسية',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================
  Widget _emptyState({
    required String text,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textColor,
            fontFamily: 'Tajawal',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// =============================================================================
// SECTION ICON
// =============================================================================
class _SectionIcon extends StatelessWidget {
  final IconData icon;
  final Color background;
  final Color color;

  const _SectionIcon({
    required this.icon,
    required this.background,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// =============================================================================
// BACKGROUND
// =============================================================================
class _PlacementResultBackground extends StatelessWidget {
  const _PlacementResultBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 55,
          right: -55,
          child: _circle(150, const Color(0xFFDCC9F5).withOpacity(0.20)),
        ),

        Positioned(
          top: 350,
          left: -70,
          child: _circle(165, const Color(0xFFDDF2E3).withOpacity(0.27)),
        ),

        Positioned(
          top: 730,
          right: -55,
          child: _circle(135, const Color(0xFFFFDCE3).withOpacity(0.25)),
        ),

        Positioned(
          bottom: 80,
          left: 38,
          child: _circle(22, const Color(0xFFD5BFE9).withOpacity(0.34)),
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

// =============================================================================
// RESULT BUNNY
// =============================================================================
class _PlacementResultBunny extends StatelessWidget {
  const _PlacementResultBunny();

  @override
  Widget build(BuildContext context) {
    const faceColor = Color(0xFFFFDCE7);
    const bodyColor = Color(0xFF8B55B3);
    const innerEarColor = Color(0xFFFFA1B7);
    const detailsColor = Color(0xFF4D3855);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // =========================================================
        // Small celebration bubble
        // =========================================================
        Positioned(
          top: 2,
          right: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.90),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'رائع!',
              style: TextStyle(
                color: Color(0xFF8B55B3),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ),

        // =========================================================
        // Small celebration decorations
        // =========================================================
        const Positioned(
          top: 33,
          right: 5,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFF3B82F),
            size: 15,
          ),
        ),

        const Positioned(
          top: 18,
          left: 5,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Color(0xFFFF8FA3),
            size: 11,
          ),
        ),

        // =========================================================
        // Right ear
        // =========================================================
        Positioned(
          top: 18,
          right: 29,
          child: Transform.rotate(
            angle: 0.08,
            child: Container(
              width: 20,
              height: 44,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 27,
                  decoration: BoxDecoration(
                    color: innerEarColor.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // =========================================================
        // Left ear
        // =========================================================
        Positioned(
          top: 18,
          left: 29,
          child: Transform.rotate(
            angle: -0.08,
            child: Container(
              width: 20,
              height: 44,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 27,
                  decoration: BoxDecoration(
                    color: innerEarColor.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // =========================================================
        // Body
        // =========================================================
        Positioned(
          bottom: 1,
          child: Container(
            width: 54,
            height: 36,
            decoration: const BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
                bottomLeft: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
            ),
          ),
        ),

        // =========================================================
        // Small collar detail
        // =========================================================
        Positioned(
          bottom: 25,
          child: Container(
            width: 31,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFA16BC3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),

        // =========================================================
        // Head
        // =========================================================
        Positioned(
          top: 51,
          child: Container(
            width: 68,
            height: 63,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Eyes
                Positioned(
                  top: 22,
                  right: 16,
                  child: Container(
                    width: 6,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 22,
                  left: 16,
                  child: Container(
                    width: 6,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Tiny eye shines
                Positioned(
                  top: 23,
                  right: 17,
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 23,
                  left: 17,
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 37,
                  right: 7,
                  child: Container(
                    width: 10,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 37,
                  left: 7,
                  child: Container(
                    width: 10,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 31,
                  left: 30,
                  child: Container(
                    width: 8,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Happy small smile
                Positioned(
                  top: 38,
                  left: 24,
                  child: Container(
                    width: 20,
                    height: 9,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: detailsColor, width: 1.4),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(11),
                        bottomRight: Radius.circular(11),
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
