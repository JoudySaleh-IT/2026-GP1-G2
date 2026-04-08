import 'package:flutter/material.dart';

// ─── Mock Data ────────────────────────────────────────────────────────────────
class _LetterData {
  final String letter;
  final String name;
  final int completed;
  final int total;

  const _LetterData({
    required this.letter,
    required this.name,
    required this.completed,
    required this.total,
  });
}

const _letters = [
  _LetterData(letter: 'ض', name: 'Dhad', completed: 2, total: 5),
  _LetterData(letter: 'خ', name: 'Khaa', completed: 5, total: 5),
  _LetterData(letter: 'غ', name: 'Ghayn', completed: 0, total: 5),
  _LetterData(letter: 'ص', name: 'Saad', completed: 3, total: 5),
  _LetterData(letter: 'س', name: 'Seen', completed: 0, total: 5),
  _LetterData(letter: 'ق', name: 'Qaf', completed: 1, total: 5),
];

// ─── Screen ──────────────────────────────────────────────────────────────────
class ExercisesScreen extends StatelessWidget {
  final String childId;
  const ExercisesScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    // Determine screen size for tablet optimization
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
              child: SingleChildScrollView(
                // Added responsive horizontal padding for tablets
                padding: EdgeInsets.fromLTRB(
                  isTablet ? screenWidth * 0.1 : 16,
                  16,
                  isTablet ? screenWidth * 0.1 : 16,
                  100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Letters grid ─────────────────────────────────
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        // THE FIX: Use 3 or 4 columns on tablets, 2 on phones
                        crossAxisCount: isTablet
                            ? (screenWidth > 900 ? 4 : 3)
                            : 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.88,
                      ),
                      itemCount: _letters.length,
                      itemBuilder: (context, i) {
                        final item = _letters[i];
                        return _LetterCard(
                          item: item,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/child/letter-levels',
                            arguments: {
                              'letter': item.letter,
                              'currentProgress': item.completed,
                              'childId': childId,
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _ChildBottomNav(
          currentRoute: '/child/exercises',
          childId: childId,
        ),
      ),
    );
  }
}

// ─── Stat Chip Helper ─────────────────────────────────────────────────────────
Widget _statChip({
  required IconData icon,
  required String label,
  Color iconColor = const Color(0xFF511281),
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: iconColor, size: 14),
      const SizedBox(width: 3),
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF555555),
          fontFamily: 'Tajawal',
        ),
      ),
    ],
  );
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _ExercisesHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A3A9E), Color(0xFF511281)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20, // Slightly more padding for tablet feel
        right: 20,
        left: 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'هيا نتدرب!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22, // Increased slightly for visibility
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'اختر حرفاً للتمرن عليه',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
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
    final hasProgress = widget.item.completed > 0;

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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF511281).withOpacity(0.1),
              width: 2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Text(
                    widget.item.letter,
                    style: const TextStyle(
                      fontSize:
                          60, // Reduced slightly so it doesn't crowd the card on smaller tablets
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF511281),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFEEEEEE),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        hasProgress
                            ? const Color(0xFFFF6969)
                            : const Color(0xFFDDDDDD),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${widget.item.completed}/${widget.item.total}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                      ),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 24,
            ), // Taller bar for tablets
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ), // Icon slightly bigger for tablet touch targets
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
