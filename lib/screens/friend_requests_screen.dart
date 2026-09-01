import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/friend_service.dart';

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

class _FriendRequestsScreenState
    extends State<FriendRequestsScreen> {
  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  final FriendService _friendService = FriendService();

  String? _processingPairId;

  // ─────────────────────────────────────────────
  // Standard App SnackBar
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

        appBar: AppBar(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'طلبات الصداقة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ),

        body: StreamBuilder<
            QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('friend_requests')
              .where(
                'receiverId',
                isEqualTo: widget.childId,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _purple,
                ),
              );
            }

            if (snapshot.hasError) {
              return const _MessageView(
                icon: Icons.error_outline_rounded,
                title: 'تعذّر تحميل الطلبات',
                message: 'حاول مرة أخرى بعد قليل',
              );
            }

            final requests =
                snapshot.data?.docs ?? [];

            if (requests.isEmpty) {
              return const _MessageView(
                icon: Icons.people_outline_rounded,
                title: 'لا توجد طلبات جديدة',
                message:
                    'ستظهر طلبات أصدقائك هنا',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: requests.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final request = requests[index];
                final data = request.data();

                final senderId =
                    data['senderId']?.toString() ?? '';

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
                      return const SizedBox.shrink();
                    }

                    final String name =
                        profile['name']?.toString() ??
                            'صديق جديد';

                    final String avatar =
                        profile['avatar']?.toString() ??
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
            );
          },
        ),
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: purple.withOpacity(0.08),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      purple.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  avatar,
                  style: const TextStyle(
                    fontSize: 34,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.bold,
                        color: purple,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'يريد أن يكون صديقك',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (processing)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: CircularProgressIndicator(
                color: purple,
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
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
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    child: const Text(
                      'قبول',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor: purple,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 12,
                      ),
                      side: BorderSide(
                        color: purple.withOpacity(
                          0.25,
                        ),
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    child: const Text(
                      'رفض',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontFamily: 'Tajawal',
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

class _RequestLoadingCard extends StatelessWidget {
  const _RequestLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF511281),
        ),
      ),
    );
  }
}

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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF511281)
                    .withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 45,
                color:
                    const Color(0xFF511281),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color:
                    Color(0xFF511281),
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }
}