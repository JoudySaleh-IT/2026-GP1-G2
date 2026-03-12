import 'package:flutter/material.dart';

// ─── Mock Data ───────────────────────────────────────────────────────────────
const _mockChild = (
  name: 'أحمد',
  avatar: '🦁',
  level: 'متوسط',
  streak: 7,
  points: 1250,
  rank: 12,
  todayExercises: 2,
  todayGoal: 5,
);

// ─── Screen ──────────────────────────────────────────────────────────────────
class ChildHomeScreen extends StatelessWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: Column(
          children: [
            _ChildHeader(
              name: _mockChild.name,
              avatar: _mockChild.avatar,
              level: _mockChild.level,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                child: Column(
                  children: [
                    // ── Placement test banner ──────────────────────────
                    _PlacementTestBanner(
                      onTap: () =>
                          Navigator.pushNamed(context, '/child/placement-test'),
                    ),
                    const SizedBox(height: 16),

                    // ── Stats row ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.local_fire_department,
                            value: _mockChild.streak.toString(),
                            label: 'المواظبة',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.star,
                            value: _mockChild.points.toString(),
                            label: 'النقاط',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.emoji_events,
                            value: '#${_mockChild.rank}',
                            label: 'الترتيب',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Today's goal card ──────────────────────────────
                    _TodayGoalCard(
                      done: _mockChild.todayExercises,
                      goal: _mockChild.todayGoal,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // ── Bottom navigation bar ──────────────────────────────────────
        bottomNavigationBar: const _ChildBottomNav(currentRoute: '/child/home'),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
class _ChildHeader extends StatelessWidget {
  final String name;
  final String avatar;
  final String level;

  const _ChildHeader({
    required this.name,
    required this.avatar,
    required this.level,
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
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pushNamed(context, '/parent/dashboard'),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_forward, // RTL back = arrow forward
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Text(avatar, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 10),

          // Name + level
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مرحبا $name!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                level,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Placement Test Banner ────────────────────────────────────────────────────
class _PlacementTestBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _PlacementTestBanner({required this.onTap});

  @override
  State<_PlacementTestBanner> createState() => _PlacementTestBannerState();
}

class _PlacementTestBannerState extends State<_PlacementTestBanner>
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
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6969),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44FF6969),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Text
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اختبار تحديد المستوى',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'استكشف مستواك اللغوي!',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
              // Play icon
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF511281).withOpacity(0.1),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF511281), size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Today's Goal Card ────────────────────────────────────────────────────────
class _TodayGoalCard extends StatelessWidget {
  final int done;
  final int goal;

  const _TodayGoalCard({required this.done, required this.goal});

  @override
  Widget build(BuildContext context) {
    final remaining = goal - done;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF511281).withOpacity(0.1),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'هدف اليوم',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222222),
                ),
              ),
              Text(
                '$done/$goal',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF6969),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / goal,
              minHeight: 8,
              backgroundColor: const Color(0xFFFF6969).withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF6969),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Remaining text
          Text(
            'تحتاج $remaining تدريبات لتحقيق الهدف!',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
class _ChildBottomNav extends StatelessWidget {
  final String currentRoute;
  const _ChildBottomNav({required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr, // nav items always LTR
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'التمارين',
                  isActive: currentRoute == '/child/exercises',
                  onTap: () => Navigator.pushNamed(context, '/child/exercises'),
                ),
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isActive: currentRoute == '/child/home',
                  onTap: () => Navigator.pushNamed(context, '/child/home'),
                ),
                _NavItem(
                  icon: Icons.leaderboard_rounded,
                  label: 'المتصدرون',
                  isActive: currentRoute == '/child/leaderboard',
                  onTap: () =>
                      Navigator.pushNamed(context, '/child/leaderboard'),
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
