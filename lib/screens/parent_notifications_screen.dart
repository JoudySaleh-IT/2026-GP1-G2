import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'style_constants.dart';

class ParentNotificationsScreen extends StatelessWidget {
  const ParentNotificationsScreen({super.key});

  static const Color _purple = Color(0xFF511281);
  static const Color _background = Color(0xFFFCF9EA);

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
              subtitle: 'تابع آخر التحديثات المتعلقة بأطفالك',
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
  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('parent_notifications')
        .where(
          'parentId',
          isEqualTo: FirebaseAuth.instance.currentUser!.uid,
        )
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Stack(
          children: [
            Positioned.fill(
              child: _ParentNotificationsBackground(),
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
              child: _ParentNotificationsBackground(),
            ),
            _ParentNotificationMessageView(
              title: 'تعذّر تحميل الإشعارات',
              message: 'حاول مرة أخرى بعد قليل',
            ),
          ],
        );
      }

      final notifications = snapshot.data?.docs.toList() ?? [];

      // Newest first
      notifications.sort((a, b) {
        final aTime = a.data()['createdAt'] as Timestamp?;
        final bTime = b.data()['createdAt'] as Timestamp?;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime);
      });

      if (notifications.isEmpty) {
        return const Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: _ParentNotificationsBackground(),
              ),
            ),
            _ParentNotificationMessageView(
              title: 'لا توجد إشعارات جديدة',
              message:
                  'ستظهر هنا آخر التحديثات المتعلقة بأطفالك',
            ),
          ],
        );
      }

      return Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(
              child: _ParentNotificationsBackground(),
            ),
          ),

          ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 11),
            itemBuilder: (context, index) {
              final notification = notifications[index];

              return _ParentNotificationItem(
                notification: notification,
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
class _ParentNotificationItem extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> notification;

  const _ParentNotificationItem({
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    final data = notification.data();

    final String childId = data['childId']?.toString() ?? '';
    final bool isRead = data['isRead'] == true;
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .get(),
      builder: (context, childSnapshot) {
        if (childSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const _ParentNotificationLoadingCard();
        }

        final childData = childSnapshot.data?.data();

        final String nickname =
            (childData?['nickname'] ?? '').toString().trim();

        final String firstName =
            (childData?['firstName'] ?? '').toString().trim();

        final String name =
            (childData?['name'] ?? '').toString().trim();

        final String gender =
            (childData?['gender'] ?? '').toString().toLowerCase();

        final String avatar =
            (childData?['avatar'] ?? '🌟').toString();

        final String displayName = nickname.isNotEmpty
            ? nickname
            : firstName.isNotEmpty
                ? firstName
                : name.isNotEmpty
                    ? name
                    : 'طفلك';

        final String action =
            gender == 'girl' ? 'أضافت' : 'أضاف';

        return _ParentNotificationCard(
          childName: displayName,
          avatar: avatar,
          action: action,
          isRead: isRead,
          timeText: _formatParentNotificationTime(createdAt),
          onTap: () async {
            if (!isRead) {
              await notification.reference.update({
                'isRead': true,
              });
            }
          },
        );
      },
    );
  }
}

class _ParentNotificationCard extends StatelessWidget {
  final String childName;
  final String avatar;
  final String action;
  final bool isRead;
  final String timeText;
  final VoidCallback onTap;

  const _ParentNotificationCard({
    required this.childName,
    required this.avatar,
    required this.action,
    required this.isRead,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF511281);
    const coral = Color(0xFFFF6969);
    const green = Color(0xFF70A884);

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
                      decoration: const BoxDecoration(
                        color: Color(0xFFE9F4EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: green,
                        size: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'صديق جديد',
                            textAlign: TextAlign.right,
                            style: TextStyle(
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
                      '$childName $action صديقًا جديدًا',
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
                        color: const Color(0xFFF1F8F3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people_alt_rounded,
                            size: 13,
                            color: green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'نشاط الأصدقاء',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: green,
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

class _ParentNotificationLoadingCard extends StatelessWidget {
  const _ParentNotificationLoadingCard();

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

String _formatParentNotificationTime(Timestamp? timestamp) {
  if (timestamp == null) return '';

  final createdAt = timestamp.toDate();
  final now = DateTime.now();
  final difference = now.difference(createdAt);

  if (difference.inSeconds < 60) {
    if (difference.inSeconds <= 5) {
      return 'الآن';
    }

    return 'منذ ${difference.inSeconds} ثانية';
  }

  if (difference.inMinutes < 60) {
    if (difference.inMinutes == 1) {
      return 'منذ دقيقة';
    }

    return 'منذ ${difference.inMinutes} دقائق';
  }

  if (difference.inHours < 24) {
    if (difference.inHours == 1) {
      return 'منذ ساعة';
    }

    return 'منذ ${difference.inHours} ساعات';
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
// =============================================================================
// EMPTY STATE
// =============================================================================

class _ParentNotificationMessageView extends StatelessWidget {
  final String title;
  final String message;

  const _ParentNotificationMessageView({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F0FF),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF511281).withValues(alpha: 0.07),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 120,
                height: 118,
                child: _ParentNotificationBunny(),
              ),

              const SizedBox(height: 9),

              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF511281),
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
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 18,
                  color: Color(0xFF9A73B8),
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

class _ParentNotificationsBackground extends StatelessWidget {
  const _ParentNotificationsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 45,
          right: -55,
          child: _circle(
            145,
            const Color(0xFFDCC9F5).withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          top: 300,
          left: -65,
          child: _circle(
            155,
            const Color(0xFFDDF2E3).withValues(alpha: 0.25),
          ),
        ),
        Positioned(
          top: 575,
          right: -50,
          child: _circle(
            125,
            const Color(0xFFFFDCE3).withValues(alpha: 0.23),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 38,
          child: _circle(
            20,
            const Color(0xFFD5BFE9).withValues(alpha: 0.33),
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
// BUNNY
// =============================================================================

class _ParentNotificationBunny extends StatelessWidget {
  const _ParentNotificationBunny();

  @override
  Widget build(BuildContext context) {
    const face = Color(0xFFFFDCE7);
    const body = Color(0xFFB497C9);

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
              color: const Color(0xFFDDEEE2),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF70A884),
              size: 21,
            ),
          ),
        ),

        // Ears
        const Positioned(
          top: 5,
          right: 30,
          child: _ParentNotificationBunnyEar(color: face),
        ),

        Positioned(
          top: 14,
          left: 21,
          child: Transform.rotate(
            angle: -0.48,
            child: const _ParentNotificationBunnyEar(color: face),
          ),
        ),

        // Body
        Positioned(
          bottom: 3,
          child: Container(
            width: 49,
            height: 32,
            decoration: const BoxDecoration(
              color: body,
              borderRadius: BorderRadius.only(
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
                  child: _ParentNotificationBunnyEye(),
                ),
                const Positioned(
                  top: 22,
                  left: 15,
                  child: _ParentNotificationBunnyEye(),
                ),
                const Positioned(
                  top: 31,
                  left: 29,
                  child: _ParentNotificationBunnyNose(),
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
                  child: _ParentNotificationBunnyCheek(),
                ),
                const Positioned(
                  top: 36,
                  left: 7,
                  child: _ParentNotificationBunnyCheek(),
                ),
              ],
            ),
          ),
        ),

        // Dots
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
        color: const Color(0xFF9A73B8).withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ParentNotificationBunnyEar extends StatelessWidget {
  final Color color;

  const _ParentNotificationBunnyEar({
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
            color: const Color(0xFFFFA1B7).withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _ParentNotificationBunnyEye extends StatelessWidget {
  const _ParentNotificationBunnyEye();

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

class _ParentNotificationBunnyNose extends StatelessWidget {
  const _ParentNotificationBunnyNose();

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

class _ParentNotificationBunnyCheek extends StatelessWidget {
  const _ParentNotificationBunnyCheek();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFFF96AC).withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}