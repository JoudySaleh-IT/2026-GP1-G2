import 'package:flutter/material.dart';

// ─── Mock Data Models ─────────────────────────────────────────────────────────
class _Player {
  final int rank;
  final String name;
  final String avatar;
  final int points;
  final int streak;
  final bool isCurrentUser;

  const _Player({
    required this.rank,
    required this.name,
    required this.avatar,
    required this.points,
    required this.streak,
    this.isCurrentUser = false,
  });
}

// ─── Mock Data ────────────────────────────────────────────────────────────────
const _currentUser = _Player(
  rank: 12,
  name: 'أحمد',
  avatar: '🦁',
  points: 1250,
  streak: 7,
  isCurrentUser: true,
);

const List<_Player> _topPlayers = [
  _Player(rank: 1, name: 'ليلى', avatar: '🦄', points: 2850, streak: 25),
  _Player(rank: 2, name: 'عمر', avatar: '🦅', points: 2640, streak: 18),
  _Player(rank: 3, name: 'زينب', avatar: '🌟', points: 2420, streak: 22),
  _Player(rank: 4, name: 'يوسف', avatar: '⚡', points: 2180, streak: 15),
  _Player(rank: 5, name: 'عائشة', avatar: '🎨', points: 2050, streak: 12),
  _Player(rank: 6, name: 'حسن', avatar: '🚀', points: 1980, streak: 20),
  _Player(rank: 7, name: 'مريم', avatar: '🌺', points: 1820, streak: 9),
  _Player(rank: 8, name: 'علي', avatar: '🔥', points: 1750, streak: 14),
  _Player(rank: 9, name: 'نورا', avatar: '🦋', points: 1650, streak: 11),
  _Player(rank: 10, name: 'خالد', avatar: '🎯', points: 1580, streak: 16),
];

// ─── Leaderboard Screen ───────────────────────────────────────────────────────
class LeaderboardScreen extends StatelessWidget {
    final String childId;
  const LeaderboardScreen({super.key, required this.childId});

  // ── Constants ──
  static const _purple = Color(0xFF511281);
  static const _purple2 = Color(0xFF6A3A9E);
  static const _coral = Color(0xFFFF6969);
  static const _bgColor = Color(0xFFFCF9EA);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(overscroll: false),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  child: Column(
                    children: [
                      _buildCurrentUserCard(),
                      const SizedBox(height: 16),
                      _buildTopPlayersCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _ChildBottomNav(
    currentRoute: '/child/leaderboard',
    childId: childId,
  ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_purple2, _purple],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Trophy icon + title
              const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 26,
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لوحة المتصدرين',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                  Text(
                    'تنافس مع المتعلمين من حولك',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
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

  // ── Current User Card ──
  Widget _buildCurrentUserCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.1), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Text(_currentUser.avatar, style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 14),

          // Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentUser.name,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF222222),
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _statChip(
                    icon: Icons.emoji_events_rounded,
                    label: 'الترتيب #${_currentUser.rank}',
                  ),
                  const SizedBox(width: 10),
                  _statChip(
                    icon: Icons.star_rounded,
                    label: '${_currentUser.points} نقطة',
                    iconColor: _coral,
                  ),
                  const SizedBox(width: 10),
                  _statChip(
                    icon: Icons.local_fire_department_rounded,
                    label: '${_currentUser.streak} يوم',
                    iconColor: _coral,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String label,
    Color iconColor = _purple,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }

  // ── Top Players Card ──
  Widget _buildTopPlayersCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.1), width: 2),
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
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: _purple,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Text(
                  'أفضل اللاعبين',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),

          // Player rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: _topPlayers.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildPlayerRow(_topPlayers[index]),
          ),
        ],
      ),
    );
  }

  // ── Player Row ──
  Widget _buildPlayerRow(_Player player) {
    final isTop3 = player.rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        gradient: isTop3
            ? const LinearGradient(
                colors: [Color(0xFFFCF9EA), Color(0xFFF5EFD5)],
              )
            : null,
        color: isTop3 ? null : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTop3 ? _purple.withOpacity(0.2) : _purple.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // ── Rank badge (rightmost in RTL) ──
          SizedBox(
            width: 44,
            child: Center(child: _buildRankBadge(player.rank)),
          ),
          const SizedBox(width: 10),

          // ── Avatar ──
          Text(player.avatar, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),

          // ── Name + stats ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF222222),
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 13, color: _coral),
                    const SizedBox(width: 3),
                    Text(
                      '${player.points} نقطة',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 13,
                      color: _coral,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${player.streak} يوم',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Rank Badge ──
  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      // Gold / Silver / Bronze gradient circles
      final List<Color> colors = rank == 1
          ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
          : rank == 2
          ? [const Color(0xFFCDD5D8), const Color(0xFF9BA7AB)]
          : [const Color(0xFFFF8C42), const Color(0xFFCC5500)];

      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.5),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$rank',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      );
    }

    // Regular rank text
    return Text(
      '#$rank',
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _purple,
        fontFamily: 'Tajawal',
      ),
    );
  }
}

// ─── Bottom Navigation Bar (shared style) ────────────────────────────────────
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
  icon: Icons.menu_book_rounded,
  label: 'التمارين',
  isActive: currentRoute == '/child/exercises',
  onTap: () => Navigator.pushNamed(
    context, '/child/exercises',
    arguments: childId, // ✅
  ),
),
_NavItem(
  icon: Icons.home_rounded,
  label: 'الرئيسية',
  isActive: currentRoute == '/child/home',
  onTap: () => Navigator.pushNamed(
    context, '/child/home',
    arguments: childId, // ✅
  ),
),
_NavItem(
  icon: Icons.leaderboard_rounded,
  label: 'المتصدرون',
  isActive: currentRoute == '/child/leaderboard',
  onTap: () => Navigator.pushNamed(
    context, '/child/leaderboard',
    arguments: childId, // ✅
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
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
