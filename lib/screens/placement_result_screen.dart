import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Letter Name Helper ───────────────────────────────────────────────────────
String _getLetterName(String letter) {
  const names = {
    'ض': 'Dhad',
    'ح': 'Haa',
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
  // ✅ الحروف التي تحتاج تدريب (تجمع الضعيف والمتوسط: أي حرف درجته أقل من 70%)
  List<LetterScore> get _lettersToPractice =>
      widget.letterScores.where((ls) => ls.score < 70).toList();

  // ✅ الحروف المتقنة (التي درجتها 70% وما فوق)
  List<LetterScore> get _masteredLetters =>
      widget.letterScores.where((ls) => ls.score >= 70).toList();

  // ── Write placementDone = true to Firestore when result screen opens ────────
  @override
  void initState() {
    super.initState();
    _markPlacementDone();
  }

  Future<void> _markPlacementDone() async {
    try {
      await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .update({
        'placementDone': true,
        'placementScore': widget.score,
        'placementDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating placementDone: $e');
    }
  }

  // ── Constants ──
  static const _purple = Color(0xFF511281);
  static const _purple2 = Color(0xFF6A3A9E);
  static const _coral = Color(0xFFFF6969);
  static const _bgColor = Color(0xFFFCF9EA);

  // ── Overall Child Level ──
  // ── Overall Child Level ──
  String get _overallLevel {
    if (widget.score >= 70) return 'مستوى خبير 🌟';
    if (widget.score >= 40) return 'مستوى متوسط 👍';
    return 'مستوى مبتدئ ';
  }

  // ── Encouragement message ──
  String get _encouragementMessage {
    if (widget.score >= 70) return 'ممتاز يا بطل! 👏';
    if (widget.score >= 40) return 'أحسنت! في الطريق الصحيح 🌟';
    return 'بداية جميلة! سنتدرب معًا 💜';
  }

  // ── Sorted letter scores (ascending) ──
  List<LetterScore> get _sortedScores =>
      [...widget.letterScores]..sort((a, b) => a.score.compareTo(b.score));

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // ✅ لفرض الاتجاه العربي
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Stack(
          children: [
            _bubble(
              top: 60,
              left: 24,
              size: 90,
              color: const Color(0xFFFFB84D).withOpacity(0.22),
            ),
            _bubble(
              bottom: 100,
              right: 24,
              size: 110,
              color: _purple2.withOpacity(0.15),
            ),
            _bubble(
              top: 300,
              right: 18,
              size: 70,
              color: _coral.withOpacity(0.15),
            ),
            SafeArea(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: _buildCard(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildScoreCard(),
                const SizedBox(height: 16),
                _buildWeakLettersSection(context),
                const SizedBox(height: 16),
                _buildStrongLettersSection(context),
                const SizedBox(height: 16),
                _buildPerLetterScores(),
                const SizedBox(height: 20),
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8F1FF), Colors.white],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_purple2, _purple],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'أحسنت! 🎉',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: _purple,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'انتهيت من اختبار الحروف',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6b5a7a),
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _encouragementMessage,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: _coral,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_purple2, _purple],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'درجتك',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${widget.score}%',
            style: const TextStyle(
              fontSize: 60,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFamily: 'Tajawal',
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          // ✅ عرض المستوى الكلي للطفل
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _overallLevel,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'هذه النتيجة من الحروف التي اختبرناها',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xE6FFFFFF),
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeakLettersSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD9CC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الحروف التي سنتدرب عليها ✍️',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _purple,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 14),
          _lettersToPractice.isEmpty
              ? _emptyState(
                  text: 'رائع! لا توجد حروف تحتاج تدريب الآن 💚',
                  bgColor: Colors.green.shade50,
                  borderColor: Colors.green.shade200,
                  textColor: Colors.green.shade700,
                )
              : _buildDynamicLetterGrid(
                  context,
                  letters: _lettersToPractice,
                ), // ✅ استخدام الدالة الديناميكية
        ],
      ),
    );
  }

  Widget _buildStrongLettersSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FFF5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD5F0D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الحروف التي أتقنتها 🌟',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _purple,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 14),
          _masteredLetters.isEmpty
              ? _emptyState(
                  text: 'سنعرض هنا الحروف التي أتقنتها لاحقًا',
                  bgColor: Colors.white,
                  borderColor: Colors.grey.shade200,
                  textColor: Colors.grey.shade600,
                )
              : _buildDynamicLetterGrid(
                  context,
                  letters: _masteredLetters,
                ), // ✅ استخدام الدالة الديناميكية
        ],
      ),
    );
  }

  // ✅ دالة جديدة ترسم الحرف وتعطيه وساماً (Badge) حسب درجته الفردية
  Widget _buildDynamicLetterGrid(
    BuildContext context, {
    required List<LetterScore> letters,
  }) {
    final cardWidth =
        (MediaQuery.of(context).size.width - 32 - 40 - 20) / 3 - 2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: letters.map((item) {
        // تحديد مظهر البطاقة بناءً على الدرجة (متقن، تطوير، تأسيس)
        String badge = 'متقن';
        Color badgeBg = Colors.green.shade100;
        Color badgeText = Colors.green.shade700;
        Color borderColor = Colors.green.shade200;

        if (item.score < 40) {
          badge = 'تأسيس'; // كلمة ألطف من "ضعيف" للأطفال
          badgeBg = _coral.withOpacity(0.1);
          badgeText = _coral;
          borderColor = _coral.withOpacity(0.2);
        } else if (item.score < 70) {
          badge = 'تطوير'; // للمستوى المتوسط
          badgeBg = Colors.orange.shade100;
          badgeText = Colors.orange.shade800;
          borderColor = Colors.orange.shade200;
        }

        return SizedBox(
          width: cardWidth,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.letter,
                  style: const TextStyle(
                    fontSize: 36,
                    color: _purple,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getLetterName(item.letter),
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
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

  Widget _buildPerLetterScores() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7DDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'كيف كان أداؤك في كل حرف؟',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _purple,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 14),
          ..._sortedScores.map((item) => _buildScoreRow(item)),
        ],
      ),
    );
  }

  Widget _buildScoreRow(LetterScore item) {
    // ✅ تطبيق العتبات الجديدة والمسميات هنا في قائمة التفاصيل
    final String label = item.score >= 70
        ? 'متقن 🌟'
        : item.score >= 40
            ? 'في الطريق الصحيح 👍'
            : 'يحتاج تدريب ✍️';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _purple.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _purple.withOpacity(0.2), width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              item.letter,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _purple,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getLetterName(item.letter),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _purple,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${item.score}%',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _purple,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

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
            icon: const Icon(Icons.menu_book_rounded, size: 22),
            label: const Text(
              'ابدأ التدريب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _coral,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: _coral.withOpacity(0.4),
              shape: const StadiumBorder(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/child/home',
              (route) => false,
              arguments: widget.childId,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _purple,
              side: BorderSide(color: _purple.withOpacity(0.25), width: 2),
              shape: const StadiumBorder(),
            ),
            child: const Text(
              'العودة للرئيسية',
              style: TextStyle(fontSize: 18, fontFamily: 'Tajawal'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState({
    required String text,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
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