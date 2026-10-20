import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/practice_together_service.dart';
import 'style_constants.dart';

class PracticeTogetherResultScreen extends StatefulWidget {
  final String sessionId;
  final String childId;

  const PracticeTogetherResultScreen({
    super.key,
    required this.sessionId,
    required this.childId,
  });

  @override
  State<PracticeTogetherResultScreen> createState() =>
      _PracticeTogetherResultScreenState();
}

class _PracticeTogetherResultScreenState
    extends State<PracticeTogetherResultScreen> {
  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);
  static const Color _green = Color(0xFF70A884);
  static const Color _gold = Color(0xFFE5A52F);

  final PracticeTogetherService _service = PracticeTogetherService();

  String? _profileKey;
  Future<List<Map<String, dynamic>?>>? _profilesFuture;

  // ---------------------------------------------------------------------------
  // Profiles
  // ---------------------------------------------------------------------------

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
    final String firstName = (profile['firstName'] ?? '').toString().trim();

    final String lastName = (profile['lastName'] ?? '').toString().trim();

    final String legacyName = (profile['name'] ?? '').toString().trim();

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

  String _getAvatar(Map<String, dynamic> profile) {
    final value = profile['avatar']?.toString().trim();

    if (value == null || value.isEmpty) {
      return '🌟';
    }

    return value;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  int _getInt(Map<String, dynamic> data, String key) {
    return (data[key] as num?)?.toInt() ?? 0;
  }

  String _formatTime(int milliseconds) {
    final int centiseconds = milliseconds ~/ 10;

    final int minutes = centiseconds ~/ 6000;

    final int seconds = (centiseconds % 6000) ~/ 100;

    final int hundredths = centiseconds % 100;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${hundredths.toString().padLeft(2, '0')}';
  }

  int _calculatePotentialPoints({
    required String exerciseType,
    required int correctCount,
    required int averageScore,
  }) {
    if (exerciseType == 'speaking') {
      return averageScore * 10;
    }

    return correctCount * 50;
  }

  void _goHome() {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/child/home',
      (route) => false,
      arguments: {'childId': widget.childId},
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: _background,
          body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _service.watchSession(sessionId: widget.sessionId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _purple),
                );
              }

              final document = snapshot.data!;

              if (!document.exists || document.data() == null) {
                return _buildError('تعذّر العثور على نتيجة التحدي');
              }

              final data = document.data()!;

              final String senderId = data['senderId']?.toString() ?? '';

              final String receiverId = data['receiverId']?.toString() ?? '';

              if (widget.childId != senderId && widget.childId != receiverId) {
                return _buildError('لا يمكنك عرض نتيجة هذا التحدي');
              }

              return FutureBuilder<List<Map<String, dynamic>?>>(
                future: _getProfiles(senderId, receiverId),
                builder: (context, profileSnapshot) {
                  if (!profileSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: _purple),
                    );
                  }

                  final senderProfile = profileSnapshot.data![0] ?? {};

                  final receiverProfile = profileSnapshot.data![1] ?? {};

                  final String status = data['status']?.toString() ?? '';

                  if (status != 'completed') {
                    return _buildWaitingView(
                      data: data,
                      senderProfile: senderProfile,
                      receiverProfile: receiverProfile,
                    );
                  }

                  return _buildCompletedView(
                    data: data,
                    senderProfile: senderProfile,
                    receiverProfile: receiverProfile,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Waiting for second child
  // ---------------------------------------------------------------------------

  Widget _buildWaitingView({
    required Map<String, dynamic> data,
    required Map<String, dynamic> senderProfile,
    required Map<String, dynamic> receiverProfile,
  }) {
    final String senderId = data['senderId']?.toString() ?? '';

    final bool currentIsSender = widget.childId == senderId;

    final bool senderFinished = data['senderFinished'] == true;

    final bool receiverFinished = data['receiverFinished'] == true;

    return Column(
      children: [
        FaseehStyle.buildLargeHeader(
          context: context,
          title: 'أحسنت! أنهيت التحدي 🏁',
          subtitle: 'بانتظار صديقك لإنهاء التحدي',
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
        ),

        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                children: [
                  const Text('✨', style: TextStyle(fontSize: 52)),

                  const SizedBox(height: 14),

                  const Text(
                    'وصلت إلى خط النهاية!',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: _purple,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'ستظهر النتيجة هنا تلقائيًا عندما ينتهي صديقك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 14,
                      color: Color(0xFF777177),
                    ),
                  ),

                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Expanded(
                        child: _WaitingPlayerCard(
                          profile: senderProfile,
                          name: _getName(senderProfile),
                          avatar: _getAvatar(senderProfile),
                          finished: senderFinished,
                          isMe: currentIsSender,
                        ),
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'VS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _coral,
                          ),
                        ),
                      ),

                      Expanded(
                        child: _WaitingPlayerCard(
                          profile: receiverProfile,
                          name: _getName(receiverProfile),
                          avatar: _getAvatar(receiverProfile),
                          finished: receiverFinished,
                          isMe: !currentIsSender,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const CircularProgressIndicator(color: _purple),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Completed result
  // ---------------------------------------------------------------------------

  Widget _buildCompletedView({
    required Map<String, dynamic> data,
    required Map<String, dynamic> senderProfile,
    required Map<String, dynamic> receiverProfile,
  }) {
    final String senderId = data['senderId']?.toString() ?? '';

    final String receiverId = data['receiverId']?.toString() ?? '';

    final String result = data['result']?.toString() ?? '';

    final String winnerId = data['winnerId']?.toString() ?? '';

    final bool isTie = result == 'tie';

    final bool currentWon = !isTie && winnerId == widget.childId;

    final bool currentIsSender = widget.childId == senderId;

    final String exerciseType = data['exerciseType']?.toString() ?? 'listening';

    final int senderCorrect = _getInt(data, 'senderCorrectCount');

    final int receiverCorrect = _getInt(data, 'receiverCorrectCount');

    final int senderTime = _getInt(data, 'senderResponseTimeMs');

    final int receiverTime = _getInt(data, 'receiverResponseTimeMs');

    final int senderTimeouts = _getInt(data, 'senderTimedOutCount');

    final int receiverTimeouts = _getInt(data, 'receiverTimedOutCount');

    final int senderAverage = _getInt(data, 'senderAverageScore');

    final int receiverAverage = _getInt(data, 'receiverAverageScore');

    final int myCorrect = currentIsSender ? senderCorrect : receiverCorrect;

    final int friendCorrect = currentIsSender ? receiverCorrect : senderCorrect;

    final int myTime = currentIsSender ? senderTime : receiverTime;

    final int friendTime = currentIsSender ? receiverTime : senderTime;

    final int myTimeouts = currentIsSender ? senderTimeouts : receiverTimeouts;

    final int friendTimeouts = currentIsSender
        ? receiverTimeouts
        : senderTimeouts;

    final int myAverage = currentIsSender ? senderAverage : receiverAverage;

    final int friendAverage = currentIsSender ? receiverAverage : senderAverage;

    final myProfile = currentIsSender ? senderProfile : receiverProfile;

    final friendProfile = currentIsSender ? receiverProfile : senderProfile;

    final int potentialPoints = _calculatePotentialPoints(
      exerciseType: exerciseType,
      correctCount: myCorrect,
      averageScore: myAverage,
    );

    String title;
    String subtitle;

    if (isTie) {
      title = 'رائع! تعادلتما 🤝';
      subtitle = 'كان أداؤكما متقاربًا جدًا';
    } else if (currentWon) {
      title = 'أحسنت! لقد فزت بالتحدي ⭐';
      subtitle = 'أداء رائع!';
    } else {
      title = 'أحسنت! حاول مرة أخرى 💪';
      subtitle = 'صديقك أنهى التحدي بنتيجة أفضل';
    }

    return Column(
      children: [
        FaseehStyle.buildLargeHeader(
          context: context,
          title: title,
          subtitle: subtitle,
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
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: Column(
              children: [
                _buildPodium(
                  senderId: senderId,
                  receiverId: receiverId,
                  winnerId: winnerId,
                  isTie: isTie,
                  senderProfile: senderProfile,
                  receiverProfile: receiverProfile,
                  senderCorrect: senderCorrect,
                  receiverCorrect: receiverCorrect,
                ),

                const SizedBox(height: 18),

                _buildComparisonCard(
                  exerciseType: exerciseType,
                  myProfile: myProfile,
                  friendProfile: friendProfile,
                  myCorrect: myCorrect,
                  friendCorrect: friendCorrect,
                  myTime: myTime,
                  friendTime: friendTime,
                  myTimeouts: myTimeouts,
                  friendTimeouts: friendTimeouts,
                  myAverage: myAverage,
                  friendAverage: friendAverage,
                ),

                const SizedBox(height: 18),

                _buildOutcomeCard(
                  isTie: isTie,
                  currentWon: currentWon,
                  myCorrect: myCorrect,
                  friendCorrect: friendCorrect,
                ),

                const SizedBox(height: 14),

                _buildPointsCard(
                  isTie: isTie,
                  currentWon: currentWon,
                  potentialPoints: potentialPoints,
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _goHome,
                    icon: const Icon(Icons.home_rounded),
                    label: const Text(
                      'العودة للرئيسية',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _purple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
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

  // ---------------------------------------------------------------------------
  // Podium
  // ---------------------------------------------------------------------------

  Widget _buildPodium({
    required String senderId,
    required String receiverId,
    required String winnerId,
    required bool isTie,
    required Map<String, dynamic> senderProfile,
    required Map<String, dynamic> receiverProfile,
    required int senderCorrect,
    required int receiverCorrect,
  }) {
    if (isTie) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _PodiumPlayer(
                name: _getName(senderProfile),
                avatar: _getAvatar(senderProfile),
                score: senderCorrect,
                label: 'تعادل',
                podiumHeight: 105,
                isMe: widget.childId == senderId,
                isWinner: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _PodiumPlayer(
                name: _getName(receiverProfile),
                avatar: _getAvatar(receiverProfile),
                score: receiverCorrect,
                label: 'تعادل',
                podiumHeight: 105,
                isMe: widget.childId == receiverId,
                isWinner: true,
              ),
            ),
          ],
        ),
      );
    }

    final bool senderWon = winnerId == senderId;

    final winnerProfile = senderWon ? senderProfile : receiverProfile;

    final secondProfile = senderWon ? receiverProfile : senderProfile;

    final int winnerScore = senderWon ? senderCorrect : receiverCorrect;

    final int secondScore = senderWon ? receiverCorrect : senderCorrect;

    final String winnerChildId = senderWon ? senderId : receiverId;

    final String secondChildId = senderWon ? receiverId : senderId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: _PodiumPlayer(
              name: _getName(secondProfile),
              avatar: _getAvatar(secondProfile),
              score: secondScore,
              label: 'المركز الثاني',
              podiumHeight: 90,
              isMe: widget.childId == secondChildId,
              isWinner: false,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: _PodiumPlayer(
              name: _getName(winnerProfile),
              avatar: _getAvatar(winnerProfile),
              score: winnerScore,
              label: 'المركز الأول',
              podiumHeight: 130,
              isMe: widget.childId == winnerChildId,
              isWinner: true,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Comparison
  // ---------------------------------------------------------------------------

  Widget _buildComparisonCard({
    required String exerciseType,
    required Map<String, dynamic> myProfile,
    required Map<String, dynamic> friendProfile,
    required int myCorrect,
    required int friendCorrect,
    required int myTime,
    required int friendTime,
    required int myTimeouts,
    required int friendTimeouts,
    required int myAverage,
    required int friendAverage,
  }) {
    final String correctLabel = exerciseType == 'speaking'
        ? 'نطق صحيح'
        : 'إجابات صحيحة';

    final String wrongLabel = exerciseType == 'speaking'
        ? 'يحتاج تحسين'
        : 'إجابات غير صحيحة';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const Text(
            'ملخص التحدي',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _purple,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              const SizedBox(width: 105),

              Expanded(
                child: Column(
                  children: [
                    Text(
                      _getAvatar(myProfile),
                      style: const TextStyle(fontSize: 30),
                    ),
                    const Text(
                      'أنت',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        color: _purple,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    Text(
                      _getAvatar(friendProfile),
                      style: const TextStyle(fontSize: 30),
                    ),
                    Text(
                      _getName(friendProfile),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          _SummaryRow(
            label: correctLabel,
            myValue: '$myCorrect/8',
            friendValue: '$friendCorrect/8',
          ),

          _SummaryRow(
            label: wrongLabel,
            myValue: '${8 - myCorrect}',
            friendValue: '${8 - friendCorrect}',
          ),

          _SummaryRow(
            label: 'انتهى الوقت',
            myValue: '$myTimeouts',
            friendValue: '$friendTimeouts',
          ),

          _SummaryRow(
            label: 'الوقت',
            myValue: _formatTime(myTime),
            friendValue: _formatTime(friendTime),
          ),

          if (exerciseType == 'speaking')
            _SummaryRow(
              label: 'متوسط النطق',
              myValue: '$myAverage%',
              friendValue: '$friendAverage%',
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Outcome
  // ---------------------------------------------------------------------------

  Widget _buildOutcomeCard({
    required bool isTie,
    required bool currentWon,
    required int myCorrect,
    required int friendCorrect,
  }) {
    IconData icon;
    Color color;
    String title;
    String message;

    if (isTie) {
      icon = Icons.handshake_rounded;
      color = _purple;
      title = 'تعادلتما في التحدي';

      message = 'كان أداؤكما متقاربًا جدًا.';
    } else if (currentWon) {
      icon = Icons.emoji_events_rounded;
      color = _green;
      title = 'أداء رائع!';

      message = myCorrect > friendCorrect
          ? 'حققت عددًا أكبر من الإجابات الصحيحة.'
          : 'تعادلتما في الإجابات الصحيحة، وكان وقتك أقل.';
    } else {
      icon = Icons.auto_awesome_rounded;
      color = _coral;
      title = 'فرصة جديدة للتحسن';

      message = friendCorrect > myCorrect
          ? 'حقق صديقك عددًا أكبر من الإجابات الصحيحة.'
          : 'تعادلتما في الإجابات الصحيحة، وكان وقت صديقك أقل.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Points UI only
  // ---------------------------------------------------------------------------

  Widget _buildPointsCard({
    required bool isTie,
    required bool currentWon,
    required int potentialPoints,
  }) {
    String value;
    String subtitle;
    bool discarded = false;

    if (isTie) {
      value = '—';
      subtitle = 'لا يوجد فائز في حالة التعادل';
    } else if (currentWon) {
      value = '+$potentialPoints نقطة';
      subtitle = 'نقاط هذه المحاولة';
    } else {
      value = '$potentialPoints نقطة';
      subtitle = 'لم تُحتسب نقاط هذه المحاولة';
      discarded = true;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF4C466).withOpacity(0.28)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFFFE8A6),
            child: Icon(Icons.star_rounded, color: _gold),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _gold,
                    decoration: discarded ? TextDecoration.lineThrough : null,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11.5,
                    color: Color(0xFF777777),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.94),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _purple.withOpacity(0.08)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _coral),

            const SizedBox(height: 12),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 16,
                color: _purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Podium Player
// =============================================================================

class _PodiumPlayer extends StatelessWidget {
  final String name;
  final String avatar;
  final int score;
  final String label;
  final double podiumHeight;
  final bool isMe;
  final bool isWinner;

  const _PodiumPlayer({
    required this.name,
    required this.avatar,
    required this.score,
    required this.label,
    required this.podiumHeight,
    required this.isMe,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF511281);
    const gold = Color(0xFFE5A52F);

    final Color podiumColor = isWinner
        ? const Color(0xFFFFE6A3)
        : const Color(0xFFE8E3EC);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isWinner) const Text('👑', style: TextStyle(fontSize: 27)),

        Text(avatar, style: const TextStyle(fontSize: 53)),

        const SizedBox(height: 5),

        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: purple,
          ),
        ),

        if (isMe)
          const Text(
            'أنت',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10.5,
              color: Color(0xFF777777),
            ),
          ),

        const SizedBox(height: 5),

        Text(
          '$score / 8',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: purple,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          height: podiumHeight,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isWinner ? '🥇' : '🥈',
                style: const TextStyle(fontSize: 30),
              ),

              const SizedBox(height: 4),

              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isWinner ? gold : purple,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Waiting Player
// =============================================================================

class _WaitingPlayerCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String name;
  final String avatar;
  final bool finished;
  final bool isMe;

  const _WaitingPlayerCard({
    required this.profile,
    required this.name,
    required this.avatar,
    required this.finished,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF511281);
    const green = Color(0xFF70A884);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: finished ? const Color(0xFFF0F8F2) : const Color(0xFFF5F2F6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(avatar, style: const TextStyle(fontSize: 50)),

          const SizedBox(height: 8),

          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              color: purple,
            ),
          ),

          if (isMe)
            const Text(
              'أنت',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: Color(0xFF888888),
              ),
            ),

          const SizedBox(height: 8),

          Text(
            finished ? 'انتهى ✓' : 'ما زال يلعب...',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: finished ? green : const Color(0xFF999399),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Summary Row
// =============================================================================

class _SummaryRow extends StatelessWidget {
  final String label;
  final String myValue;
  final String friendValue;

  const _SummaryRow({
    required this.label,
    required this.myValue,
    required this.friendValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ),

          Expanded(
            child: Text(
              myValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                color: Color(0xFF511281),
              ),
            ),
          ),

          Expanded(
            child: Text(
              friendValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
