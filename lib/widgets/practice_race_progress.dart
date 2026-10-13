import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/practice_together_service.dart';

class PracticeRaceProgress extends StatefulWidget {
  final String sessionId;
  final String currentChildId;

  final int? secondsRemaining;
  final bool timerRunning;

  const PracticeRaceProgress({
    super.key,
    required this.sessionId,
    required this.currentChildId,
    this.secondsRemaining,
    this.timerRunning = true,
  });

  @override
  State<PracticeRaceProgress> createState() => _PracticeRaceProgressState();
}

class _PracticeRaceProgressState extends State<PracticeRaceProgress> {
  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _green = Color(0xFF70A884);

  final PracticeTogetherService _service = PracticeTogetherService();

  String? _profileKey;

  Future<List<Map<String, dynamic>?>>? _profilesFuture;

  Future<Map<String, dynamic>?> _getProfile(String childId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('child_public_profiles')
        .doc(childId)
        .get();

    return snapshot.data();
  }

  Future<List<Map<String, dynamic>?>> _getProfiles(
    String senderId,
    String receiverId,
  ) {
    final key = '$senderId|$receiverId';

    if (_profileKey != key || _profilesFuture == null) {
      _profileKey = key;

      _profilesFuture = Future.wait([
        _getProfile(senderId),
        _getProfile(receiverId),
      ]);
    }

    return _profilesFuture!;
  }

  String _getName(Map<String, dynamic> profile) {
    final firstName = (profile['firstName'] ?? '').toString().trim();

    final lastName = (profile['lastName'] ?? '').toString().trim();

    final legacyName = (profile['name'] ?? '').toString().trim();

    final fullName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');

    if (fullName.isNotEmpty) {
      return fullName;
    }

    if (legacyName.isNotEmpty) {
      return legacyName;
    }

    return 'صديق';
  }

  Widget _buildTimerChip(int seconds, bool running) {
    final safeSeconds = seconds.clamp(0, 60);

    final minutes = safeSeconds ~/ 60;
    final remainingSeconds = safeSeconds % 60;

    final timerText =
        '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';

    final bool isUrgent = running && safeSeconds <= 15;

    final Color color = !running
        ? _green
        : isUrgent
        ? _coral
        : _purple;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            running ? Icons.timer_outlined : Icons.check_circle_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            running ? timerText : 'تم',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _service.watchSession(sessionId: widget.sessionId),
      builder: (context, sessionSnapshot) {
        if (!sessionSnapshot.hasData) {
          return _buildLoadingCard();
        }

        final document = sessionSnapshot.data!;

        if (!document.exists || document.data() == null) {
          return _buildErrorCard();
        }

        final data = document.data()!;

        final senderId = data['senderId']?.toString() ?? '';

        final receiverId = data['receiverId']?.toString() ?? '';

        final senderProgress = (data['senderProgress'] as num?)?.toInt() ?? 0;

        final receiverProgress =
            (data['receiverProgress'] as num?)?.toInt() ?? 0;

        return FutureBuilder<List<Map<String, dynamic>?>>(
          future: _getProfiles(senderId, receiverId),
          builder: (context, profileSnapshot) {
            if (!profileSnapshot.hasData) {
              return _buildLoadingCard();
            }

            final senderProfile = profileSnapshot.data![0] ?? {};

            final receiverProfile = profileSnapshot.data![1] ?? {};

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _purple.withOpacity(0.08)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x09000000),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_score_rounded,
                            color: _coral,
                            size: 16,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'سباق التحدي',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: _purple,
                            ),
                          ),
                        ],
                      ),

                      if (widget.secondsRemaining != null)
                        _buildTimerChip(
                          widget.secondsRemaining!,
                          widget.timerRunning,
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  _RacePlayerRow(
                    name: _getName(senderProfile),
                    avatar: senderProfile['avatar']?.toString() ?? '🌟',
                    progress: senderProgress,
                    isMe: widget.currentChildId == senderId,
                    trackColor: _coral,
                  ),

                  const SizedBox(height: 5),

                  _RacePlayerRow(
                    name: _getName(receiverProfile),
                    avatar: receiverProfile['avatar']?.toString() ?? '🌟',
                    progress: receiverProgress,
                    isMe: widget.currentChildId == receiverId,
                    trackColor: _green,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Center(child: CircularProgressIndicator(color: _purple)),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Text(
        'تعذّر عرض تقدم التحدي',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Tajawal',
          color: _purple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RacePlayerRow extends StatelessWidget {
  final String name;
  final String avatar;
  final int progress;
  final bool isMe;
  final Color trackColor;

  const _RacePlayerRow({
    required this.name,
    required this.avatar,
    required this.progress,
    required this.isMe,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0, 8);

    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Row(
            children: [
              Text(avatar, style: const TextStyle(fontSize: 20)),

              const SizedBox(width: 4),

              Expanded(
                child: Text(
                  isMe ? '$name • أنت' : name,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF511281),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 5),

        Expanded(
          child: _RaceTrack(
            avatar: avatar,
            progress: safeProgress,
            trackColor: trackColor,
          ),
        ),

        const SizedBox(width: 5),

        SizedBox(
          width: 28,
          child: Text(
            '$safeProgress/8',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: trackColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _RaceTrack extends StatelessWidget {
  final String avatar;
  final int progress;
  final Color trackColor;

  const _RaceTrack({
    required this.avatar,
    required this.progress,
    required this.trackColor,
  });

  @override
  Widget build(BuildContext context) {
    const double runnerSize = 23;
    const double finishSpace = 19;

    final double progressValue = (progress / 8).clamp(0.0, 1.0);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final usableWidth = constraints.maxWidth - runnerSize - finishSpace;

          final runnerPosition = usableWidth * progressValue;

          return SizedBox(
            height: 26,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned(
                  left: runnerSize / 2,
                  right: finishSpace,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF0EBF3),
                      valueColor: AlwaysStoppedAnimation<Color>(trackColor),
                    ),
                  ),
                ),

                const Positioned(
                  right: 0,
                  child: Text('🏁', style: TextStyle(fontSize: 16)),
                ),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  left: runnerPosition,
                  top: 1.5,
                  child: Container(
                    width: runnerSize,
                    height: runnerSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: trackColor, width: 1.5),
                    ),
                    child: Text(avatar, style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
