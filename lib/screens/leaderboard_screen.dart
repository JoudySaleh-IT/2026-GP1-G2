import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'style_constants.dart';
import '../utils/arabic_numbers.dart';
import '../widgets/child_bottom_nav.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter
// ─────────────────────────────────────────────────────────────────────────────
enum _LeaderboardFilter { friends, family, community }

enum _PlayerRelation { friend, family }

// ─────────────────────────────────────────────────────────────────────────────
// Player Model
// ─────────────────────────────────────────────────────────────────────────────
class _Player {
  final int rank;
  final String name;
  final int points;
  final int streak;

  // UI only
  final IconData avatarIcon;
  final Color avatarColor;

  // Used only for the local mock filter
  final _PlayerRelation relation;

  const _Player({
    required this.rank,
    required this.name,
    required this.points,
    required this.streak,
    required this.avatarIcon,
    required this.avatarColor,
    required this.relation,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Leaderboard Data
// نفس البيانات الأساسية، فقط تم استبدال الإيموجي بأيقونات
// ─────────────────────────────────────────────────────────────────────────────
const List<_Player> _topPlayers = [
  _Player(
    rank: 1,
    name: 'ليلى',
    points: 2850,
    streak: 25,
    avatarIcon: Icons.face_3_rounded,
    avatarColor: Color(0xFFFF9FB2),
    relation: _PlayerRelation.family,
  ),
  _Player(
    rank: 2,
    name: 'عمر',
    points: 2640,
    streak: 18,
    avatarIcon: Icons.face_6_rounded,
    avatarColor: Color(0xFF7DB7E8),
    relation: _PlayerRelation.friend,
  ),
  _Player(
    rank: 3,
    name: 'زينب',
    points: 2420,
    streak: 22,
    avatarIcon: Icons.face_4_rounded,
    avatarColor: Color(0xFFF3B35E),
    relation: _PlayerRelation.family,
  ),
  _Player(
    rank: 4,
    name: 'يوسف',
    points: 2180,
    streak: 15,
    avatarIcon: Icons.face_rounded,
    avatarColor: Color(0xFF9B78D0),
    relation: _PlayerRelation.friend,
  ),
  _Player(
    rank: 5,
    name: 'عائشة',
    points: 2050,
    streak: 12,
    avatarIcon: Icons.face_3_rounded,
    avatarColor: Color(0xFF6BC8AD),
    relation: _PlayerRelation.friend,
  ),
  _Player(
    rank: 6,
    name: 'حسن',
    points: 1980,
    streak: 20,
    avatarIcon: Icons.face_6_rounded,
    avatarColor: Color(0xFFFF8D8D),
    relation: _PlayerRelation.family,
  ),
  _Player(
    rank: 7,
    name: 'مريم',
    points: 1820,
    streak: 9,
    avatarIcon: Icons.face_4_rounded,
    avatarColor: Color(0xFFE18EC8),
    relation: _PlayerRelation.friend,
  ),
  _Player(
    rank: 8,
    name: 'علي',
    points: 1750,
    streak: 14,
    avatarIcon: Icons.face_rounded,
    avatarColor: Color(0xFF78C9DF),
    relation: _PlayerRelation.friend,
  ),
  _Player(
    rank: 9,
    name: 'نورا',
    points: 1650,
    streak: 11,
    avatarIcon: Icons.face_3_rounded,
    avatarColor: Color(0xFFA5D38E),
    relation: _PlayerRelation.family,
  ),
  _Player(
    rank: 10,
    name: 'خالد',
    points: 1580,
    streak: 16,
    avatarIcon: Icons.face_6_rounded,
    avatarColor: Color(0xFFF0A46B),
    relation: _PlayerRelation.friend,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Leaderboard Screen
// ─────────────────────────────────────────────────────────────────────────────
class LeaderboardScreen extends StatefulWidget {
  final String childId;

  const LeaderboardScreen({super.key, required this.childId});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // ─── Theme Colors ──────────────────────────────────────────────────────────
  static const _purple = Color(0xFF511281);
  static const _purple2 = Color(0xFF7B3DB3);
  static const _coral = Color(0xFFFF6969);
  static const _gold = Color(0xFFF6B91F);
  static const _bgColor = Color(0xFFFCF9EA);

  _LeaderboardFilter _selectedFilter = _LeaderboardFilter.friends;

  // ───────────────────────────────────────────────────────────────────────────
  // Filtered Mock List
  // ───────────────────────────────────────────────────────────────────────────
  List<_Player> get _visiblePlayers {
    switch (_selectedFilter) {
      case _LeaderboardFilter.friends:
        return _topPlayers
            .where((player) => player.relation == _PlayerRelation.friend)
            .toList();

      case _LeaderboardFilter.family:
        return _topPlayers
            .where((player) => player.relation == _PlayerRelation.family)
            .toList();

      case _LeaderboardFilter.community:
        return _topPlayers;
    }
  }

  String get _sectionTitle {
    switch (_selectedFilter) {
      case _LeaderboardFilter.friends:
        return 'أصدقائي';

      case _LeaderboardFilter.family:
        return 'عائلتي';

      case _LeaderboardFilter.community:
        return 'متصدرو المجتمع';
    }
  }

  String get _helperText {
    switch (_selectedFilter) {
      case _LeaderboardFilter.friends:
        return 'نافس أصدقاءك وتقدّم بينهم';

      case _LeaderboardFilter.family:
        return 'تحدَّ أفراد عائلتك وتقدّم';

      case _LeaderboardFilter.community:
        return 'شاهد ترتيبك بين جميع المتعلمين';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,

        body: Column(
          children: [
            // ================================================================
            // HEADER
            // لم يتم تغييره
            // ================================================================
            FaseehStyle.buildLargeHeader(
              context: context,
              title: 'لوحة المتصدرين',
              subtitle: 'تحدَّ نفسك وتقدّم في الترتيب!',

              leading: const SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),

              trailingActions: const [SizedBox(width: 48, height: 48)],
            ),

            // ================================================================
            // PAGE
            // ================================================================
            Expanded(
              child: Stack(
                children: [
                  // ─── Child Home-style background ──────────────────────────
                  const Positioned.fill(
                    child: IgnorePointer(child: _LeaderboardBackground()),
                  ),

                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      children: [
                        // ====================================================
                        // FILTER
                        // ====================================================
                        _buildFilter(),

                        const SizedBox(height: 8),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _helperText,
                            key: ValueKey(_selectedFilter),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF777777),
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ====================================================
                        // CURRENT CHILD
                        // Firestore logic unchanged
                        // ====================================================
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('children')
                              .doc(widget.childId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return const Text('خطأ في التحميل');
                            }

                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return const Padding(
                                padding: EdgeInsets.all(30),
                                child: CircularProgressIndicator(
                                  color: _purple,
                                ),
                              );
                            }

                            final data =
                                snapshot.data!.data() as Map<String, dynamic>;

                            final String name = data['name'] ?? 'لاعب';

                            final int points = data['points'] ?? 0;

                            final int streak = data['streak'] ?? 0;

                            final int rank = data['rank'] ?? 12;

                            return _buildCurrentUserCard(
                              name: name,
                              points: points,
                              streak: streak,
                              rank: rank,
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        // ====================================================
                        // LEADERBOARD
                        // ====================================================
                        _buildTopPlayersCard(),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ====================================================================
        // FOOTER
        // لم يتم تغييره
        // ====================================================================
        bottomNavigationBar: ChildBottomNav(
          currentRoute: '/child/leaderboard',
          childId: widget.childId,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FILTER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFilter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _purple.withOpacity(0.10), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterButton(
              label: 'الأصدقاء',
              icon: Icons.people_alt_rounded,
              selected: _selectedFilter == _LeaderboardFilter.friends,
              onTap: () {
                setState(() {
                  _selectedFilter = _LeaderboardFilter.friends;
                });
              },
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _FilterButton(
              label: 'العائلة',
              icon: Icons.family_restroom_rounded,
              selected: _selectedFilter == _LeaderboardFilter.family,
              onTap: () {
                setState(() {
                  _selectedFilter = _LeaderboardFilter.family;
                });
              },
            ),
          ),

          const SizedBox(width: 4),

          Expanded(
            child: _FilterButton(
              label: 'المجتمع',
              icon: Icons.public_rounded,
              selected: _selectedFilter == _LeaderboardFilter.community,
              onTap: () {
                setState(() {
                  _selectedFilter = _LeaderboardFilter.community;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CURRENT USER CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCurrentUserCard({
    required String name,
    required int points,
    required int streak,
    required int rank,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 185),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F0FF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _purple.withOpacity(0.14), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 9,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // ─── Soft background circles ─────────────────────────────────────
            Positioned(
              right: -45,
              top: -55,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              left: -50,
              bottom: -65,
              child: Container(
                width: 180,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFBDE6C0).withOpacity(0.55),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(100),
                    topRight: Radius.circular(100),
                  ),
                ),
              ),
            ),

            // ─── Arabic letter bubble ────────────────────────────────────────
            // ================================================================
            // Trophy - واضح بجانب الأرنب
            // ================================================================
            Positioned(
              top: 12,
              left: 88,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CF),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFFF6B91F).withOpacity(0.25),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Color(0xFFF3AD16),
                  size: 25,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ─── Current Rank ──────────────────────────────────────────
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _purple.withOpacity(0.14),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          toArabicDigits(rank),
                          style: const TextStyle(
                            fontSize: 23,
                            color: _purple,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        const Text(
                          'ترتيبك',
                          style: TextStyle(
                            fontSize: 9,
                            color: _purple,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ─── User information ──────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _purple.withOpacity(0.09),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'مركزك الحالي',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: _purple,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 19,
                            color: Color(0xFF222222),
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 10),

                        Row(
                          children: [
                            Expanded(
                              child: _CurrentStatBox(
                                icon: Icons.star_rounded,
                                value: toArabicDigits(points),
                                label: 'النقاط',
                                color: _gold,
                              ),
                            ),

                            const SizedBox(width: 7),

                            Expanded(
                              child: _CurrentStatBox(
                                icon: Icons.local_fire_department_rounded,
                                value: toArabicDigits(streak),
                                label: 'أيام متتالية',
                                color: _coral,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ─── Cute character ────────────────────────────────────────
                  const SizedBox(
                    width: 72,
                    height: 95,
                    child: _CuteLeaderboardCharacter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP PLAYERS CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopPlayersCard() {
    final players = _visiblePlayers;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _purple.withOpacity(0.10), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 17, 16, 11),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _purple.withOpacity(0.09),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: _purple,
                    size: 19,
                  ),
                ),

                const SizedBox(width: 9),

                Text(
                  _sectionTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            itemCount: players.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _buildPlayerRow(players[index]);
            },
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // PLAYER ROW
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildPlayerRow(_Player player) {
    final bool isTop3 = player.rank <= 3;

    Color backgroundColor;

    if (player.rank == 1) {
      backgroundColor = const Color(0xFFFFF9E8);
    } else if (player.rank == 2) {
      backgroundColor = const Color(0xFFF2F8FF);
    } else if (player.rank == 3) {
      backgroundColor = const Color(0xFFFFF4EB);
    } else {
      backgroundColor = const Color(0xFFFCFAFF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: isTop3
              ? _buildRankColor(player.rank).withOpacity(0.24)
              : _purple.withOpacity(0.08),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          // ─── Rank ──────────────────────────────────────────────────────────
          _buildRankBadge(player.rank),

          const SizedBox(width: 10),

          // ─── Avatar ────────────────────────────────────────────────────────
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: player.avatarColor.withOpacity(0.16),
              shape: BoxShape.circle,
              border: Border.all(color: player.avatarColor.withOpacity(0.20)),
            ),
            child: Icon(player.avatarIcon, color: player.avatarColor, size: 25),
          ),

          const SizedBox(width: 10),

          // ─── Name ──────────────────────────────────────────────────────────
          Expanded(
            child: Text(
              player.name,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF222222),
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
          ),

          // ─── Points ────────────────────────────────────────────────────────
          SizedBox(
            width: 73,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: _gold),
                    const SizedBox(width: 3),
                    Text(
                      toArabicDigits(player.points),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
                const Text(
                  'النقاط',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF777777),
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),

          // ─── Streak ────────────────────────────────────────────────────────
          SizedBox(
            width: 68,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: _coral,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      toArabicDigits(player.streak),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
                const Text(
                  'يوم',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF777777),
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

  // ───────────────────────────────────────────────────────────────────────────
  // Rank Color
  // ───────────────────────────────────────────────────────────────────────────
  Color _buildRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFF5B82E);

      case 2:
        return const Color(0xFF9EB2C5);

      case 3:
        return const Color(0xFFE59A61);

      default:
        return _purple;
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Rank Badge
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildRankBadge(int rank) {
    final color = _buildRankColor(rank);

    if (rank <= 3) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          toArabicDigits(rank),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            fontFamily: 'Tajawal',
          ),
        ),
      );
    }

    return SizedBox(
      width: 38,
      child: Center(
        child: Text(
          toArabicDigits(rank),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _purple,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Button
// ─────────────────────────────────────────────────────────────────────────────
class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF511281) : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? Colors.white : const Color(0xFF777777),
              ),

              const SizedBox(width: 5),

              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : const Color(0xFF555555),
                    fontFamily: 'Tajawal',
                  ),
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
// Current User Stat Box
// ─────────────────────────────────────────────────────────────────────────────
class _CurrentStatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _CurrentStatBox({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 17),

          const SizedBox(width: 4),

          Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF333333),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Tajawal',
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 8.5,
                  color: Color(0xFF777777),
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cute Character
// Flutter shapes only — no emoji
// ─────────────────────────────────────────────────────────────────────────────
class _CuteLeaderboardCharacter extends StatelessWidget {
  const _CuteLeaderboardCharacter();

  @override
  Widget build(BuildContext context) {
    const faceColor = Color(0xFFFFDCE7);
    const accentColor = Color(0xFF8A4BB8);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // ─── Right ear
        Positioned(
          top: 1,
          right: 11,
          child: Transform.rotate(
            angle: 0.16,
            child: Container(
              width: 19,
              height: 38,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9FB8).withOpacity(0.60),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ─── Left ear
        Positioned(
          top: 1,
          left: 11,
          child: Transform.rotate(
            angle: -0.16,
            child: Container(
              width: 19,
              height: 38,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9FB8).withOpacity(0.60),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ─── Body
        Positioned(
          bottom: 0,
          child: Container(
            width: 44,
            height: 31,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
          ),
        ),

        // ─── Head
        Positioned(
          top: 27,
          child: Container(
            width: 59,
            height: 56,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(27),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Eyes
                Positioned(
                  top: 19,
                  right: 14,
                  child: Container(
                    width: 6,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4E3655),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 19,
                  left: 14,
                  child: Container(
                    width: 6,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4E3655),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 31,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8FA3).withOpacity(0.52),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 31,
                  left: 6,
                  child: Container(
                    width: 10,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8FA3).withOpacity(0.52),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 27,
                  left: 26,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7B92),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Smile
                Positioned(
                  top: 33,
                  left: 22,
                  child: Container(
                    width: 15,
                    height: 8,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF4E3655),
                          width: 1.6,
                        ),
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
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background Decoration
// نفس فكرة Child Home
// ─────────────────────────────────────────────────────────────────────────────
class _LeaderboardBackground extends StatelessWidget {
  const _LeaderboardBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ─── دوائر خلفية كبيرة وخفيفة ─────────────────────────────
        Positioned(
          top: 70,
          right: -55,
          child: Container(
            width: 145,
            height: 145,
            decoration: BoxDecoration(
              color: const Color(0xFF511281).withOpacity(0.045),
              shape: BoxShape.circle,
            ),
          ),
        ),

        Positioned(
          top: 360,
          left: -65,
          child: Container(
            width: 165,
            height: 165,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6969).withOpacity(0.045),
              shape: BoxShape.circle,
            ),
          ),
        ),

        Positioned(
          top: 670,
          right: -45,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFFF3B82F).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // ─── دوائر صغيرة للزخرفة ────────────────────────────────
        Positioned(
          top: 180,
          left: 58,
          child: _smallDot(const Color(0xFF511281).withOpacity(0.14), 8),
        ),

        Positioned(
          top: 315,
          right: 58,
          child: _smallDot(const Color(0xFFFF6969).withOpacity(0.16), 7),
        ),

        Positioned(
          top: 590,
          left: 52,
          child: _smallDot(const Color(0xFFF3B82F).withOpacity(0.18), 9),
        ),

        Positioned(
          top: 755,
          right: 58,
          child: _smallDot(const Color(0xFF511281).withOpacity(0.12), 6),
        ),
      ],
    );
  }

  Widget _smallDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BackgroundLetter extends StatelessWidget {
  final String letter;
  final Color backgroundColor;
  final Color textColor;
  final double size;
  final bool circle;

  const _BackgroundLetter({
    required this.letter,
    required this.backgroundColor,
    required this.textColor,
    required this.size,
    this.circle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.48,
          fontWeight: FontWeight.w800,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }
}
