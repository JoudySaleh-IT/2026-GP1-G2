import 'package:flutter/material.dart';

const _levelProgress = {
  'ض': (mcq: true, listening: true, recording: false),
  'خ': (mcq: true, listening: true, recording: true),
  'غ': (mcq: false, listening: false, recording: false),
  'ص': (mcq: true, listening: false, recording: false),
  'س': (mcq: false, listening: false, recording: false),
  'ق': (mcq: false, listening: false, recording: false),
};

class _LevelInfo {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool completed;
  final bool isLocked; // ✅ إضافة خاصية القفل

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

class LetterLevelsScreen extends StatelessWidget {
  final String letter;
  final String childId;
  const LetterLevelsScreen({super.key, required this.letter, required this.childId});

  List<_LevelInfo> _buildLevels() {
    final p = _levelProgress[letter] ?? (mcq: false, listening: false, recording: false);

    // ✅ منطق التسلسل:
    // 1. المستوى الأول (MCQ) مفتوح دائماً
    bool mcqLocked = false;
    // 2. الاستماع يفتح فقط إذا اكتمل الـ MCQ
    bool listeningLocked = !p.mcq;
    // 3. التسجيل يفتح فقط إذا اكتمل الاستماع
    bool recordingLocked = !p.listening;

    return [
      _LevelInfo(
        id: 'mcq',
        title: 'اختيار من متعدد',
        description: 'اختر الإجابة الصحيحة',
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFFFF6969),
        completed: p.mcq,
        isLocked: mcqLocked,
      ),
      _LevelInfo(
        id: 'listening',
        title: 'الاستماع',
        description: 'استمع وكرر',
        icon: Icons.headphones_rounded,
        color: const Color(0xFF511281),
        completed: p.listening,
        isLocked: listeningLocked,
      ),
      _LevelInfo(
        id: 'recording',
        title: 'التسجيل',
        description: 'سجل صوتك',
        icon: Icons.mic_rounded,
        color: const Color(0xFFFF6969),
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
            _LetterLevelsHeader(
              letter: letter,
              completedCount: completedCount,
              totalCount: levels.length,
              childId: childId,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    ...levels.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _LevelCard(
                          level: entry.value,
                          number: entry.key + 1,
                          onTap: () {
                            // ✅ منع الانتقال إذا كان المستوى مغلقاً
                            if (entry.value.isLocked) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('يجب عليك إنهاء المستوى السابق أولاً!'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                              return;
                            }

                            if (entry.value.id == 'recording') {
                              Navigator.pushNamed(
                                context,
                                '/child/letter-introduction',
                                arguments: {'letter': letter, 'childId': childId},
                              );
                            } else {
                              Navigator.pushNamed(
                                context,
                                '/child/exercise/${entry.value.id}',
                                arguments: {'letter': letter, 'childId': childId},
                              );
                            }
                          },
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
    );
  }
}

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
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))],
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
            onTap: () => Navigator.pushNamed(context, '/child/exercises', arguments: childId),
          ),
          const SizedBox(width: 12),
          Text(
            letter,
            style: const TextStyle(fontSize: 52, color: Colors.white, height: 1.1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تمارين حرف $letter',
                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  '$completedCount من $totalCount مستويات مكتملة',
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

class _LevelCard extends StatefulWidget {
  final _LevelInfo level;
  final int number;
  final VoidCallback onTap;

  const _LevelCard({required this.level, required this.number, required this.onTap});

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ إذا كان المستوى مغلقاً، نستخدم اللون الرمادي
    final Color mainColor = widget.level.isLocked ? Colors.grey : widget.level.color;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => widget.level.isLocked ? null : _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Opacity(
          // ✅ تقليل الشفافية إذا كان مغلقاً ليعطي إيحاء بالقفل
          opacity: widget.level.isLocked ? 0.6 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: mainColor.withOpacity(0.15), width: 2),
              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              children: [
                // دائرة الرقم
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: mainColor, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '${widget.number}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // أيقونة المستوى
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: mainColor.withOpacity(0.12), shape: BoxShape.circle),
                  child: Icon(
                    widget.level.isLocked ? Icons.lock_outline_rounded : widget.level.icon, // ✅ عرض قفل
                    color: mainColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                // النصوص
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.level.title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: mainColor),
                      ),
                      Text(
                        widget.level.isLocked ? 'أكمل المستوى السابق للفتح' : widget.level.description,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                      ),
                    ],
                  ),
                ),
                // سهم أو علامة صح
                Icon(
                  widget.level.completed ? Icons.check_circle : Icons.arrow_forward_ios_rounded,
                  color: widget.level.completed ? Colors.green : Colors.grey.shade300,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(width: 34, height: 34, child: Icon(icon, color: Colors.white, size: 25)),
      );
}