import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'friend_requests_screen.dart';
import 'style_constants.dart';

class NotificationsScreen extends StatelessWidget {
  final String childId;

  const NotificationsScreen({
    super.key,
    required this.childId,
  });

  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  Future<Map<String, dynamic>?> _getSenderProfile(
    String senderId,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('child_public_profiles')
        .doc(senderId)
        .get();

    if (!snapshot.exists) return null;

    return snapshot.data();
  }

  Future<void> _openNotification(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> notification,
  ) async {
    final data = notification.data();
    final String type = data['type']?.toString() ?? '';

    // Mark as read
    if (data['isRead'] != true) {
      await notification.reference.update({
        'isRead': true,
      });
    }

    if (!context.mounted) return;

    if (type == 'friend_request') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FriendRequestsScreen(
            childId: childId,
          ),
        ),
      );
    }

    // practice_invitation
    // بنربطه لاحقًا بشاشة Practice Together
  }
String _formatNotificationTime(Timestamp? timestamp) {
  if (timestamp == null) return '';

  final DateTime createdAt = timestamp.toDate();
  final DateTime now = DateTime.now();

  final Duration difference = now.difference(createdAt);

  if (difference.inSeconds < 60) {
    final seconds = difference.inSeconds;

    if (seconds <= 5) {
      return 'الآن';
    }

    return 'منذ $seconds ثانية';
  }

  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;

    if (minutes == 1) {
      return 'منذ دقيقة';
    }

    return 'منذ $minutes دقائق';
  }

  if (difference.inHours < 24) {
    final hours = difference.inHours;

    if (hours == 1) {
      return 'منذ ساعة';
    }

    return 'منذ $hours ساعات';
  }

  const months = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  return '${createdAt.day} ${months[createdAt.month - 1]} ${createdAt.year}';
}
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        body: Column(
          children: [
            // ===============================================================
            // HEADER
            // ===============================================================
            FaseehStyle.buildLargeHeader(
              context: context,
              title: 'الإشعارات',
              subtitle: 'تابع آخر التحديثات والدعوات',
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===============================================================
            // BODY
            // ===============================================================
            Expanded(
              child:
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where(
                      'receiverId',
                      isEqualTo: childId,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Stack(
                      children: [
                        Positioned.fill(
                          child: _NotificationsBackground(),
                        ),
                        Center(
                          child: CircularProgressIndicator(
                            color: _purple,
                          ),
                        ),
                      ],
                    );
                  }

                  if (snapshot.hasError) {
                    return const Stack(
                      children: [
                        Positioned.fill(
                          child: _NotificationsBackground(),
                        ),
                        _NotificationMessageView(
                          isError: true,
                          title: 'تعذّر تحميل الإشعارات',
                          message: 'حاول مرة أخرى بعد قليل',
                        ),
                      ],
                    );
                  }

                  final allNotifications =
    snapshot.data?.docs.toList() ?? [];

final sevenDaysAgo =
    DateTime.now().subtract(const Duration(days: 7));

final notifications = allNotifications.where((notification) {
  final data = notification.data();

  final bool isRead = data['isRead'] == true;
  final Timestamp? createdAt =
      data['createdAt'] as Timestamp?;

  // الإشعار غير المقروء يبقى مهما كان عمره
  if (!isRead) {
    return true;
  }

  // احتياطًا: إذا ما عنده تاريخ نخليه ظاهر
  if (createdAt == null) {
    return true;
  }

  // المقروء يظهر فقط إذا عمره أقل من 7 أيام
  return createdAt.toDate().isAfter(sevenDaysAgo);
}).toList();

                  // Newest first
                  notifications.sort((a, b) {
                    final aTime =
                        a.data()['createdAt'] as Timestamp?;
                    final bTime =
                        b.data()['createdAt'] as Timestamp?;

                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;

                    return bTime.compareTo(aTime);
                  });

                  if (notifications.isEmpty) {
                    return const Stack(
                      children: [
                        Positioned.fill(
                          child: _NotificationsBackground(),
                        ),
                        _NotificationMessageView(
                          title: 'لا توجد إشعارات جديدة',
                          message: 'ستظهر إشعاراتك ودعوات أصدقائك هنا',
                        ),
                      ],
                    );
                  }

                  return Stack(
                    children: [
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: _NotificationsBackground(),
                        ),
                      ),

                      ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          18,
                          18,
                          30,
                        ),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 11),
                        itemBuilder: (context, index) {
                          final notification =
                              notifications[index];

                          final data = notification.data();

                          final senderId =
                              data['senderId']?.toString() ?? '';

                          final type =
                              data['type']?.toString() ?? '';

                          final isRead =
                              data['isRead'] == true;

                              final createdAt =
    data['createdAt'] as Timestamp?;

final timeText =
    _formatNotificationTime(createdAt);

                          return FutureBuilder<
                              Map<String, dynamic>?>(
                            future: _getSenderProfile(senderId),
                            builder: (context, profileSnapshot) {
                              if (profileSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const _NotificationLoadingCard();
                              }

                              final profile =
                                  profileSnapshot.data;

                              final name =
                                  profile?['name']?.toString() ??
                                      'صديقك';

                              final avatar =
                                  profile?['avatar']?.toString() ??
                                      '🌟';

                              return _NotificationCard(
                                name: name,
                                avatar: avatar,
                                type: type,
                                isRead: isRead,
                                timeText: timeText,

                                onTap: () {
                                  _openNotification(
                                    context,
                                    notification,
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// NOTIFICATION CARD
// =============================================================================

class _NotificationCard extends StatelessWidget {
  final String name;
  final String avatar;
  final String type;
  final bool isRead;
  final VoidCallback onTap;
  final String timeText;

  const _NotificationCard({
    required this.name,
    required this.avatar,
    required this.type,
    required this.isRead,
    required this.onTap,
    required this.timeText,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF511281);
    const coral = Color(0xFFFF6969);

    final bool isFriendRequest =
        type == 'friend_request';

    final bool isPracticeInvitation =
        type == 'practice_invitation';

    String title;
    String message;
    IconData typeIcon;
    Color tagBackground;
    Color tagColor;

    if (isFriendRequest) {
      title = 'طلب صداقة جديد';
      message = 'أرسل لك $name طلب صداقة';
      typeIcon = Icons.person_add_alt_1_rounded;
      tagBackground = const Color(0xFFF1F8F3);
      tagColor = const Color(0xFF70A884);
    } else if (isPracticeInvitation) {
      title = 'دعوة للتدرّب معًا';
      message = 'دعاك $name للتدرّب معًا';
      typeIcon = Icons.groups_rounded;
      tagBackground = const Color(0xFFFFF1E8);
      tagColor = const Color(0xFFE59A61);
    } else {
      title = 'إشعار جديد';
      message = 'لديك إشعار جديد';
      typeIcon = Icons.notifications_rounded;
      tagBackground = const Color(0xFFF3EBFA);
      tagColor = purple;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(23),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead
                ? Colors.white.withValues(alpha: 0.94)
                : const Color(0xFFF7F0FF),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: isRead
                  ? purple.withValues(alpha: 0.07)
                  : purple.withValues(alpha: 0.15),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x09000000),
                blurRadius: 7,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3EBFA),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: purple.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      avatar,
                      style: const TextStyle(fontSize: 34),
                    ),
                  ),

                  Positioned(
                    left: -3,
                    bottom: -2,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isFriendRequest
                            ? const Color(0xFFFFE7EC)
                            : const Color(0xFFE9F4EC),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        typeIcon,
                        color: isFriendRequest
                            ? coral
                            : const Color(0xFF70A884),
                        size: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: purple,
                            ),
                          ),
                        ),

                        if (!isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: coral,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
  message,
  textAlign: TextAlign.right,
  style: const TextStyle(
    fontFamily: 'Tajawal',
    fontSize: 11.5,
    color: Color(0xFF808080),
  ),
),

const SizedBox(height: 5),

if (timeText.isNotEmpty)
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.access_time_rounded,
        size: 12,
        color: Color(0xFFA9A0AE),
      ),
      const SizedBox(width: 4),
      Text(
        timeText,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFFA9A0AE),
        ),
      ),
    ],
  ),

