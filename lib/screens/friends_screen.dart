import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_friend_screen.dart';
import 'friend_requests_screen.dart';
import '../widgets/child_bottom_nav.dart';
import '../services/friend_service.dart';
import 'style_constants.dart';

class FriendsScreen extends StatelessWidget {
  final String childId;

  const FriendsScreen({
    super.key,
    required this.childId,
  });

  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  // ─────────────────────────────────────────────
  // Standard app SnackBar
  // نفس شكل الرسائل الموجودة في باقي التطبيق
  // ─────────────────────────────────────────────
  void _showAppSnackBar(
    BuildContext context, {
    required String message,
    Color backgroundColor = _purple,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    // يمنع تكدس الرسائل فوق بعض
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.fixed,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              message,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Confirm + Remove Friend
  // ─────────────────────────────────────────────
  Future<void> _confirmRemoveFriend(
    BuildContext context, {
    required String friendId,
    required String friendName,
  }) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'إزالة صديق',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'هل أنت متأكد أنك تريد إزالة $friendName من أصدقائك؟',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Tajawal',
              ),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              // الفعل المهم على اليمين
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _coral,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'إزالة',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // الإلغاء على اليسار
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FriendService().removeFriend(
        currentChildId: childId,
        friendId: friendId,
      );

      if (!context.mounted) return;

      _showAppSnackBar(
        context,
        message: 'تمت إزالة $friendName من قائمة أصدقائك',
        backgroundColor: _purple,
      );
    } catch (_) {
      if (!context.mounted) return;

      _showAppSnackBar(
        context,
        message: 'تعذّرت إزالة الصديق. حاول مرة أخرى.',
        backgroundColor: _coral,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,

        // ─────────────────────────────────────
        // Body
        // ─────────────────────────────────────
        body: Column(
          children: [
            // ─────────────────────────────────
            // Shared Header
            // نفس هيدر التمارين والمتصدرين
            // ─────────────────────────────────
            FaseehStyle.buildLargeHeader(
              context: context,
              title: 'أصدقائي',
              subtitle: 'أضف أصدقاء وتدرّبوا معًا',
              leading: const SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(
                    Icons.people_alt_rounded,
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

            // ─────────────────────────────────
            // Page Content
            // ─────────────────────────────────
            Expanded(
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─────────────────────────────
                      // إضافة صديق
                      // ─────────────────────────────
                      _MainActionCard(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'إضافة صديق',
                        subtitle: 'أضف صديقًا باستخدام رمز QR',
                        color: _coral,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddFriendScreen(
                                childId: childId,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      // ─────────────────────────────
                      // طلبات الصداقة
                      // ─────────────────────────────
                      StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('friend_requests')
                            .where(
                              'receiverId',
                              isEqualTo: childId,
                            )
                            .snapshots(),
                        builder: (context, snapshot) {
                          final int requestCount =
                              snapshot.data?.docs.length ?? 0;

                          return _MainActionCard(
                            icon: Icons.notifications_active_rounded,
                            title: 'طلبات الصداقة',
                            subtitle: requestCount > 0
                                ? 'لديك $requestCount طلب جديد'
                                : 'لا توجد طلبات جديدة',
                            color: _purple,
                            badgeCount: requestCount,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FriendRequestsScreen(
                                    childId: childId,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // ─────────────────────────────
                      // عنوان قائمة الأصدقاء
                      // ─────────────────────────────
                      const Text(
                        'قائمة الأصدقاء',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _purple,
                          fontFamily: 'Tajawal',
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ─────────────────────────────
                      // Friendships - childA
                      // ─────────────────────────────
                      StreamBuilder<
                          QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('friendships')
                            .where(
                              'childA',
                              isEqualTo: childId,
                            )
                            .snapshots(),
                        builder: (
                          context,
                          childASnapshot,
                        ) {
                          if (childASnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(30),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _purple,
                                ),
                              ),
                            );
                          }

                          if (childASnapshot.hasError) {
                            return const _EmptyFriendsView(
                              icon: Icons.error_outline_rounded,
                              title: 'تعذّر تحميل الأصدقاء',
                              message: 'حاول مرة أخرى بعد قليل',
                            );
                          }

                          // ─────────────────────────
                          // Friendships - childB
                          // ─────────────────────────
                          return StreamBuilder<
                              QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('friendships')
                                .where(
                                  'childB',
                                  isEqualTo: childId,
                                )
                                .snapshots(),
                            builder: (
                              context,
                              childBSnapshot,
                            ) {
                              if (childBSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(30),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: _purple,
                                    ),
                                  ),
                                );
                              }

                              if (childBSnapshot.hasError) {
                                return const _EmptyFriendsView(
                                  icon: Icons.error_outline_rounded,
                                  title: 'تعذّر تحميل الأصدقاء',
                                  message: 'حاول مرة أخرى بعد قليل',
                                );
                              }

                              final friendships = [
                                ...?childASnapshot.data?.docs,
                                ...?childBSnapshot.data?.docs,
                              ];

                              if (friendships.isEmpty) {
                                return const _EmptyFriendsView(
                                  icon: Icons.people_outline_rounded,
                                  title: 'لم تضف أصدقاء بعد',
                                  message:
                                      'أضف صديقًا لتتمرّنا معًا',
                                );
                              }

                              return Column(
                                children: friendships.map(
                                  (friendship) {
                                    final data =
                                        friendship.data();

                                    final String childA =
                                        data['childA']
                                                ?.toString() ??
                                            '';

                                    final String childB =
                                        data['childB']
                                                ?.toString() ??
                                            '';

                                    if (childA.isEmpty ||
                                        childB.isEmpty) {
                                      return const SizedBox
                                          .shrink();
                                    }

                                    final String friendId =
                                        childA == childId
                                            ? childB
                                            : childA;

                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child:
                                          _FriendProfileCard(
                                        key: ValueKey(
                                          friendId,
                                        ),
                                        friendId: friendId,
                                        onRemove: (
                                          friendName,
                                        ) {
                                          _confirmRemoveFriend(
                                            context,
                                            friendId:
                                                friendId,
                                            friendName:
                                                friendName,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ).toList(),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // ─────────────────────────────────────
        // Child Bottom Navigation
        // ─────────────────────────────────────
        bottomNavigationBar: ChildBottomNav(
          currentRoute: '/child/friends',
          childId: childId,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Main Action Card
// ─────────────────────────────────────────────
class _MainActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final int badgeCount;

  const _MainActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.10),
            ),
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
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 29,
                    ),
                  ),

                  if (badgeCount > 0)
                    Positioned(
                      top: -6,
                      left: -6,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6969),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Friend Profile Card
// يمنع إعادة تحميل البروفايل مع كل rebuild
// ─────────────────────────────────────────────
class _FriendProfileCard extends StatefulWidget {
  final String friendId;
  final void Function(String friendName) onRemove;

  const _FriendProfileCard({
    super.key,
    required this.friendId,
    required this.onRemove,
  });

  @override
  State<_FriendProfileCard> createState() =>
      _FriendProfileCardState();
}

class _FriendProfileCardState
    extends State<_FriendProfileCard> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  @override
  void didUpdateWidget(
    covariant _FriendProfileCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.friendId != widget.friendId) {
      _profileFuture = _loadProfile();
    }
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('child_public_profiles')
        .doc(widget.friendId)
        .get()
        .timeout(
          const Duration(seconds: 8),
        );

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _FriendLoadingCard();
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text(
              'تعذّر تحميل بيانات الصديق',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.grey,
              ),
            ),
          );
        }

        final profile = snapshot.data!;

        final String name =
            profile['name']?.toString() ?? 'صديق';

        final String avatar =
            profile['avatar']?.toString() ?? '🌟';

        return _FriendCard(
          name: name,
          avatar: avatar,
          onRemove: () {
            widget.onRemove(name);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Friend Card
// ─────────────────────────────────────────────
class _FriendCard extends StatelessWidget {
  final String name;
  final String avatar;
  final VoidCallback onRemove;

  const _FriendCard({
    required this.name,
    required this.avatar,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF511281);
    const coral = Color(0xFFFF6969);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: purple.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: purple.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Text(
              avatar,
              style: const TextStyle(
                fontSize: 31,
              ),
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Text(
              name,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: purple,
                fontFamily: 'Tajawal',
              ),
            ),
          ),

          IconButton(
            tooltip: 'إزالة الصديق',
            onPressed: onRemove,
            icon: const Icon(
              Icons.person_remove_rounded,
              color: coral,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Friend Loading Card
// ─────────────────────────────────────────────
class _FriendLoadingCard extends StatelessWidget {
  const _FriendLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF511281),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────
class _EmptyFriendsView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyFriendsView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFF511281)
                  .withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF511281),
              size: 38,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF511281),
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),

          const SizedBox(height: 6),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}