import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/leaderboard_service.dart';
import '../services/auth_service.dart';
import 'style_constants.dart';
import '../utils/arabic_numbers.dart';
import '../widgets/child_bottom_nav.dart';
import '../widgets/child_store_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter
// ─────────────────────────────────────────────────────────────────────────────
enum _LeaderboardFilter { friends, community }

// ─────────────────────────────────────────────────────────────────────────────
// Player Model
// ─────────────────────────────────────────────────────────────────────────────
class _Player {
  final String childId;
  final int rank;
  final String name;
  final String avatar;
  final int points;
  final int streak;
  final String ageGroup;
  final bool isCurrent;

  const _Player({
    required this.childId,
    required this.rank,
    required this.name,
    required this.avatar,
    required this.points,
    required this.streak,
    required this.ageGroup,
    required this.isCurrent,
  });

  _Player copyWithRank(int newRank) {
    return _Player(
      childId: childId,
      rank: newRank,
      name: name,
      avatar: avatar,
      points: points,
      streak: streak,
      ageGroup: ageGroup,
      isCurrent: isCurrent,
    );
  }
}

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

  final LeaderboardService _leaderboardService = LeaderboardService();

  String get _sectionTitle {
    switch (_selectedFilter) {
      case _LeaderboardFilter.friends:
        return 'أصدقائي';

      case _LeaderboardFilter.community:
        return 'متصدرو المجتمع';
    }
  }

  String get _helperText {
    switch (_selectedFilter) {
      case _LeaderboardFilter.friends:
        return 'نافس أصدقاءك وتقدّم بينهم';

      case _LeaderboardFilter.community:
        return 'شاهد ترتيبك بين أبطال فصيح من فئتك العمرية';
    }
  }

  @override
  void initState() {
    super.initState();

    _ensureLeaderboardProfile();
  }

  Future<void> _ensureLeaderboardProfile() async {
    try {
      await _leaderboardService.ensureLeaderboardProfile(
        childId: widget.childId,
      );
    } catch (e) {
      debugPrint('Leaderboard profile sync failed: $e');
    }
  }

  _Player _playerFromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};

    final String rawName = (data['name'] ?? '').toString().trim();

    return _Player(
      childId: document.id,
      rank: 0,
      name: rawName.isNotEmpty ? rawName : 'بطل فصيح',
      avatar: (data['avatar'] ?? '🌟').toString(),
      points: (data['points'] as num?)?.toInt() ?? 0,
      streak: (data['streak'] as num?)?.toInt() ?? 0,
      ageGroup: (data['ageGroup'] ?? '').toString(),
      isCurrent: document.id == widget.childId,
    );
  }

  List<_Player> _rankPlayers(List<_Player> players) {
    final sorted = List<_Player>.from(players);

    sorted.sort((a, b) {
      final pointsComparison = b.points.compareTo(a.points);

      if (pointsComparison != 0) {
        return pointsComparison;
      }

      final streakComparison = b.streak.compareTo(a.streak);

      if (streakComparison != 0) {
        return streakComparison;
      }

      // Deterministic display order only.
      // This does NOT break the ranking tie.
      return a.name.compareTo(b.name);
    });

    final ranked = <_Player>[];

    for (int i = 0; i < sorted.length; i++) {
      final player = sorted[i];

      int rank = i + 1;

      if (i > 0) {
        final previous = sorted[i - 1];

        final bool exactTie =
            player.points == previous.points &&
            player.streak == previous.streak;

        if (exactTie) {
          rank = ranked.last.rank;
        }
      }

      ranked.add(player.copyWithRank(rank));
    }

    return ranked;
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
                        _buildRealtimeLeaderboard(),

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

  Widget _buildRealtimeLeaderboard() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('leaderboard_profiles')
          .snapshots(),
      builder: (context, leaderboardSnapshot) {
        if (leaderboardSnapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Text(
              'تعذّر تحميل لوحة المتصدرين',
              style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFF777777)),
            ),
          );
        }

        if (!leaderboardSnapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: CircularProgressIndicator(color: _purple),
          );
        }

        final allPlayers = leaderboardSnapshot.data!.docs
            .map(_playerFromDocument)
            .toList();

        final currentMatches = allPlayers.where(
          (player) => player.childId == widget.childId,
        );

        if (currentMatches.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Text(
              'تعذر العثور على ملف المتصدرين',
              style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFF777777)),
            ),
          );
        }

        final currentPlayer = currentMatches.first;

        // =====================================================
        // COMMUNITY
        // Same age group only
        // =====================================================
        if (_selectedFilter == _LeaderboardFilter.community) {
          final communityPlayers = allPlayers
              .where((player) => player.ageGroup == currentPlayer.ageGroup)
              .toList();

          return _buildRankedLeaderboard(communityPlayers);
        }

        // =====================================================
        // FRIENDS
        // Query friendships where current child is childA.
        // =====================================================
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('friendships')
              .where('childA', isEqualTo: widget.childId)
              .snapshots(),
          builder: (context, childASnapshot) {
            if (childASnapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Text(
                  'تعذّر تحميل الأصدقاء',
                  style: TextStyle(fontFamily: 'Tajawal'),
                ),
              );
            }

            if (!childASnapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: CircularProgressIndicator(color: _purple),
              );
            }

            // ===============================================
            // Current child could also be childB.
            // ===============================================
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('friendships')
                  .where('childB', isEqualTo: widget.childId)
                  .snapshots(),
              builder: (context, childBSnapshot) {
                if (childBSnapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      'تعذّر تحميل الأصدقاء',
                      style: TextStyle(fontFamily: 'Tajawal'),
                    ),
                  );
                }

                if (!childBSnapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(color: _purple),
                  );
                }

                final friendIds = <String>{widget.childId};

                for (final document in childASnapshot.data!.docs) {
                  final data = document.data();

                  final friendId = (data['childB'] ?? '').toString();

                  if (friendId.isNotEmpty) {
                    friendIds.add(friendId);
                  }
                }

                for (final document in childBSnapshot.data!.docs) {
                  final data = document.data();

                  final friendId = (data['childA'] ?? '').toString();

                  if (friendId.isNotEmpty) {
                    friendIds.add(friendId);
                  }
                }

                final friendsPlayers = allPlayers
                    .where((player) => friendIds.contains(player.childId))
                    .toList();

                return _buildRankedLeaderboard(friendsPlayers);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRankedLeaderboard(List<_Player> candidates) {
    final rankedPlayers = _rankPlayers(candidates);

    final currentPlayers = rankedPlayers.where((player) => player.isCurrent);

    if (currentPlayers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Text(
          'تعذر العثور على ترتيبك',
          style: TextStyle(fontFamily: 'Tajawal', color: Color(0xFF777777)),
        ),
      );
    }

    final currentPlayer = currentPlayers.first;

    return Column(
      children: [
        _buildCurrentUserCard(
          name: currentPlayer.name,
          points: currentPlayer.points,
          streak: currentPlayer.streak,
          rank: currentPlayer.rank,
        ),

        const SizedBox(height: 18),

        _buildTopPlayersCard(rankedPlayers),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FILTER
  // تابين فقط: الأصدقاء + المجتمع
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
          // ===========================================================
          // Friends
          // ===========================================================
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

          const SizedBox(width: 5),

          // ===========================================================
          // Community
          // ===========================================================
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

            // ================================================================
            // Trophy
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
                  // ─── Current Rank
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

                  // ─── User information
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
  Widget _buildTopPlayersCard(List<_Player> players) {
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

    if (player.isCurrent) {
      backgroundColor = const Color(0xFFF4EBFC);
    } else if (player.rank == 1) {
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
          color: player.isCurrent
              ? _purple.withOpacity(0.35)
              : isTop3
              ? _buildRankColor(player.rank).withOpacity(0.24)
              : _purple.withOpacity(0.08),
          width: player.isCurrent ? 1.8 : 1.4,
        ),
      ),
      child: Row(
        children: [
          // Rank
          _buildRankBadge(player.rank),

          const SizedBox(width: 10),

          // Real child avatar
          // Real child avatar from public profile
          _LeaderboardAvatar(
            childId: player.childId,
            fallbackAvatar: player.avatar,
            size: 43,
          ),
          const SizedBox(width: 10),

          // Name
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    player.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color(0xFF222222),
                      fontWeight: player.isCurrent
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),

                if (player.isCurrent) ...[
                  const SizedBox(width: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _purple.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'أنت',
                      style: TextStyle(
                        fontSize: 9,
                        color: _purple,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Points
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

          // Streak
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF511281) : Colors.transparent,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF777777),
              ),

              const SizedBox(width: 6),

              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
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
            decoration: const BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.only(
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

class _LeaderboardAvatar extends StatelessWidget {
  final String childId;
  final String fallbackAvatar;
  final double size;

  const _LeaderboardAvatar({
    required this.childId,
    required this.fallbackAvatar,
    this.size = 43,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('child_public_profiles')
          .doc(childId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        return StoreAvatarImage(
          avatar: data?['avatar']?.toString() ?? fallbackAvatar,
          avatarId: data?['equippedAvatarId']?.toString(),
          backgroundId: data?['equippedBackgroundId']?.toString(),
          size: size,
        );
      },
    );
  }
}
