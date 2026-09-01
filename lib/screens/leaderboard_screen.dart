import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/auth_service.dart';
import 'style_constants.dart';
import '../utils/arabic_numbers.dart';
import '../widgets/child_bottom_nav.dart';

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
  _Player(
    rank: 1,
    name: 'ليلى',
    avatar: '🦄',
    points: 2850,
    streak: 25,
  ),
  _Player(
    rank: 2,
    name: 'عمر',
    avatar: '🦅',
    points: 2640,
    streak: 18,
  ),
  _Player(
    rank: 3,
    name: 'زينب',
    avatar: '🌟',
    points: 2420,
    streak: 22,
  ),
  _Player(
    rank: 4,
    name: 'يوسف',
    avatar: '⚡',
    points: 2180,
    streak: 15,
  ),
  _Player(
    rank: 5,
    name: 'عائشة',
    avatar: '🎨',
    points: 2050,
    streak: 12,
  ),
  _Player(
    rank: 6,
    name: 'حسن',
    avatar: '🚀',
    points: 1980,
    streak: 20,
  ),
  _Player(
    rank: 7,
    name: 'مريم',
    avatar: '🌺',
    points: 1820,
    streak: 9,
  ),
  _Player(
    rank: 8,
    name: 'علي',
    avatar: '🔥',
    points: 1750,
    streak: 14,
  ),
  _Player(
    rank: 9,
    name: 'نورا',
    avatar: '🦋',
    points: 1650,
    streak: 11,
  ),
  _Player(
    rank: 10,
    name: 'خالد',
    avatar: '🎯',
    points: 1580,
    streak: 16,
  ),
];

// ─── Leaderboard Screen ───────────────────────────────────────────────────────
class LeaderboardScreen extends StatelessWidget {
  final String childId;

  const LeaderboardScreen({
    super.key,
    required this.childId,
  });

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

  trailingActions: const [
    SizedBox(
      width: 48,
      height: 48,
    ),
  ],
),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  100,
                ),
                child: Column(
                  children: [
                    // ─────────────────────────────
                    // Current Child Card
                    // ─────────────────────────────
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('children')
                          .doc(childId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text(
                            'خطأ في التحميل',
                          );
                        }

                        if (!snapshot.hasData ||
                            !snapshot.data!.exists) {
                          return const CircularProgressIndicator(
                            color: _purple,
                          );
                        }

                        final data =
                            snapshot.data!.data()
                                as Map<String, dynamic>;

                        // استخراج البيانات الحقيقية
                        final String name =
                            data['name'] ?? 'لاعب';

                        final String avatar =
                            data['avatar'] ?? '👤';

                        final int points =
                            data['points'] ?? 0;

                        final int streak =
                            data['streak'] ?? 0;

                        return _buildCurrentUserCard(
                          name,
                          avatar,
                          points,
                          streak,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    // بقية القائمة تبقى Mock Data
                    _buildTopPlayersCard(),
                  ],
                ),
              ),
            ),
          ],
        ),

        // ─────────────────────────────────────
        // Shared Child Bottom Navigation
        // ─────────────────────────────────────
        bottomNavigationBar: ChildBottomNav(
          currentRoute: '/child/leaderboard',
          childId: childId,
        ),
      ),
    );
  }



  // ─────────────────────────────────────────────
  // Current User Card
  // ─────────────────────────────────────────────
  Widget _buildCurrentUserCard(
    String name,
    String avatar,
    int points,
    int streak,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _purple.withOpacity(0.1),
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
      child: Row(
        children: [
          // Avatar الحقيقي
          Text(
            avatar,
            style: const TextStyle(
              fontSize: 48,
            ),
          ),

          const SizedBox(width: 14),

          // Info الحقيقي
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                name,
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
                    label: 'متعلّم نشط',
                  ),

                  const SizedBox(width: 10),

                  _statChip(
                    icon: Icons.star_rounded,
                    label:
                        '${toArabicDigits(points)} نقطة',
                    iconColor: _coral,
                  ),

                  const SizedBox(width: 10),

                  _statChip(
                    icon: Icons
                        .local_fire_department_rounded,
                    label:
                        '${toArabicDigits(streak)} يوم',
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
        Icon(
          icon,
          size: 15,
          color: iconColor,
        ),

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

  // ─────────────────────────────────────────────
  // Top Players Card
  // ─────────────────────────────────────────────
  Widget _buildTopPlayersCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _purple.withOpacity(0.1),
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // Card header
          const Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  color: _purple,
                  size: 22,
                ),

                SizedBox(width: 8),

                Text(
                  'المتصدرون',
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
            physics:
                const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            itemCount: _topPlayers.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _buildPlayerRow(
              _topPlayers[index],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Player Row
  // ─────────────────────────────────────────────
  Widget _buildPlayerRow(_Player player) {
    final bool isTop3 =
        player.rank <= 3;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        gradient: isTop3
            ? const LinearGradient(
                colors: [
                  Color(0xFFFCF9EA),
                  Color(0xFFF5EFD5),
                ],
              )
            : null,
        color:
            isTop3 ? null : Colors.white,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: isTop3
              ? _purple.withOpacity(0.2)
              : _purple.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: isTop3
            ? [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // ── Rank badge ──
          SizedBox(
            width: 44,
            child: Center(
              child:
                  _buildRankBadge(
                player.rank,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // ── Avatar ──
          Text(
            player.avatar,
            style: const TextStyle(
              fontSize: 28,
            ),
          ),

          const SizedBox(width: 10),

          // ── Name + stats ──
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF222222),
                    fontWeight:
                        FontWeight.w500,
                    fontFamily: 'Tajawal',
                  ),
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: _coral,
                    ),

                    const SizedBox(width: 3),

                    Text(
                      '${toArabicDigits(player.points)} نقطة',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF666666),
                        fontFamily:
                            'Tajawal',
                      ),
                    ),

                    const SizedBox(width: 10),

                    const Icon(
                      Icons
                          .local_fire_department_rounded,
                      size: 13,
                      color: _coral,
                    ),

                    const SizedBox(width: 3),

                    Text(
                      '${toArabicDigits(player.streak)} يوم',
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            Color(0xFF666666),
                        fontFamily:
                            'Tajawal',
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

  // ─────────────────────────────────────────────
  // Rank Badge
  // ─────────────────────────────────────────────
  Widget _buildRankBadge(int rank) {
    if (rank <= 3) {
      final List<Color> colors =
          rank == 1
              ? [
                  const Color(0xFFFFD700),
                  const Color(0xFFFFA500),
                ]
              : rank == 2
                  ? [
                      const Color(0xFFCDD5D8),
                      const Color(0xFF9BA7AB),
                    ]
                  : [
                      const Color(0xFFFF8C42),
                      const Color(0xFFCC5500),
                    ];

      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:
                Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.last
                  .withOpacity(0.5),
              blurRadius: 6,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          toArabicDigits(rank),
          style: const TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
            fontSize: 15,
          ),
        ),
      );
    }

    // Regular rank text
    return Text(
      toArabicDigits(rank),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _purple,
        fontFamily: 'Tajawal',
      ),
    );
  }
}