const SizedBox(height: 7),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: tagBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            typeIcon,
                            size: 13,
                            color: tagColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isFriendRequest
                                ? 'طلب صداقة'
                                : isPracticeInvitation
                                    ? 'تدرّب معًا'
                                    : 'إشعار',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: tagColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// LOADING CARD
// =============================================================================

class _NotificationLoadingCard extends StatelessWidget {
  const _NotificationLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(23),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF511281),
        ),
      ),
    );
  }
}

// =============================================================================
// EMPTY / ERROR
// =============================================================================

class _NotificationMessageView extends StatelessWidget {
  final String title;
  final String message;
  final bool isError;

  const _NotificationMessageView({
    required this.title,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            22,
          ),
          decoration: BoxDecoration(
            color: isError
                ? const Color(0xFFFFF4F1)
                : const Color(0xFFF7F0FF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isError
                  ? const Color(0xFFFF6969)
                      .withValues(alpha: 0.08)
                  : const Color(0xFF511281)
                      .withValues(alpha: 0.07),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 118,
                child: _NotificationBunny(
                  isError: isError,
                ),
              ),

              const SizedBox(height: 9),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isError
                      ? const Color(0xFFD7685B)
                      : const Color(0xFF511281),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xFF858085),
                ),
              ),

              const SizedBox(height: 13),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isError
                      ? Icons.priority_high_rounded
                      : Icons.notifications_none_rounded,
                  size: 18,
                  color: isError
                      ? const Color(0xFFE08073)
                      : const Color(0xFF9A73B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// BACKGROUND
// =============================================================================

class _NotificationsBackground extends StatelessWidget {
  const _NotificationsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 45,
          right: -55,
          child: _circle(
            145,
            const Color(0xFFDCC9F5)
                .withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          top: 300,
          left: -65,
          child: _circle(
            155,
            const Color(0xFFDDF2E3)
                .withValues(alpha: 0.25),
          ),
        ),
        Positioned(
          top: 575,
          right: -50,
          child: _circle(
            125,
            const Color(0xFFFFDCE3)
                .withValues(alpha: 0.23),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 38,
          child: _circle(
            20,
            const Color(0xFFD5BFE9)
                .withValues(alpha: 0.33),
          ),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

// =============================================================================
// NOTIFICATION BUNNY
// =============================================================================

class _NotificationBunny extends StatelessWidget {
  final bool isError;

  const _NotificationBunny({
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    const face = Color(0xFFFFDCE7);

    final body = isError
        ? const Color(0xFFD5A1A1)
        : const Color(0xFFB497C9);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Bell bubble
        Positioned(
          right: 3,
          bottom: 7,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isError
                  ? const Color(0xFFFFE5E1)
                  : const Color(0xFFDDEEE2),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isError
                  ? Icons.priority_high_rounded
                  : Icons.notifications_none_rounded,
              color: isError
                  ? const Color(0xFFE08073)
                  : const Color(0xFF70A884),
              size: 21,
            ),
          ),
        ),

        // Ears
        Positioned(
          top: 5,
          right: 30,
          child: _NotificationBunnyEar(
            color: face,
          ),
        ),

        Positioned(
          top: 14,
          left: 21,
          child: Transform.rotate(
            angle: -0.48,
            child: _NotificationBunnyEar(
              color: face,
            ),
          ),
        ),

        // Body
        Positioned(
          bottom: 3,
          child: Container(
            width: 49,
            height: 32,
            decoration: BoxDecoration(
              color: body,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ),

        // Head
        Positioned(
          top: 39,
          child: Container(
            width: 65,
            height: 60,
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: 22,
                  right: 15,
                  child: _NotificationBunnyEye(),
                ),
                const Positioned(
                  top: 22,
                  left: 15,
                  child: _NotificationBunnyEye(),
                ),
                const Positioned(
                  top: 31,
                  left: 29,
                  child: _NotificationBunnyNose(),
                ),

                Positioned(
                  top: 39,
                  left: 25,
                  child: Container(
                    width: 15,
                    height: 6,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF4D3855),
                          width: 1.3,
                        ),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                  ),
                ),

                const Positioned(
                  top: 36,
                  right: 7,
                  child: _NotificationBunnyCheek(),
                ),
                const Positioned(
                  top: 36,
                  left: 7,
                  child: _NotificationBunnyCheek(),
                ),
              ],
            ),
          ),
        ),

        // Waiting dots
        if (!isError)
          Positioned(
            top: 12,
            right: 5,
            child: Row(
              children: [
                _dot(4),
                const SizedBox(width: 3),
                _dot(6),
                const SizedBox(width: 3),
                _dot(4),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dot(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF9A73B8)
            .withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NotificationBunnyEar extends StatelessWidget {
  final Color color;

  const _NotificationBunnyEar({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFFA1B7)
                .withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _NotificationBunnyEye extends StatelessWidget {
  const _NotificationBunnyEye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 7,
      decoration: const BoxDecoration(
        color: Color(0xFF4D3855),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NotificationBunnyNose extends StatelessWidget {
  const _NotificationBunnyNose();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 5,
      decoration: const BoxDecoration(
        color: Color(0xFFFF7890),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NotificationBunnyCheek extends StatelessWidget {
  const _NotificationBunnyCheek();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFFF96AC)
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}