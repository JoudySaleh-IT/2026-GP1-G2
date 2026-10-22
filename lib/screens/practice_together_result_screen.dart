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
                _buildResultHero(isTie: isTie, currentWon: currentWon),
                const SizedBox(height: 16),
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

  Widget _buildResultHero({required bool isTie, required bool currentWon}) {
    String title;
    String message;
    Color cardColor;

    if (isTie) {
      title = 'تعادل رائع! 🤝';
      message = 'أبدعتما! كانت النتيجة متقاربة جدًا';
      cardColor = const Color(0xFFF7F0FF);
    } else if (currentWon) {
      title = 'أحسنت يا بطل! 🌟';
      message = 'فزت بالتحدي، استمر بهذا الأداء الرائع!';
      cardColor = const Color(0xFFFFF1C9);
    } else {
      title = 'أداء جميل! 💪';
      message = 'هذه المرة فاز صديقك، والمحاولة القادمة لك!';
      cardColor = const Color(0xFFE6F4EA);
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 145),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _purple.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -35,
              top: -45,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5).withOpacity(0.28),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              left: -30,
              bottom: -55,
              child: Container(
                width: 145,
                height: 105,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9E2).withOpacity(0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // For fastest implementation,
                  // use the same bunny code from ChildHomeScreen.
                  const SizedBox(width: 92, height: 110, child: _ResultBunny()),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _purple,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          message,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            height: 1.5,
                            color: Color(0xFF666666),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFF3B82F),
                          size: 18,
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
            label: 'أسئلة انتهى وقتها',
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

class _ResultBunny extends StatelessWidget {
  const _ResultBunny();

  @override
  Widget build(BuildContext context) {
    const Color normalFace = Color(0xFFFFDCE7);
    const Color normalBody = Color(0xFF8B55B3);
    const Color innerEar = Color(0xFFFFA1B7);
    const Color details = Color(0xFF4D3855);

    const Color faceColor = normalFace;
    const Color bodyColor = normalBody;

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // =========================================================
        // Bubble
        // =========================================================
        Positioned(
          top: 3,
          right: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Text(
              'هيا!',
              style: TextStyle(
                color: Color(0xFF8B55B3),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ),

        // =========================================================
        // Happy decorative lines
        // =========================================================
        Positioned(
          top: 38,
          right: 3,
          child: Transform.rotate(
            angle: -0.35,
            child: Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD36A),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),

        Positioned(
          top: 47,
          right: 0,
          child: Transform.rotate(
            angle: 0.60,
            child: Container(
              width: 4,
              height: 11,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD36A),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),

        // =========================================================
        // Right ear
        // =========================================================
        Positioned(
          top: 19,
          right: 28,
          child: Container(
            width: 20,
            height: 43,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 27,
                decoration: BoxDecoration(
                  color: innerEar.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // =========================================================
        // Left ear - tilted
        // =========================================================
        Positioned(
          top: 24,
          left: 21,
          child: Transform.rotate(
            angle: -0.38,
            child: Container(
              width: 20,
              height: 43,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 27,
                  decoration: BoxDecoration(
                    color: innerEar.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // =========================================================
        // Body
        // =========================================================
        Positioned(
          bottom: 1,
          child: Container(
            width: 50,
            height: 34,
            decoration: BoxDecoration(
              color: bodyColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(27),
                topRight: Radius.circular(27),
                bottomLeft: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
            ),
          ),
        ),

        // =========================================================
        // Head
        // =========================================================
        Positioned(
          top: 53,
          child: Container(
            width: 66,
            height: 61,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(31),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Eyes
                Positioned(
                  top: 22,
                  right: 15,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: BoxDecoration(
                      color: details,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 22,
                  left: 15,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: BoxDecoration(
                      color: details,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 35,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 35,
                  left: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 30,
                  left: 29,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Smile
                Positioned(
                  top: 37,
                  left: 23,
                  child: Container(
                    width: 19,
                    height: 8,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: details, width: 1.5),
                      ),
                      borderRadius: const BorderRadius.only(
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
