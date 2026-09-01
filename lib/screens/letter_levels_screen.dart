import 'package:flutter/material.dart';
import '../utils/arabic_numbers.dart';

const _levelProgress = {
  'ض': (mcq: true, listening: true, recording: false),
  'خ': (mcq: true, listening: true, recording: true),
  'غ': (mcq: false, listening: false, recording: false),
  'ص': (mcq: true, listening: false, recording: false),
  'س': (mcq: false, listening: false, recording: false),
  'ق': (mcq: false, listening: false, recording: false),
};

// ─────────────────────────────────────────────────────────────────────────────
// Level Info
// ─────────────────────────────────────────────────────────────────────────────
class _LevelInfo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool completed;
  final bool isLocked;

  const _LevelInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.completed,
    required this.isLocked,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class LetterLevelsScreen extends StatelessWidget {
  final String letter;
  final String childId;

  const LetterLevelsScreen({
    super.key,
    required this.letter,
    required this.childId,
  });

  List<_LevelInfo> _buildLevels() {
    final p =
        _levelProgress[letter] ??
        (mcq: false, listening: false, recording: false);

    // الاستماع هو أول تمرين ظاهر
    const bool listeningLocked = false;

    // تمارين النطق تفتح بعد إكمال تمارين الاستماع
    final bool recordingLocked = !p.listening;

    return [
      _LevelInfo(
        id: 'listening',
        title: 'تمارين الاستماع',
        description: 'استمع وكرر',
        icon: Icons.headphones_rounded,
        color: const Color(0xFF7B4AAD),
        completed: p.listening,
        isLocked: listeningLocked,
      ),

      _LevelInfo(
        // نبقي recording داخليًا حتى لا تتغير الـ functionality
        id: 'recording',
        title: 'تمارين النطق',
        description: 'انطق وسجّل صوتك',
        icon: Icons.mic_rounded,
        color: const Color(0xFF5CB88A),
        completed: p.recording,
        isLocked: recordingLocked,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final levels = _buildLevels();

    final completedCount = levels.where((l) => l.completed).length;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),

        body: Column(
          children: [
            // ===============================================================
            // HEADER
            // بدون تغيير
            // ===============================================================
            _LetterLevelsHeader(
              letter: letter,
              completedCount: completedCount,
              totalCount: levels.length,
              childId: childId,
            ),

            // ===============================================================
            // CONTENT
            // ===============================================================
            Expanded(
              child: Stack(
                children: [
                  // خلفية باستيل
                  const Positioned.fill(
                    child: IgnorePointer(child: _LevelsBackground()),
                  ),

                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 35),
                    child: Column(
                      children: [
                        // ─────────────────────────────────────────────────────
                        // Cute Intro Card
                        // ─────────────────────────────────────────────────────
                        _LevelsIntroCard(
                          letter: letter,
                          completedCount: completedCount,
                          totalCount: levels.length,
                        ),

                        const SizedBox(height: 14),

                        // ─────────────────────────────────────────────────────
                        // Levels
                        // ─────────────────────────────────────────────────────
                        ...levels.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LevelCard(
                              level: entry.value,
                              number: entry.key + 1,

                              // =================================================
                              // نفس الـ functionality الحالية
                              // =================================================
                              onTap: () {
                                if (entry.value.isLocked) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'يجب عليك إنهاء المستوى السابق أولاً!',
                                      ),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );

                                  return;
                                }

                                if (entry.value.id == 'recording') {
                                  Navigator.pushNamed(
                                    context,
                                    '/child/letter-introduction',
                                    arguments: {
                                      'letter': letter,
                                      'childId': childId,
                                    },
                                  );
                                } else {
                                  Navigator.pushNamed(
                                    context,
                                    '/child/exercise/${entry.value.id}',
                                    arguments: {
                                      'letter': letter,
                                      'childId': childId,
                                    },
                                  );
                                }
                              },
                            ),
                          );
                        }),
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
// Header
// نفس الهيدر الأصلي بدون تغيير
// ─────────────────────────────────────────────────────────────────────────────
class _LetterLevelsHeader extends StatelessWidget {
  final String letter;
  final int completedCount;
  final int totalCount;
  final String childId;

  const _LetterLevelsHeader({
    required this.letter,
    required this.completedCount,
    required this.totalCount,
    required this.childId,
  });

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
        bottom: 16,
        right: 16,
        left: 16,
      ),
      child: Row(
        children: [
          _HeaderIconBtn(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pushNamed(
              context,
              '/child/exercises',
              arguments: childId,
            ),
          ),

          const SizedBox(width: 12),

          Text(
            letter,
            style: const TextStyle(
              fontSize: 52,
              color: Colors.white,
              height: 1.1,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تمارين حرف $letter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  '${toArabicDigits(completedCount)} من ${toArabicDigits(totalCount)} مستويات مكتملة',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cute Intro Card
// بدون تغيير
// ─────────────────────────────────────────────────────────────────────────────
class _LevelsIntroCard extends StatelessWidget {
  final String letter;
  final int completedCount;
  final int totalCount;

  const _LevelsIntroCard({
    required this.letter,
    required this.completedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = totalCount == 0 ? 0 : completedCount / totalCount;

    return Container(
      width: double.infinity,
      height: 145,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
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
            // موف خلفي
            Positioned(
              right: -40,
              top: -50,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8C2F0).withOpacity(0.32),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // وردي خلفي
            Positioned(
              left: 45,
              bottom: -55,
              child: Container(
                width: 135,
                height: 105,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD7E1).withOpacity(0.48),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  // ─── Text ─────────────────────────────
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اختر تمرينك وابدأ!',
                          style: TextStyle(
                            fontSize: 17,
                            color: Color(0xFF511281),
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'أكمل المستويات واحدًا بعد الآخر',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF777777),
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            // الحرف
                            Container(
                              width: 43,
                              height: 43,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(
                                    0xFF511281,
                                  ).withOpacity(0.10),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                letter,
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Color(0xFF511281),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Tajawal',
                                  height: 1,
                                ),
                              ),
                            ),

                            const SizedBox(width: 9),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'تقدّمك',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          color: Color(0xFF777777),
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),

                                      Text(
                                        '${toArabicDigits(completedCount)}/${toArabicDigits(totalCount)}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF511281),
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'Tajawal',
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 5),

                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 7,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.85,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Color(0xFFFF6969),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ─── Character ────────────────────────
                  const SizedBox(
                    width: 82,
                    height: 110,
                    child: _CuteLevelCharacter(),
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
// Level Card
// ─────────────────────────────────────────────────────────────────────────────
class _LevelCard extends StatefulWidget {
  final _LevelInfo level;
  final int number;
  final VoidCallback onTap;

  const _LevelCard({
    required this.level,
    required this.number,
    required this.onTap,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard>
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
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _cardColor {
    if (widget.level.isLocked) {
      return const Color(0xFFF4F3F5);
    }

    switch (widget.level.id) {
      case 'listening':
        return const Color(0xFFF5F0FA);

      case 'recording':
        return const Color(0xFFF0F9F4);

      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = widget.level.isLocked
        ? const Color(0xFFAAAAAA)
        : widget.level.color;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.level.isLocked) {
            _ctrl.forward();
          }
        },

        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },

        onTapCancel: () => _ctrl.reverse(),

        child: Opacity(
          opacity: widget.level.isLocked ? 0.72 : 1.0,

          child: Container(
            constraints: const BoxConstraints(minHeight: 112),

            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: mainColor.withOpacity(0.16),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(23),

              child: Stack(
                children: [
                  // خلفية ناعمة داخل الكارد
                  Positioned(
                    left: -28,
                    bottom: -38,
                    child: Container(
                      width: 115,
                      height: 95,
                      decoration: BoxDecoration(
                        color: mainColor.withOpacity(0.055),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // دائرة صغيرة
                  Positioned(
                    right: 85,
                    top: 15,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: mainColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),

                    child: Row(
                      children: [
                        // ── رقم المرحلة
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: mainColor,
                            shape: BoxShape.circle,
                            boxShadow: widget.level.isLocked
                                ? null
                                : [
                                    BoxShadow(
                                      color: mainColor.withOpacity(0.20),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            toArabicDigits(widget.number),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),

                        const SizedBox(width: 11),

                        // ── Icon
                        Container(
                          width: 55,
                          height: 55,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: mainColor.withOpacity(0.12),
                            ),
                          ),
                          child: Icon(
                            widget.level.isLocked
                                ? Icons.lock_outline_rounded
                                : widget.level.icon,
                            color: mainColor,
                            size: 27,
                          ),
                        ),

                        const SizedBox(width: 12),

                        // ── Text
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.level.title,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: widget.level.isLocked
                                      ? const Color(0xFF888888)
                                      : const Color(0xFF333333),
                                  fontFamily: 'Tajawal',
                                ),
                              ),

                              const SizedBox(height: 3),

                              Text(
                                widget.level.isLocked
                                    ? 'أكمل المستوى السابق للفتح'
                                    : widget.level.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF888888),
                                  fontFamily: 'Tajawal',
                                ),
                              ),

                              // ── Completed indicator
                              if (widget.level.completed) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF59B77B,
                                    ).withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'تم إكماله',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF4E9F6C),
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // ── Final icon
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: widget.level.completed
                                ? const Color(0xFF5BB980).withOpacity(0.12)
                                : mainColor.withOpacity(0.07),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.level.completed
                                ? Icons.check_rounded
                                : widget.level.isLocked
                                ? Icons.lock_rounded
                                : Icons.arrow_forward_ios_rounded,
                            color: widget.level.completed
                                ? const Color(0xFF55AD75)
                                : mainColor.withOpacity(0.65),
                            size: widget.level.completed ? 20 : 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// بدون تغيير
// ─────────────────────────────────────────────────────────────────────────────
class _LevelsBackground extends StatelessWidget {
  const _LevelsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 45,
          right: -55,
          child: _circle(150, const Color(0xFFDCC9F5).withOpacity(0.20)),
        ),

        Positioned(
          top: 150,
          left: 20,
          child: _circle(22, const Color(0xFFFFC9D5).withOpacity(0.50)),
        ),

        Positioned(
          top: 260,
          left: -55,
          child: _circle(150, const Color(0xFFD8F0DF).withOpacity(0.30)),
        ),

        Positioned(
          top: 420,
          right: 22,
          child: _circle(25, const Color(0xFFD6C1EF).withOpacity(0.40)),
        ),

        Positioned(
          top: 530,
          right: -45,
          child: _circle(125, const Color(0xFFFFDCE3).withOpacity(0.28)),
        ),

        Positioned(
          top: 680,
          left: 38,
          child: _circle(18, const Color(0xFFCDEFD9).withOpacity(0.52)),
        ),

        Positioned(
          top: 790,
          left: -45,
          child: _circle(135, const Color(0xFFDCC9F5).withOpacity(0.18)),
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
// بدون تغيير
// ─────────────────────────────────────────────────────────────────────────────
class _CuteLevelCharacter extends StatelessWidget {
  final Color faceColor;
  final Color accentColor;

  const _CuteLevelCharacter({
    this.faceColor = const Color(0xFFFFDCE7),
    this.accentColor = const Color(0xFF8B55B3),
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Right Ear
        Positioned(
          top: 1,
          right: 13,
          child: Transform.rotate(
            angle: 0.15,
            child: Container(
              width: 20,
              height: 41,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 27,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9CB5).withOpacity(0.62),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Left Ear
        Positioned(
          top: 1,
          left: 13,
          child: Transform.rotate(
            angle: -0.15,
            child: Container(
              width: 20,
              height: 41,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Container(
                  width: 8,
                  height: 27,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9CB5).withOpacity(0.62),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Body
        Positioned(
          bottom: 0,
          child: Container(
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(26),
                topRight: Radius.circular(26),
              ),
            ),
          ),
        ),

        // Arm
        Positioned(
          right: 4,
          bottom: 20,
          child: Transform.rotate(
            angle: -0.50,
            child: Container(
              width: 11,
              height: 28,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Head
        Positioned(
          top: 30,
          child: Container(
            width: 64,
            height: 59,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(29),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
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
                    height: 9,
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
                    height: 9,
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
                    width: 11,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8EA6).withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                Positioned(
                  top: 34,
                  left: 7,
                  child: Container(
                    width: 11,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8EA6).withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
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
                    height: 9,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF4D3855),
                          width: 1.7,
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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header Button
// بدون تغيير
// ─────────────────────────────────────────────────────────────────────────────
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 34,
      height: 34,
      child: Icon(icon, color: Colors.white, size: 25),
    ),
  );
}
