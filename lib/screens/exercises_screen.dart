import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'style_constants.dart';
import '../widgets/child_bottom_nav.dart';

const _mockLevelProgress = {
  'ض': (mcq: true, listening: true, recording: false), // 2/3
  'خ': (mcq: true, listening: true, recording: true), // 3/3
  'ص': (mcq: true, listening: false, recording: false), // 1/3
  'س': (mcq: false, listening: false, recording: false), // 0/3
  'ع': (mcq: false, listening: false, recording: false), // 0/3
  'ن': (mcq: false, listening: false, recording: false), // 0/3
};

// ─── Data Model ──────────────────────────────────────────────────────────────
class _LetterData {
  final String letter;
  final String name;
  final int score;
  final int completed;
  final int total;

  const _LetterData({
    required this.letter,
    required this.name,
    required this.score,
    required this.completed,
    required this.total,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class ExercisesScreen extends StatefulWidget {
  final String childId;

  const ExercisesScreen({super.key, required this.childId});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<_LetterData> _filteredLetters = [];
  bool _isLoading = true;
  bool _hasCompletedPlacement = false;

  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  @override
  void initState() {
    super.initState();
    _loadChildProgress();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // نفس الـFunctionality الحالية
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _loadChildProgress() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        _hasCompletedPlacement = data['placementDone'] ?? false;

        final dynamic rawScores = data['letterScores'];

        List<_LetterData> loaded = [];

        if (rawScores is Map) {
          rawScores.forEach((letter, scoreValue) {
            int score = (scoreValue is num) ? scoreValue.toInt() : 0;

            // إظهار الحروف التي درجتها أقل من 70% فقط
            if (score < 70) {
              final p =
                  _mockLevelProgress[letter] ??
                  (mcq: false, listening: false, recording: false);

              int completedCount = 0;

              if (p.mcq) completedCount++;
              if (p.listening) completedCount++;
              if (p.recording) completedCount++;

              loaded.add(
                _LetterData(
                  letter: letter.toString(),
                  name: _getLetterName(letter.toString()),
                  score: score,
                  completed: completedCount,
                  total: 3,
                ),
              );
            }
          });
        }

        if (!mounted) return;

        setState(() {
          _filteredLetters = loaded;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isTablet = screenWidth > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,

        body: Column(
          children: [
            // ================================================================
            // HEADER
            // نفس الهيدر بدون تغيير
            // ================================================================
            FaseehStyle.buildLargeHeader(
              context: context,
              title: 'هيا نتدرّب!',
              subtitle: 'اختر حرفًا لتتدرّب عليه',

              leading: const SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),

              trailingActions: const [SizedBox(width: 48, height: 48)],
            ),

            // ================================================================
            // CONTENT
            // ================================================================
            Expanded(
              child: Stack(
                children: [
                  // خلفية طفولية
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: _ExercisesBackgroundDecoration(),
                    ),
                  ),

                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _purple),
                        )
                      : _filteredLetters.isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            isTablet ? screenWidth * 0.1 : 16,
                            16,
                            isTablet ? screenWidth * 0.1 : 16,
                            100,
                          ),
                          child: Column(
                            children: [
                              // ─────────────────────────────────────────
                              // Cute welcome card
                              // ─────────────────────────────────────────
                              const _ExercisesWelcomeCard(),

                              const SizedBox(height: 18),

                              // ─────────────────────────────────────────
                              // Letter Grid
                              // ─────────────────────────────────────────
                              GridView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: isTablet
                                          ? (screenWidth > 900 ? 4 : 3)
                                          : 2,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,

                                      // تصميم أقصر قليلًا من السابق
                                      childAspectRatio: isTablet ? 0.95 : 0.90,
                                    ),
                                itemCount: _filteredLetters.length,
                                itemBuilder: (context, i) {
                                  final item = _filteredLetters[i];

                                  // ألوان باستيل متناوبة
                                  const cardColors = [
                                    Color(0xFFFFF1F3),
                                    Color(0xFFF6F0FF),
                                    Color(0xFFFFF8E8),
                                    Color(0xFFF0FAF4),
                                    Color(0xFFF3F7FF),
                                    Color(0xFFFFF2EA),
                                  ];

                                  const accentColors = [
                                    Color(0xFFFF8D9B),
                                    Color(0xFF8B5BB7),
                                    Color(0xFFF3B43F),
                                    Color(0xFF65B98B),
                                    Color(0xFF72A3D8),
                                    Color(0xFFE89968),
                                  ];

                                  return _LetterCard(
                                    item: item,
                                    cardColor:
                                        cardColors[i % cardColors.length],
                                    accentColor:
                                        accentColors[i % accentColors.length],
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/child/letter-levels',
                                        arguments: {
                                          'letter': item.letter,
                                          'currentProgress': item.completed,
                                          'childId': widget.childId,
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),

        // ================================================================
        // FOOTER
        // نفس الفوتر بدون تغيير
        // ================================================================
        bottomNavigationBar: ChildBottomNav(
          currentRoute: '/child/exercises',
          childId: widget.childId,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Empty State
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    if (!_hasCompletedPlacement) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(22, 25, 22, 25),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F1FF),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _purple.withOpacity(0.10), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 9,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 100,
                  height: 115,
                  child: _LearningExerciseBunny(),
                ),

                const SizedBox(height: 12),

                const Text(
                  'أهلًا بك يا بطل!',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 21,
                    color: _purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'ابدأ باختبار تحديد المستوى من الصفحة الرئيسية، وبعدها نبدأ التمارين!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFF777777),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  width: 54,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _coral.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: const Color(0xFFF1FAF3),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF76BE91).withOpacity(0.20),
            ),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 95,
                height: 110,
                child: _LearningExerciseBunny(
                  faceColor: Color(0xFFDDF4E4),
                  accentColor: Color(0xFF65B98B),
                ),
              ),

              SizedBox(height: 14),

              Text(
                'أحسنت!',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 22,
                  color: Color(0xFF3C9661),
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 7),

              Text(
                'لقد أتقنت جميع الحروف',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  color: Color(0xFF6F6F6F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome Card
// ─────────────────────────────────────────────────────────────────────────────
class _ExercisesWelcomeCard extends StatelessWidget {
  const _ExercisesWelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 132,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F0FF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFF511281).withOpacity(0.10),
          width: 1.4,
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
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // خلفيات دائرية
            Positioned(
              right: -35,
              top: -50,
              child: Container(
                width: 135,
                height: 135,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC8F3).withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              left: 40,
              bottom: -50,
              child: Container(
                width: 120,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDCE4).withOpacity(0.45),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اختر حرفك وابدأ!',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF511281),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'كل تمرين يساعدك على تحسين نطقك',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11.5,
                            height: 1.4,
                            color: Color(0xFF777777),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  const SizedBox(
                    width: 92,
                    height: 108,
                    child: _LearningExerciseBunny(),
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
// Letter Card
// ─────────────────────────────────────────────────────────────────────────────
class _LetterCard extends StatefulWidget {
  final _LetterData item;
  final VoidCallback onTap;

  final Color cardColor;
  final Color accentColor;

  const _LetterCard({
    required this.item,
    required this.onTap,
    required this.cardColor,
    required this.accentColor,
  });

  @override
  State<_LetterCard> createState() => _LetterCardState();
}

class _LetterCardState extends State<_LetterCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double percent = widget.item.completed / widget.item.total;

    final bool isCritical = widget.item.score < 40;

    final Color statusColor = isCritical
        ? const Color(0xFFFF6969)
        : const Color(0xFFF1A340);

    final String statusLabel = isCritical ? 'تأسيس' : 'تطوير';

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: widget.cardColor,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: widget.accentColor.withOpacity(0.24),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 9,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(
              children: [
                // Decorative circle
                Positioned(
                  right: -26,
                  top: -30,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Small decorative circle
                Positioned(
                  left: 15,
                  top: 18,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),

                      // ─── Letter Bubble
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.80),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.accentColor.withOpacity(0.15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.item.letter,
                          style: const TextStyle(
                            fontSize: 47,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF511281),
                            fontFamily: 'Tajawal',
                            height: 1,
                          ),
                        ),
                      ),

                      const SizedBox(height: 9),

                      // ─── Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),

                      const Spacer(),

                      // ─── Progress information
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'تقدّمك',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF888888),
                              fontFamily: 'Tajawal',
                            ),
                          ),

                          Text(
                            '${widget.item.completed}/${widget.item.total}',
                            style: TextStyle(
                              fontSize: 10,
                              color: widget.accentColor,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percent,
                          minHeight: 7,
                          backgroundColor: Colors.white.withOpacity(0.75),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            statusColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// دوائر باستيل فقط، بدون حروف وبدون Emoji
// ─────────────────────────────────────────────────────────────────────────────
class _ExercisesBackgroundDecoration extends StatelessWidget {
  const _ExercisesBackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ============================================================
        // Pastel circles
        // ============================================================
        Positioned(
          top: 45,
          right: -55,
          child: _circle(150, const Color(0xFFDCC9F5).withOpacity(0.18)),
        ),

        Positioned(
          top: 170,
          left: 20,
          child: _circle(25, const Color(0xFFFFC6D2).withOpacity(0.45)),
        ),

        Positioned(
          top: 300,
          left: -55,
          child: _circle(150, const Color(0xFFD9F0DF).withOpacity(0.30)),
        ),

        Positioned(
          top: 455,
          right: 20,
          child: _circle(24, const Color(0xFFDCC9F5).withOpacity(0.40)),
        ),

        Positioned(
          top: 590,
          right: -45,
          child: _circle(125, const Color(0xFFFFDCE3).withOpacity(0.25)),
        ),

        Positioned(
          top: 720,
          left: 40,
          child: _circle(18, const Color(0xFFCDEFD9).withOpacity(0.50)),
        ),

        // ============================================================
        // BOOK 1 - أعلى يسار الصفحة
        // ============================================================
        Positioned(
          top: 155,
          left: 15,
          child: Transform.rotate(
            angle: -0.15,
            child: const _LearningBookDecoration(
              backgroundColor: Color(0xFFFFE8ED),
              iconColor: Color(0xFFFF8298),
              icon: Icons.menu_book_rounded,
              size: 39,
            ),
          ),
        ),

        // ============================================================
        // BOOK 2 - يمين الصفحة
        // ============================================================
        Positioned(
          top: 385,
          right: 9,
          child: Transform.rotate(
            angle: 0.12,
            child: const _LearningBookDecoration(
              backgroundColor: Color(0xFFEDE3F7),
              iconColor: Color(0xFF8B55B3),
              icon: Icons.auto_stories_rounded,
              size: 42,
            ),
          ),
        ),

        // ============================================================
        // BOOK 3 - يسار أسفل الصفحة
        // ============================================================
        Positioned(
          top: 610,
          left: 10,
          child: Transform.rotate(
            angle: -0.10,
            child: const _LearningBookDecoration(
              backgroundColor: Color(0xFFE5F4E9),
              iconColor: Color(0xFF65A97F),
              icon: Icons.menu_book_rounded,
              size: 38,
            ),
          ),
        ),

        // ============================================================
        // BOOK 4 - يمين أسفل
        // ============================================================
        Positioned(
          top: 790,
          right: 14,
          child: Transform.rotate(
            angle: 0.14,
            child: const _LearningBookDecoration(
              backgroundColor: Color(0xFFFFF0D2),
              iconColor: Color(0xFFE8A62E),
              icon: Icons.library_books_rounded,
              size: 40,
            ),
          ),
        ),

        // ============================================================
        // Small dots
        // ============================================================
        Positioned(
          top: 520,
          left: 33,
          child: _circle(12, const Color(0xFFFFB8C7).withOpacity(0.50)),
        ),

        Positioned(
          top: 690,
          right: 42,
          child: _circle(11, const Color(0xFFBFA0DA).withOpacity(0.45)),
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
// Cute Character
// مرسوم بالكامل بالـFlutter
// بدون Emoji
// ─────────────────────────────────────────────────────────────────────────────
class _LearningExerciseBunny extends StatelessWidget {
  final Color faceColor;
  final Color accentColor;

  const _LearningExerciseBunny({
    super.key,
    this.faceColor = const Color(0xFFFFDCE7),
    this.accentColor = const Color(0xFF8B55B3),
  });

  @override
  Widget build(BuildContext context) {
    const Color innerEarColor = Color(0xFFFFA1B7);
    const Color detailsColor = Color(0xFF4D3855);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // =========================================================
        // كتاب صغير فوق
        // =========================================================
        Positioned(
          top: 10,
          left: 2,
          child: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Color(0xFF8B55B3),
              size: 15,
            ),
          ),
        ),

        // =========================================================
        // أذن يمين
        // =========================================================
        Positioned(
          top: 0,
          right: 25,
          child: Container(
            width: 19,
            height: 39,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // =========================================================
        // أذن يسار
        // =========================================================
        Positioned(
          top: 0,
          left: 25,
          child: Container(
            width: 19,
            height: 39,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // =========================================================
        // جسم الأرنب
        // =========================================================
        Positioned(
          bottom: 10,
          child: Container(
            width: 48,
            height: 31,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ),
        // =========================================================
        // اليد اليمنى
        // =========================================================
        Positioned(
          bottom: 17,
          right: 26,
          child: Transform.rotate(
            angle: -0.28,
            child: Container(
              width: 10,
              height: 21,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // =========================================================
        // اليد اليسرى
        // =========================================================
        Positioned(
          bottom: 17,
          left: 26,
          child: Transform.rotate(
            angle: 0.28,
            child: Container(
              width: 10,
              height: 21,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // =========================================================
        // الرأس
        // =========================================================
        Positioned(
          top: 28,
          child: Container(
            width: 60,
            height: 56,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(28),
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
                // العين اليمنى
                Positioned(
                  top: 20,
                  right: 14,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // العين اليسرى
                Positioned(
                  top: 20,
                  left: 14,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // لمعة العين اليمنى
                Positioned(
                  top: 21,
                  right: 15,
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // لمعة العين اليسرى
                Positioned(
                  top: 21,
                  left: 15,
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // الخد الأيمن
                Positioned(
                  top: 32,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // الخد الأيسر
                Positioned(
                  top: 32,
                  left: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // الأنف
                Positioned(
                  top: 28,
                  left: 26,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // الابتسامة
                Positioned(
                  top: 34,
                  left: 22,
                  child: Container(
                    width: 15,
                    height: 7,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: detailsColor, width: 1.4),
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

        // =========================================================
        // كتاب مفتوح أمام الأرنب
        // =========================================================
        Positioned(
          bottom: 0,
          child: Container(
            width: 58,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCCFE5)),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(6, 5, 3, 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F0FF),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                Container(width: 1.2, color: const Color(0xFFE6DDEC)),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(3, 5, 6, 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF4F6),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // =========================================================
        // كتاب صغير يسار
        // =========================================================
        Positioned(
          left: 2,
          bottom: 8,
          child: Transform.rotate(
            angle: -0.20,
            child: Container(
              width: 20,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF2E3),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),

        // =========================================================
        // كتاب صغير يمين
        // =========================================================
        Positioned(
          right: 2,
          bottom: 8,
          child: Transform.rotate(
            angle: 0.20,
            child: Container(
              width: 20,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7EC),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniBookDecoration extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Color spineColor;

  const _MiniBookDecoration({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    required this.spineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 2)],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: spineColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningBookDecoration extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final double size;

  const _LearningBookDecoration({
    super.key,
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: iconColor.withOpacity(0.10)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: iconColor.withOpacity(0.75), size: size * 0.55),
    );
  }
}
