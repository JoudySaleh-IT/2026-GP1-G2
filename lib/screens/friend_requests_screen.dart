import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/friend_service.dart';
import 'style_constants.dart';

class FriendRequestsScreen extends StatefulWidget {
  final String childId;

  const FriendRequestsScreen({
    super.key,
    required this.childId,
  });

  @override
  State<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  final FriendService _friendService = FriendService();

  String? _processingPairId;

  // ─────────────────────────────────────────────
  // Standard App SnackBar
  // بدون تغيير
  // ─────────────────────────────────────────────
  void _showAppSnackBar(
    String message, {
    Color backgroundColor = _purple,
  }) {
    final messenger = ScaffoldMessenger.of(context);

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
  // Get Sender Profile
  // بدون تغيير
  // ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> _getSenderProfile(
    String senderId,
  ) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('child_public_profiles')
        .doc(senderId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot.data();
  }

  // ─────────────────────────────────────────────
  // Accept
  // بدون تغيير
  // ─────────────────────────────────────────────
  Future<void> _acceptRequest(String pairId) async {
    setState(() {
      _processingPairId = pairId;
    });

    try {
      await _friendService.acceptFriendRequest(
        currentChildId: widget.childId,
        pairId: pairId,
      );

      if (!mounted) return;

      _showAppSnackBar(
        'أصبحتم أصدقاء الآن! 🎉',
      );
    } catch (e) {
      if (!mounted) return;

      _showAppSnackBar(
        'تعذّر قبول الطلب. حاول مرة أخرى.',
        backgroundColor: _coral,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingPairId = null;
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // Decline
  // بدون تغيير
  // ─────────────────────────────────────────────
  Future<void> _declineRequest(String pairId) async {
    setState(() {
      _processingPairId = pairId;
    });

    try {
      await _friendService.declineFriendRequest(
        currentChildId: widget.childId,
        pairId: pairId,
      );

      if (!mounted) return;

      _showAppSnackBar(
        'تم رفض طلب الصداقة',
      );
    } catch (e) {
      if (!mounted) return;

      _showAppSnackBar(
        'تعذّر رفض الطلب. حاول مرة أخرى.',
        backgroundColor: _coral,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingPairId = null;
        });
      }
    }
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
            // UNIFIED HEADER
            // ===============================================================
            FaseehStyle.buildLargeHeader(
              context: context,
              title: 'طلبات الصداقة',
              subtitle: 'شاهد من يريد أن يصبح صديقك',

              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // زر الرجوع
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

                  // أيقونة الصفحة
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(
                        Icons.notifications_active_rounded,
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
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('friend_requests')
                    .where(
                      'receiverId',
                      isEqualTo: widget.childId,
                    )
                    .snapshots(),
                builder: (context, snapshot) {
                  // =========================================================
                  // Loading
                  // =========================================================
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Stack(
                      children: [
                        Positioned.fill(
                          child: _RequestsBackground(),
                        ),
                        Center(
                          child: CircularProgressIndicator(
                            color: _purple,
                          ),
                        ),
                      ],
                    );
                  }

                  // =========================================================
                  // Error
                  // =========================================================
                  if (snapshot.hasError) {
                    return const Stack(
                      children: [
                        Positioned.fill(
                          child: _RequestsBackground(),
                        ),
                        _MessageView(
                          icon: Icons.error_outline_rounded,
                          title: 'تعذّر تحميل الطلبات',
                          message: 'حاول مرة أخرى بعد قليل',
                        ),
                      ],
                    );
                  }

                  final requests =
                      snapshot.data?.docs ?? [];

                  // =========================================================
                  // Empty
                  // =========================================================
                  if (requests.isEmpty) {
                    return const Stack(
                      children: [
                        Positioned.fill(
                          child: _RequestsBackground(),
                        ),
                        _MessageView(
                          icon: Icons.people_outline_rounded,
                          title: 'لا توجد طلبات جديدة',
                          message:
                              'ستظهر طلبات أصدقائك هنا',
                        ),
                      ],
                    );
                  }

                  // =========================================================
                  // Requests
                  // =========================================================
                  return Stack(
                    children: [
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: _RequestsBackground(),
                        ),
                      ),

                      ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          18,
                          16,
                          18,
                          30,
                        ),

                        // +1 للكارد الترحيبي فقط
                        itemCount: requests.length + 1,

                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 11),

                        itemBuilder: (context, index) {
                          // =================================================
                          // Intro Card
                          // =================================================
                          if (index == 0) {
                            return _RequestsWelcomeCard(
                              requestCount:
                                  requests.length,
                            );
                          }

                          final request =
                              requests[index - 1];

                          final data =
                              request.data();

                          final senderId =
                              data['senderId']
                                      ?.toString() ??
                                  '';

                          return FutureBuilder<
                              Map<String, dynamic>?>(
                            future: _getSenderProfile(
                              senderId,
                            ),
                            builder: (
                              context,
                              profileSnapshot,
                            ) {
                              if (profileSnapshot
                                      .connectionState ==
                                  ConnectionState.waiting) {
                                return const _RequestLoadingCard();
                              }

                              final profile =
                                  profileSnapshot.data;

                              if (profile == null) {
                                return const SizedBox
                                    .shrink();
                              }

                              final String name =
                                  profile['name']
                                          ?.toString() ??
                                      'صديق جديد';

                              final String avatar =
                                  profile['avatar']
                                          ?.toString() ??
                                      '🌟';

                              final bool processing =
                                  _processingPairId ==
                                      request.id;

                              return _FriendRequestCard(
                                name: name,
                                avatar: avatar,
                                processing: processing,
                                onAccept: () =>
                                    _acceptRequest(
                                  request.id,
                                ),
                                onDecline: () =>
                                    _declineRequest(
                                  request.id,
                                ),
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
// WELCOME CARD
// =============================================================================
class _RequestsWelcomeCard extends StatelessWidget {
  final int requestCount;

  const _RequestsWelcomeCard({
    required this.requestCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 132,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: const Color(0xFF511281)
              .withOpacity(0.07),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          children: [
            // Purple decoration
            Positioned(
              right: -55,
              top: -65,
              child: Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5)
                      .withOpacity(0.28),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Pink decoration
            Positioned(
              left: 30,
              bottom: -55,
              child: Container(
                width: 135,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9E2)
                      .withOpacity(0.38),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              child: Row(
                children: [
                  // Bunny receiving request
                  const SizedBox(
                    width: 100,
                    height: 108,
                    child: _RequestBunny(),
                  ),

                  const SizedBox(width: 11),

                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'لديك أصدقاء جدد!',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 17,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                Color(0xFF511281),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'اختر من تريد إضافته إلى قائمة أصدقائك',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            height: 1.45,
                            color:
                                Color(0xFF777777),
                          ),
                        ),

                        const SizedBox(height: 9),

                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white
                                .withOpacity(0.72),
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Text(
                            '$requestCount طلب صداقة',
                            style:
                                const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  Color(0xFF8B55B3),
                            ),
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
    );
  }
}

// =============================================================================
// FRIEND REQUEST CARD
// =============================================================================
class _FriendRequestCard extends StatelessWidget {
  final String name;
  final String avatar;
  final bool processing;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _FriendRequestCard({
    required this.name,
    required this.avatar,
    required this.processing,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF511281);
    const coral = Color(0xFFFF6969);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: purple.withOpacity(0.07),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ===============================================================
          // Friend info
          // ===============================================================
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Avatar
                  Container(
                    width: 62,
                    height: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFF3EBFA,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: purple
                            .withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      avatar,
                      style: const TextStyle(
                        fontSize: 34,
                      ),
                    ),
                  ),

                  // Small heart
                  Positioned(
                    left: -3,
                    bottom: -2,
                    child: Container(
                      width: 23,
                      height: 23,
                      decoration:
                          const BoxDecoration(
                        color:
                            Color(0xFFFFE7EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color:
                            Color(0xFFFF7890),
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
                    Text(
                      name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color: purple,
                        fontFamily: 'Tajawal',
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'يريد أن يصبح صديقك',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11.5,
                        color:
                            Color(0xFF808080),
                        fontFamily: 'Tajawal',
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFF1F8F3,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            Icons
                                .people_alt_rounded,
                            size: 13,
                            color: Color(
                              0xFF70A884,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'طلب صداقة',
                            style: TextStyle(
                              fontFamily:
                                  'Tajawal',
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w600,
                              color: Color(
                                0xFF66997A,
                              ),
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

          const SizedBox(height: 14),

          // ===============================================================
          // Processing
          // ===============================================================
          if (processing)
            Container(
              height: 46,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFF7F1FB),
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
              ),
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: purple,
                ),
              ),
            )
          else
            // =============================================================
            // Accept / Decline
            // نفس callbacks
            // =============================================================
            Row(
              children: [
                // Accept
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(
                      Icons.favorite_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'قبول',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor: coral,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      shape:
                          const StadiumBorder(),
                    ),
                  ),
                ),

                const SizedBox(width: 9),

                // Decline
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          const Color(
                        0xFF817987,
                      ),
                      backgroundColor:
                          const Color(
                        0xFFFAF8FB,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      side: BorderSide(
                        color: purple
                            .withOpacity(0.10),
                      ),
                      shape:
                          const StadiumBorder(),
                    ),
                    child: const Text(
                      'رفض',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// LOADING CARD
// =============================================================================
class _RequestLoadingCard extends StatelessWidget {
  const _RequestLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
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
// EMPTY / ERROR VIEW
// =============================================================================
class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final bool isError =
        icon == Icons.error_outline_rounded;

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
            borderRadius:
                BorderRadius.circular(28),
            border: Border.all(
              color: isError
                  ? const Color(0xFFFF6969)
                      .withOpacity(0.08)
                  : const Color(0xFF511281)
                      .withOpacity(0.07),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 120,
                height: 118,
                child: isError
                    ? const _ConcernedBunny()
                    : const _WaitingRequestBunny(),
              ),

              const SizedBox(height: 9),

              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isError
                      ? const Color(
                          0xFFD7685B,
                        )
                      : const Color(
                          0xFF511281,
                        ),
                  fontFamily: 'Tajawal',
                ),
              ),

              const SizedBox(height: 6),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xFF858085),
                  fontFamily: 'Tajawal',
                ),
              ),

              const SizedBox(height: 13),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.65),
                  borderRadius:
                      BorderRadius.circular(
                    18,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isError
                      ? const Color(
                          0xFFE08073,
                        )
                      : const Color(
                          0xFF9A73B8,
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

// =============================================================================
// BACKGROUND
// =============================================================================
class _RequestsBackground extends StatelessWidget {
  const _RequestsBackground();

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
                .withOpacity(0.18),
          ),
        ),

        Positioned(
          top: 300,
          left: -65,
          child: _circle(
            155,
            const Color(0xFFDDF2E3)
                .withOpacity(0.25),
          ),
        ),

        Positioned(
          top: 575,
          right: -50,
          child: _circle(
            125,
            const Color(0xFFFFDCE3)
                .withOpacity(0.23),
          ),
        ),

        Positioned(
          bottom: 40,
          left: 38,
          child: _circle(
            20,
            const Color(0xFFD5BFE9)
                .withOpacity(0.33),
          ),
        ),
      ],
    );
  }

  Widget _circle(
    double size,
    Color color,
  ) {
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
// HAPPY REQUEST BUNNY
// مستلم طلب صداقة
// =============================================================================
class _RequestBunny extends StatelessWidget {
  const _RequestBunny();

  @override
  Widget build(BuildContext context) {
    const face = Color(0xFFFFDCE7);
    const body = Color(0xFF8B55B3);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Envelope
        Positioned(
          left: 0,
          bottom: 8,
          child: Transform.rotate(
            angle: -0.10,
            child: Container(
              width: 38,
              height: 29,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color:
                      const Color(0xFFDCC9E8),
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.favorite_rounded,
                  size: 14,
                  color:
                      Color(0xFFFF7890),
                ),
              ),
            ),
          ),
        ),

        // Heart bubble
        Positioned(
          top: 8,
          left: 4,
          child: Container(
            width: 25,
            height: 25,
            decoration:
                const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 14,
              color: Color(0xFFFF7890),
            ),
          ),
        ),

        // Ears
        Positioned(
          top: 0,
          right: 23,
          child: _BunnyEar(
            color: face,
          ),
        ),

        Positioned(
          top: 0,
          left: 23,
          child: _BunnyEar(
            color: face,
          ),
        ),

        // Body
        Positioned(
          bottom: 0,
          child: Container(
            width: 46,
            height: 29,
            decoration:
                const BoxDecoration(
              color: body,
              borderRadius:
                  BorderRadius.only(
                topLeft:
                    Radius.circular(24),
                topRight:
                    Radius.circular(24),
                bottomLeft:
                    Radius.circular(11),
                bottomRight:
                    Radius.circular(11),
              ),
            ),
          ),
        ),

        // Head
        Positioned(
          top: 27,
          child: Container(
            width: 59,
            height: 55,
            decoration: BoxDecoration(
              color: face,
              borderRadius:
                  BorderRadius.circular(
                28,
              ),
            ),
            child: const Stack(
              children: [
                Positioned(
                  top: 20,
                  right: 14,
                  child: _BunnyEye(),
                ),
                Positioned(
                  top: 20,
                  left: 14,
                  child: _BunnyEye(),
                ),
                Positioned(
                  top: 28,
                  left: 26,
                  child: _BunnyNose(),
                ),
                Positioned(
                  top: 34,
                  left: 22,
                  child: _BunnySmile(),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 60,
          right: 28,
          child: _BunnyCheek(),
        ),

        Positioned(
          top: 60,
          left: 28,
          child: _BunnyCheek(),
        ),
      ],
    );
  }
}

// =============================================================================
// WAITING BUNNY
// لا توجد طلبات - ينتظر بهدوء
// =============================================================================
class _WaitingRequestBunny extends StatelessWidget {
  const _WaitingRequestBunny();

  @override
  Widget build(BuildContext context) {
    const face = Color(0xFFFFDCE7);
    const body = Color(0xFFB497C9);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Mail box
        Positioned(
          right: 2,
          bottom: 4,
          child: Container(
            width: 38,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(
                0xFFDDEEE2,
              ),
              borderRadius:
                  BorderRadius.circular(
                10,
              ),
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              color: Color(0xFF70A884),
              size: 20,
            ),
          ),
        ),

        // One normal ear
        Positioned(
          top: 5,
          right: 30,
          child: _BunnyEar(
            color: face,
          ),
        ),

        // One tilted ear
        Positioned(
          top: 14,
          left: 21,
          child: Transform.rotate(
            angle: -0.48,
            child: _BunnyEar(
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
            decoration:
                const BoxDecoration(
              color: body,
              borderRadius:
                  BorderRadius.only(
                topLeft:
                    Radius.circular(24),
                topRight:
                    Radius.circular(24),
                bottomLeft:
                    Radius.circular(12),
                bottomRight:
                    Radius.circular(12),
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
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),
            child: Stack(
              children: [
                const Positioned(
                  top: 22,
                  right: 15,
                  child: _BunnyEye(),
                ),

                const Positioned(
                  top: 22,
                  left: 15,
                  child: _BunnyEye(),
                ),

                const Positioned(
                  top: 31,
                  left: 29,
                  child: _BunnyNose(),
                ),

                Positioned(
                  top: 39,
                  left: 25,
                  child: Container(
                    width: 15,
                    height: 6,
                    decoration:
                        const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(
                            0xFF4D3855,
                          ),
                          width: 1.3,
                        ),
                      ),
                      borderRadius:
                          BorderRadius.only(
                        bottomLeft:
                            Radius.circular(8),
                        bottomRight:
                            Radius.circular(8),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 36,
                  right: 7,
                  child: _BunnyCheek(),
                ),

                Positioned(
                  top: 36,
                  left: 7,
                  child: _BunnyCheek(),
                ),
              ],
            ),
          ),
        ),

        // Tiny waiting dots
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
        color: const Color(
          0xFF9A73B8,
        ).withOpacity(0.45),
        shape: BoxShape.circle,
      ),
    );
  }
}

// =============================================================================
// CONCERNED BUNNY
// للخطأ فقط - قلق وليس معصب
// =============================================================================
class _ConcernedBunny extends StatelessWidget {
  const _ConcernedBunny();

  @override
  Widget build(BuildContext context) {
    const face = Color(0xFFFFDCE7);
    const body = Color(0xFFD5A1A1);
    const details = Color(0xFF5D4B62);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Ears slightly tilted
        Positioned(
          top: 7,
          right: 29,
          child: Transform.rotate(
            angle: 0.18,
            child: _BunnyEar(
              color: face,
            ),
          ),
        ),

        Positioned(
          top: 7,
          left: 29,
          child: Transform.rotate(
            angle: -0.18,
            child: _BunnyEar(
              color: face,
            ),
          ),
        ),

        // Body
        Positioned(
          bottom: 3,
          child: Container(
            width: 49,
            height: 31,
            decoration:
                const BoxDecoration(
              color: body,
              borderRadius:
                  BorderRadius.only(
                topLeft:
                    Radius.circular(24),
                topRight:
                    Radius.circular(24),
                bottomLeft:
                    Radius.circular(12),
                bottomRight:
                    Radius.circular(12),
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
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 24,
                  right: 15,
                  child: Container(
                    width: 8,
                    height: 5,
                    decoration:
                        const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: details,
                          width: 1.7,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 24,
                  left: 15,
                  child: Container(
                    width: 8,
                    height: 5,
                    decoration:
                        const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: details,
                          width: 1.7,
                        ),
                      ),
                    ),
                  ),
                ),

                const Positioned(
                  top: 32,
                  left: 29,
                  child: _BunnyNose(),
                ),

                Positioned(
                  top: 41,
                  left: 29,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: details,
                        width: 1.2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 37,
                  right: 8,
                  child: _BunnyCheek(),
                ),

                Positioned(
                  top: 37,
                  left: 8,
                  child: _BunnyCheek(),
                ),
              ],
            ),
          ),
        ),

        // Little alert bubble
        Positioned(
          top: 11,
          left: 5,
          child: Container(
            width: 27,
            height: 27,
            decoration:
                const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Color(
                0xFFE18478,
              ),
              size: 17,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SMALL BUNNY PARTS
// =============================================================================
class _BunnyEar extends StatelessWidget {
  final Color color;

  const _BunnyEar({
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 19,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Center(
        child: Container(
          width: 7,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(
              0xFFFFA1B7,
            ).withOpacity(0.52),
            borderRadius:
                BorderRadius.circular(
              12,
            ),
          ),
        ),
      ),
    );
  }
}

class _BunnyEye extends StatelessWidget {
  const _BunnyEye();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 7,
      decoration:
          const BoxDecoration(
        color: Color(0xFF4D3855),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BunnyNose extends StatelessWidget {
  const _BunnyNose();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 5,
      decoration:
          const BoxDecoration(
        color: Color(0xFFFF7890),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BunnySmile extends StatelessWidget {
  const _BunnySmile();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 7,
      decoration:
          const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF4D3855),
            width: 1.4,
          ),
        ),
        borderRadius:
            BorderRadius.only(
          bottomLeft:
              Radius.circular(10),
          bottomRight:
              Radius.circular(10),
        ),
      ),
    );
  }
}

class _BunnyCheek extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(
          0xFFFF96AC,
        ).withOpacity(0.45),
        borderRadius:
            BorderRadius.circular(
          10,
        ),
      ),
    );
  }
}