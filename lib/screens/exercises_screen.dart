import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'style_constants.dart';

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
  final int score; // الدرجة القادمة من اختبار المستوى
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

  @override
  void initState() {
    super.initState();
    _loadChildProgress();
  }

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
              // ✅ حساب عدد المستويات المكتملة من الـ Mock
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
                  completed: completedCount, // سيعكس 1 أو 2 أو 3
                  total: 3, // إجمالي المستويات (اختيار، استماع، نطق)
                ),
              );
            }
          });
        }

        setState(() {
          _filteredLetters = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
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
        backgroundColor: const Color(0xFFFCF9EA),
        body: Column(
          children: [
            _ExercisesHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF511281),
                      ),
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
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isTablet
                              ? (screenWidth > 900 ? 4 : 3)
                              : 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: _filteredLetters.length,
                        itemBuilder: (context, i) {
                          final item = _filteredLetters[i];
                          return _LetterCard(
                            item: item,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/child/letter-levels',
                              arguments: {
                                'letter': item.letter,
                                'currentProgress': item.completed,
                                'childId': widget.childId,
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
        bottomNavigationBar: _ChildBottomNav(
          currentRoute: '/child/exercises',
          childId: widget.childId,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (!_hasCompletedPlacement) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.play_circle_outline_rounded,
              size: 80,
              color: Color(0xFF511281),
            ),
            const SizedBox(height: 16),
            const Text(
              "أهلاً بك يا بطل! 🚀",
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 22,
                color: Color(0xFF511281),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "يرجى أخذ اختبار تحديد المستوى\nمن الصفحة الرئيسية لنبدأ التمارين.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    // Existing mastery state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.stars_rounded, size: 80, color: Color(0xFF511281)),
          SizedBox(height: 16),
          Text(
            "أنت رائع! لقد أتقنت جميع الحروف 🌟",
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 20,
              color: Color(0xFF511281),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _ExercisesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: FaseehStyle.headerDecoration,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        right: 20,
        left: 20,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'هيا نتدرب!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Tajawal',
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'اختر حرفاً للتمرن عليه',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 32),
        ],
      ),
    );
  }
}

// ─── Letter Card ──────────────────────────────────────────────────────────────
class _LetterCard extends StatefulWidget {
  final _LetterData item;
  final VoidCallback onTap;
  const _LetterCard({required this.item, required this.onTap});

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
    final percent = widget.item.completed / widget.item.total;

    // ✅ تحديد الألوان بناءً على نتيجة البليسمنت تست
    // أحمر للتأسيس (< 40) وبرتقالي للتطوير (>= 40 وأقل من 70)
    final bool isCritical = widget.item.score < 40;
    final Color statusColor = isCritical
        ? const Color(0xFFFF6969)
        : Colors.orange;
    final String statusLabel = isCritical ? "تأسيس" : "تطوير";

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
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // زوايا أنعم
            border: Border.all(
              color: statusColor.withOpacity(
                0.15,
              ), // إطار خفيف جداً بلون الحالة
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04), // ظل هادئ جداً
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ✅ الحرف باللون البنفسجي الأساسي لمشروعك (يعطي فخامة)
              Text(
                widget.item.letter,
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF511281),
                  fontFamily: 'Tajawal',
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              // ✅ وسام الحالة (Badge) خلفية باهتة ونص ملون
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
              const Spacer(),
              // ✅ شريط التقدم أنحف
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF0F0F0),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${widget.item.completed}/${widget.item.total}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
class _ChildBottomNav extends StatelessWidget {
  final String currentRoute;
  final String childId;
  const _ChildBottomNav({required this.currentRoute, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A3A9E), Color(0xFF511281)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'التمارين',
                  isActive: currentRoute == '/child/exercises',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/child/exercises',
                    arguments: childId,
                  ),
                ),
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isActive: currentRoute == '/child/home',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/child/home',
                    arguments: childId,
                  ),
                ),
                _NavItem(
                  icon: Icons.leaderboard_rounded,
                  label: 'المتصدرون',
                  isActive: currentRoute == '/child/leaderboard',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/child/leaderboard',
                    arguments: childId,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFFFF6969) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12, fontFamily: 'Tajawal'),
          ),
        ],
      ),
    );
  }
}
