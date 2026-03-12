import 'package:flutter/material.dart';

// ─── Mock Progress Data ───────────────────────────────────────────────────────
const _levelProgress = {
  'ض': (mcq: true,  listening: true,  recording: false),
  'خ': (mcq: true,  listening: true,  recording: true),
  'غ': (mcq: false, listening: false, recording: false),
  'ص': (mcq: true,  listening: false, recording: false),
  'س': (mcq: false, listening: false, recording: false),
  'ق': (mcq: false, listening: false, recording: false),
};

// ─── Level Model ─────────────────────────────────────────────────────────────
class _LevelInfo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool completed;

  const _LevelInfo({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.completed,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class LetterLevelsScreen extends StatelessWidget {
  final String letter;
  const LetterLevelsScreen({super.key, required this.letter});

  List<_LevelInfo> _buildLevels() {
    final p = _levelProgress[letter] ??
        (mcq: false, listening: false, recording: false);
    return [
      _LevelInfo(
        id: 'mcq',
        title: 'اختيار من متعدد',
        description: 'اختر الإجابة الصحيحة',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFFFF6969),
        completed: p.mcq,
      ),
      _LevelInfo(
        id: 'listening',
        title: 'الاستماع',
        description: 'استمع وكرر',
        icon: Icons.headphones_rounded,
        color: const Color(0xFF511281),
        completed: p.listening,
      ),
      _LevelInfo(
        id: 'recording',
        title: 'التسجيل',
        description: 'سجل صوتك',
        icon: Icons.mic_rounded,
        color: const Color(0xFFFF6969),
        completed: p.recording,
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
            _LetterLevelsHeader(
              letter: letter,
              completedCount: completedCount,
              totalCount: levels.length,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  // crossAxisAlignment.start = RIGHT in RTL
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'اختر مستوى للتمرن',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF511281),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...levels.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _LevelCard(
                            level: entry.value,
                            number: entry.key + 1,
                            onTap: () {
                              // Recording goes through intro first
                              if (entry.value.id == 'recording') {
                                Navigator.pushNamed(
                                  context,
                                  '/child/letter-introduction',
                                  arguments: {'letter': letter},
                                );
                              } else {
                                Navigator.pushNamed(
                                  context,
                                  '/child/exercise/${entry.value.id}',
                                  arguments: {'letter': letter},
                                );
                              }
                            },
                          ),
                        )),
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

// ─── Header ──────────────────────────────────────────────────────────────────
// RTL order (right → left): back arrow | letter | title+subtitle
class _LetterLevelsHeader extends StatelessWidget {
  final String letter;
  final int completedCount;
  final int totalCount;

  const _LetterLevelsHeader({
    required this.letter,
    required this.completedCount,
    required this.totalCount,
  });

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
        bottom: 16,
        right: 16,
        left: 16,
      ),
      // Explicit RTL so back arrow is on the RIGHT
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // 1 — Back arrow (rightmost) - تم التغيير إلى arrow_back_ios_rounded
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () =>
                    Navigator.pushNamed(context, '/child/exercises'),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_ios_rounded, // تم التغيير هنا
                      color: Colors.white, size: 22),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // 2 — Large letter
            Text(
              letter,
              style: const TextStyle(
                fontSize: 52,
                color: Colors.white,
                fontWeight: FontWeight.w400,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 12),

            // 3 — Title + subtitle (fills remaining space)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تمارين حرف $letter',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$completedCount من $totalCount مستويات مكتملة',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
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

// ─── Level Card ──────────────────────────────────────────────────────────────
// RTL order (right → left): number badge | icon circle | title+desc | arrow
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
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.level.color;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: _buildRowContent(color),
        ),
      ),
    );
  }

  Widget _buildRowContent(Color color) {
    return Row(
      children: [
        // 1 — Number badge (rightmost in RTL)
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${widget.number}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 2 — Icon circle
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.level.icon, color: color, size: 26),
        ),
        const SizedBox(width: 14),

        // 3 — Title + description (expands)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.level.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF511281),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.level.description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ),

        // 4 — Arrow (leftmost in RTL)
        const Icon(
          Icons.arrow_forward_ios_rounded, // تم التغيير إلى arrow_forward_ios_rounded
          color: Color(0xFFCCCCCC),
          size: 18,
        ),
      ],
    );
  }
}