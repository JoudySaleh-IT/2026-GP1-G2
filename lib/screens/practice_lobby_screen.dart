import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/practice_together_service.dart';
import 'style_constants.dart';
import '../services/notification_service.dart';
import '../widgets/child_store_avatar.dart';

class PracticeLobbyScreen extends StatefulWidget {
  final String sessionId;
  final String childId;

  const PracticeLobbyScreen({
    super.key,
    required this.sessionId,
    required this.childId,
  });

  @override
  State<PracticeLobbyScreen> createState() => _PracticeLobbyScreenState();
}

class _PracticeLobbyScreenState extends State<PracticeLobbyScreen> {
  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);
  static const Color _green = Color(0xFF70A884);

  final PracticeTogetherService _service = PracticeTogetherService();

  Timer? _ticker;

  bool _readyBusy = false;
  bool _timeoutBusy = false;
  bool _startBusy = false;
  bool _terminalHandled = false;
  bool _exerciseNavigationStarted = false;

  String? _profileKey;
  Future<List<Map<String, dynamic>?>>? _profilesFuture;

  @override
  void initState() {
    super.initState();

    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

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

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    if (isError) {
      NotificationService.showErrorSnackBar(message);
    } else {
      NotificationService.showSuccessSnackBar(message);
    }
  }

  Future<void> _markReady() async {
    if (_readyBusy) return;

    setState(() {
      _readyBusy = true;
    });

    try {
      await _service.markReady(
        sessionId: widget.sessionId,
        childId: widget.childId,
      );
    } catch (e) {
      _showMessage('تعذّر تسجيل الاستعداد، حاول مرة أخرى', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _readyBusy = false;
        });
      }
    }
  }

  Future<void> _cancelPendingInvitation() async {
    try {
      await _service.cancelInvitation(
        sessionId: widget.sessionId,
        childId: widget.childId,
      );
    } catch (e) {
      _showMessage('تعذّر إلغاء الدعوة', isError: true);
    }
  }

  Future<void> _checkTimedActions(Map<String, dynamic> data) async {
    final status = data['status']?.toString() ?? '';
    // ----------------------------------------------------------
    // Pending invitation expiration
    // ----------------------------------------------------------

    if (status == 'pending' && !_timeoutBusy) {
      final createdAt = data['createdAt'] as Timestamp?;

      if (createdAt != null) {
        final elapsed = DateTime.now().difference(createdAt.toDate());

        if (elapsed >= const Duration(minutes: 30)) {
          _timeoutBusy = true;

          try {
            await _service.cancelInvitation(
              sessionId: widget.sessionId,
              childId: widget.childId,
            );
          } catch (_) {
            // The invitation may already have been accepted,
            // declined, or cancelled on the other device.
          } finally {
            _timeoutBusy = false;
          }

          return;
        }
      }
    }
    // ----------------------------------------------------------
    // 60-second lobby timeout
    // ----------------------------------------------------------
    if (status == 'lobby' && !_timeoutBusy) {
      final startedAt = data['lobbyStartedAt'] as Timestamp?;

      if (startedAt != null) {
        final elapsed = DateTime.now().difference(startedAt.toDate());

        if (elapsed >= const Duration(seconds: 60)) {
          _timeoutBusy = true;

          try {
            await _service.cancelLobbyAfterTimeout(
              sessionId: widget.sessionId,
              childId: widget.childId,
            );
          } catch (_) {
            // The other device may have already updated the session,
            // or server time may be slightly ahead.
          } finally {
            _timeoutBusy = false;
          }
        }
      }
    }

    // ----------------------------------------------------------
    // Shared 3-second countdown
    // ----------------------------------------------------------
    if (status == 'countdown' && !_startBusy) {
      final startedAt = data['countdownStartedAt'] as Timestamp?;

      if (startedAt != null) {
        final elapsed = DateTime.now().difference(startedAt.toDate());

        // Small safety margin because Firestore rules use server time.
        if (elapsed >= const Duration(milliseconds: 3250)) {
          _startBusy = true;

          try {
            await _service.startSessionAfterCountdown(
              sessionId: widget.sessionId,
              childId: widget.childId,
            );
          } catch (_) {
            // Another device may already have started it.
          } finally {
            _startBusy = false;
          }
        }
      }
    }
  }

  void _handleTerminalState(Map<String, dynamic> data) {
    if (_terminalHandled) return;

    final status = data['status']?.toString() ?? '';

    if (status != 'declined' && status != 'cancelled') {
      return;
    }

    _terminalHandled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final cancelReason = data['cancelReason']?.toString();

      String message;

      if (status == 'declined') {
        message = 'تم رفض دعوة التدريب';
      } else if (cancelReason == 'ready_timeout') {
        message = 'انتهى الوقت لأن أحد اللاعبين لم يستعد';
      } else {
        message = 'تم إلغاء جلسة التدريب';
      }

      Navigator.pop(context);

      if (!mounted) return;

      _showMessage(message);
    });
  }

  void _openSelectedExercise(Map<String, dynamic> data) {
    if (_exerciseNavigationStarted || !mounted) {
      return;
    }

    if (data['status'] != 'active') {
      return;
    }

    final String senderId = data['senderId']?.toString() ?? '';

    final String receiverId = data['receiverId']?.toString() ?? '';

    final bool isSender = widget.childId == senderId;

    if (!isSender && widget.childId != receiverId) {
      return;
    }

    final String exerciseType = data['exerciseType']?.toString() ?? '';

    final String letter = isSender
        ? data['senderLetter']?.toString() ?? ''
        : data['receiverLetter']?.toString() ?? '';

    final String level = isSender
        ? data['senderLevel']?.toString() ?? ''
        : data['receiverLevel']?.toString() ?? '';

    if (letter.isEmpty || level.isEmpty) {
      return;
    }

    _exerciseNavigationStarted = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (exerciseType == 'listening') {
        Navigator.pushReplacementNamed(
          context,
          '/child/exercise/listening',
          arguments: {
            'letter': letter,
            'level': level,
            'childId': widget.childId,
            'practiceSessionId': widget.sessionId,
          },
        );

        return;
      }

      if (exerciseType == 'speaking') {
        Navigator.pushReplacementNamed(
          context,
          '/child/exercise/recording',
          arguments: {
            'letter': letter,
            'level': level,
            'childId': widget.childId,
            'practiceSessionId': widget.sessionId,
          },
        );

        return;
      }

      _exerciseNavigationStarted = false;
    });
  }

  int _getLobbySecondsLeft(Map<String, dynamic> data) {
    final startedAt = data['lobbyStartedAt'] as Timestamp?;

    if (startedAt == null) return 60;

    final elapsed = DateTime.now().difference(startedAt.toDate());

    final remaining = 60 - elapsed.inSeconds;

    return remaining.clamp(0, 60);
  }

  String _getCountdownText(Map<String, dynamic> data) {
    final startedAt = data['countdownStartedAt'] as Timestamp?;

    if (startedAt == null) return '3';

    final milliseconds = DateTime.now()
        .difference(startedAt.toDate())
        .inMilliseconds;

    if (milliseconds < 1000) return '3';
    if (milliseconds < 2000) return '2';
    if (milliseconds < 3000) return '1';

    return 'ابدأ!';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _service.watchSession(sessionId: widget.sessionId),
          builder: (context, sessionSnapshot) {
            if (!sessionSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _purple),
              );
            }

            final document = sessionSnapshot.data!;

            if (!document.exists || document.data() == null) {
              return const Center(
                child: Text(
                  'تعذّر العثور على الجلسة',
                  style: TextStyle(fontFamily: 'Tajawal', color: _purple),
                ),
              );
            }

            final data = document.data()!;

            _handleTerminalState(data);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              _checkTimedActions(data);

              if (data['status'] == 'active') {
                _openSelectedExercise(data);
              }
            });

            final senderId = data['senderId']?.toString() ?? '';

            final receiverId = data['receiverId']?.toString() ?? '';

            final status = data['status']?.toString() ?? '';

            final bool isSender = widget.childId == senderId;

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

                if (status == 'pending' || status == 'accepted') {
                  return _buildWaitingView(
                    status: status,
                    isSender: isSender,
                    receiverProfile: receiverProfile,
                  );
                }

                return _buildLobbyView(
                  data: data,
                  senderProfile: senderProfile,
                  receiverProfile: receiverProfile,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaitingView({
    required String status,
    required bool isSender,
    required Map<String, dynamic> receiverProfile,
  }) {
    final String firstName = (receiverProfile['firstName'] ?? '')
        .toString()
        .trim();

    final String lastName = (receiverProfile['lastName'] ?? '')
        .toString()
        .trim();

    final String legacyName = (receiverProfile['name'] ?? '').toString().trim();

    final String fullName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');

    final String receiverName = fullName.isNotEmpty
        ? fullName
        : legacyName.isNotEmpty
        ? legacyName
        : 'صديقك';

    final String receiverAvatar = receiverProfile['avatar']?.toString() ?? '🌟';

    final String? receiverAvatarId = receiverProfile['equippedAvatarId']
        ?.toString();

    final String? receiverBackgroundId = receiverProfile['equippedBackgroundId']
        ?.toString();

    final bool accepted = status == 'accepted';

    // The screen already refreshes through _ticker,
    // so this gives us cute animated waiting dots.
    final int activeDot = (DateTime.now().millisecondsSinceEpoch ~/ 450) % 3;

    return Column(
      children: [
        FaseehStyle.buildLargeHeader(
          context: context,
          title: 'تدرّب معًا',
          subtitle: accepted
              ? 'صديقك وافق! استعد للتحدي 🎉'
              : 'دعوتك في الطريق 💌',
          leading: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Icon(
                accepted ? Icons.celebration_rounded : Icons.mail_rounded,
                color: Colors.white,
                size: 29,
              ),
            ),
          ),
        ),

        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE9DCF4)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // ============================================
                    // INVITATION ICON
                    // ============================================
                    Container(
                      width: 55,
                      height: 55,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4EAFB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        accepted
                            ? Icons.celebration_rounded
                            : Icons.forward_to_inbox_rounded,
                        color: _purple,
                        size: 27,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ============================================
                    // FRIEND AVATAR
                    // ============================================
                    Container(
                      width: 92,
                      height: 92,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F0FF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFDCC9F5),
                          width: 2,
                        ),
                      ),
                      child: StoreAvatarImage(
                        avatar: receiverAvatar,
                        avatarId: receiverAvatarId,
                        backgroundId: receiverBackgroundId,
                        size: 84,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      receiverName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _purple,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Text(
                      accepted
                          ? 'وافق $receiverName على دعوتك! 🎉'
                          : 'دعوتك وصلت إلى $receiverName 💌',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4B3F50),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      accepted
                          ? 'يختار تمرينه الآن، خلك جاهز!'
                          : 'بانتظار موافقته على التحدي',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF777177),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ============================================
                    // FRIENDLY WAITING ANIMATION
                    // ============================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final bool active = index == activeDot;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 12 : 8,
                          height: active ? 12 : 8,
                          decoration: BoxDecoration(
                            color: active ? _purple : const Color(0xFFD9C8E8),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7E8),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            color: Color(0xFFE5A52F),
                            size: 19,
                          ),

                          const SizedBox(width: 6),

                          Flexible(
                            child: Text(
                              accepted
                                  ? 'سيبدأ التحدي تلقائيًا عندما يصبح كل شيء جاهزًا'
                                  : 'خلك جاهز! بنبدأ أول ما يوافق صديقك',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF806328),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (status == 'pending' && isSender) ...[
                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _cancelPendingInvitation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _coral,
                            side: const BorderSide(color: Color(0xFFFFB5B5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: const StadiumBorder(),
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text(
                            'إلغاء الدعوة',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLobbyView({
    required Map<String, dynamic> data,
    required Map<String, dynamic> senderProfile,
    required Map<String, dynamic> receiverProfile,
  }) {
    final status = data['status']?.toString() ?? '';

    final senderReady = data['senderReady'] == true;
    final receiverReady = data['receiverReady'] == true;

    final senderId = data['senderId']?.toString() ?? '';

    final bool currentChildIsSender = widget.childId == senderId;

    final bool currentChildReady = currentChildIsSender
        ? senderReady
        : receiverReady;

    final secondsLeft = _getLobbySecondsLeft(data);

    final double timerProgress = (secondsLeft / 60).clamp(0.0, 1.0).toDouble();

    final bool timeRunningLow = secondsLeft <= 10;

    return Column(
      children: [
        FaseehStyle.buildLargeHeader(
          context: context,
          title: status == 'countdown' ? 'يلا نبدأ!' : 'استعدوا للتحدي!',
          subtitle: status == 'countdown'
              ? 'التحدي سيبدأ خلال لحظات'
              : 'جاهزون للتدرّب معًا؟',
          leading: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Icon(
                status == 'countdown'
                    ? Icons.rocket_launch_rounded
                    : Icons.sports_esports_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              // ============================================================
              // Cute pastel page background
              // ============================================================
              const Positioned.fill(
                child: IgnorePointer(child: _LobbyBackgroundDecoration()),
              ),

              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 35),
                child: Column(
                  children: [
                    // ======================================================
                    // Intro card
                    // ======================================================
                    const _LobbyIntroCard(),

                    const SizedBox(height: 18),

                    // ======================================================
                    // Players arena
                    // ======================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(13, 18, 13, 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _purple.withValues(alpha: 0.09),
                          width: 1.3,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Small arena title
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: Color(0xFFF2B536),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'ساحة التحدي',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: _purple,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.auto_awesome_rounded,
                                size: 16,
                                color: Color(0xFFF2B536),
                              ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          SizedBox(
                            height: 270,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _PlayerCard(
                                    profile: senderProfile,
                                    ready: senderReady,
                                    isMe: currentChildIsSender,
                                  ),
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 7),
                                  child: _LobbyVsBadge(),
                                ),

                                Expanded(
                                  child: _PlayerCard(
                                    profile: receiverProfile,
                                    ready: receiverReady,
                                    isMe: !currentChildIsSender,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ======================================================
                    // Normal ready lobby
                    // ======================================================
                    if (status == 'lobby') ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
                        decoration: BoxDecoration(
                          color: timeRunningLow
                              ? const Color(0xFFFFF0F1)
                              : const Color(0xFFFFF8E8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: timeRunningLow
                                ? _coral.withValues(alpha: 0.18)
                                : const Color(
                                    0xFFF0B63C,
                                  ).withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 43,
                                  height: 43,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.timer_rounded,
                                    color: timeRunningLow
                                        ? _coral
                                        : const Color(0xFFE3A52D),
                                    size: 24,
                                  ),
                                ),

                                const SizedBox(width: 11),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'وقت الاستعداد',
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: _purple,
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      Text(
                                        currentChildReady
                                            ? 'أنت جاهز! ننتظر صديقك الآن ✨'
                                            : 'اضغط جاهز قبل انتهاء الوقت',
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 10.5,
                                          color: Color(0xFF777177),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 52,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    '$secondsLeft ث',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Tajawal',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: timeRunningLow ? _coral : _purple,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 13),

                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: LinearProgressIndicator(
                                value: timerProgress,
                                minHeight: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.90,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  timeRunningLow
                                      ? _coral
                                      : const Color(0xFFF0B63C),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 57,
                        child: ElevatedButton.icon(
                          onPressed: currentChildReady || _readyBusy
                              ? null
                              : _markReady,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: currentChildReady
                                ? _green
                                : const Color(0xFFDCD3E3),
                            disabledForegroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(21),
                            ),
                            shadowColor: _purple.withValues(alpha: 0.18),
                          ),
                          icon: _readyBusy
                              ? const SizedBox.shrink()
                              : Icon(
                                  currentChildReady
                                      ? Icons.check_circle_rounded
                                      : Icons.emoji_events_rounded,
                                  size: 22,
                                ),
                          label: _readyBusy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  currentChildReady
                                      ? 'أنا جاهز! ✓'
                                      : 'أنا جاهز للتحدي!',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 11),

                      if (!currentChildReady)
                        const Text(
                          'لما تصبحون جاهزين أنتم الاثنين، يبدأ العد التنازلي تلقائيًا',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 10.5,
                            height: 1.5,
                            color: Color(0xFF8A828C),
                          ),
                        ),
                    ],

                    // ======================================================
                    // Shared countdown
                    // ======================================================
                    if (status == 'countdown') ...[
                      const SizedBox(height: 4),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 25,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F3),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: _coral.withValues(alpha: 0.13),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'استعدا... 🚀',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _purple,
                              ),
                            ),

                            const SizedBox(height: 13),

                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Container(
                                key: ValueKey(_getCountdownText(data)),
                                width: 105,
                                height: 105,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _coral.withValues(alpha: 0.22),
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _coral.withValues(alpha: 0.10),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _getCountdownText(data),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 48,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    color: _coral,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFFF0B63C),
                                  size: 15,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'التحدي على وشك البدء!',
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF777177),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Color(0xFFF0B63C),
                                  size: 15,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],

                    // ======================================================
                    // Very short active state before navigation
                    // ======================================================
                    if (status == 'active') ...[
                      const SizedBox(height: 4),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 30),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F8F2),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.rocket_launch_rounded,
                              color: _green,
                              size: 42,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'ابدأ!',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 37,
                                fontWeight: FontWeight.w900,
                                color: _purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final bool ready;
  final bool isMe;

  const _PlayerCard({
    required this.profile,
    required this.ready,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF511281);
    const green = Color(0xFF70A884);
    const coral = Color(0xFFFF6969);

    final String firstName = (profile['firstName'] ?? '').toString().trim();

    final String lastName = (profile['lastName'] ?? '').toString().trim();

    final String legacyName = (profile['name'] ?? '').toString().trim();

    final String fullName = [
      firstName,
      lastName,
    ].where((part) => part.isNotEmpty).join(' ');

    final String name = fullName.isNotEmpty
        ? fullName
        : legacyName.isNotEmpty
        ? legacyName
        : 'صديق';

    final String avatar = profile['avatar']?.toString() ?? '🌟';

    final String? avatarId = profile['equippedAvatarId']?.toString();

    final String? backgroundId = profile['equippedBackgroundId']?.toString();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 270,
      padding: const EdgeInsets.fromLTRB(7, 12, 7, 12),
      decoration: BoxDecoration(
        color: ready
            ? const Color(0xFFF0F9F3)
            : isMe
            ? const Color(0xFFF7F0FF)
            : const Color(0xFFFFF3F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: ready
              ? green.withValues(alpha: 0.30)
              : isMe
              ? purple.withValues(alpha: 0.12)
              : coral.withValues(alpha: 0.10),
          width: ready ? 1.6 : 1.2,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // =========================================================
              // Avatar
              // =========================================================
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 91,
                    height: 91,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ready
                            ? green.withValues(alpha: 0.28)
                            : purple.withValues(alpha: 0.10),
                        width: 2,
                      ),
                    ),
                  ),

                  StoreAvatarImage(
                    avatar: avatar,
                    avatarId: avatarId,
                    backgroundId: backgroundId,
                    size: 82,
                  ),

                  if (ready)
                    Positioned(
                      right: -1,
                      bottom: 1,
                      child: Container(
                        width: 27,
                        height: 27,
                        decoration: BoxDecoration(
                          color: green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // =========================================================
              // Name
              // =========================================================
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: purple,
                ),
              ),

              const SizedBox(height: 4),

              // Always reserve the same height here so both player cards
              // stay perfectly aligned, even though only one shows "أنت".
              SizedBox(
                height: 23,
                child: Center(
                  child: isMe
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'أنت',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: purple,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),

              const SizedBox(height: 9),

              // =========================================================
              // Ready status
              // =========================================================
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: ready
                      ? green.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ready
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      size: 13,
                      color: ready ? green : const Color(0xFF9A8DA0),
                    ),

                    const SizedBox(width: 4),

                    Text(
                      ready ? 'جاهز!' : 'يستعد...',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ready ? green : const Color(0xFF8F8493),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tiny decorative sparkle
          Positioned(
            top: 0,
            left: 0,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 13,
              color: ready
                  ? const Color(0xFFF0B63C)
                  : purple.withValues(alpha: 0.20),
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyVsBadge extends StatelessWidget {
  const _LobbyVsBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 12,
            color: Color(0xFFF0B63C),
          ),

          const SizedBox(height: 4),

          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF6969).withValues(alpha: 0.18),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'VS',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFFFF6969),
              ),
            ),
          ),

          const SizedBox(height: 4),

          const Icon(
            Icons.auto_awesome_rounded,
            size: 10,
            color: Color(0xFF8B55B3),
          ),
        ],
      ),
    );
  }
}

class _LobbyBackgroundDecoration extends StatelessWidget {
  const _LobbyBackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Large soft purple blob
        Positioned(
          top: 45,
          right: -65,
          child: _circle(155, const Color(0xFFDCC9F5).withValues(alpha: 0.20)),
        ),

        // Pink blob
        Positioned(
          top: 230,
          left: -55,
          child: _circle(135, const Color(0xFFFFD6DF).withValues(alpha: 0.30)),
        ),

        // Green blob
        Positioned(
          top: 455,
          right: -60,
          child: _circle(145, const Color(0xFFD9F0DF).withValues(alpha: 0.38)),
        ),

        // Clouds
        Positioned(
          top: 195,
          right: 18,
          child: Icon(
            Icons.cloud_rounded,
            size: 34,
            color: const Color(0xFFCFE8FF).withValues(alpha: 0.55),
          ),
        ),

        Positioned(
          top: 530,
          left: 16,
          child: Icon(
            Icons.cloud_rounded,
            size: 28,
            color: const Color(0xFFD9E8FF).withValues(alpha: 0.48),
          ),
        ),

        // Sparkles
        Positioned(
          top: 135,
          left: 24,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: const Color(0xFFF3B43F).withValues(alpha: 0.58),
          ),
        ),

        Positioned(
          top: 395,
          right: 28,
          child: Icon(
            Icons.star_rounded,
            size: 17,
            color: const Color(0xFFFF8D9B).withValues(alpha: 0.38),
          ),
        ),

        Positioned(
          top: 675,
          right: 40,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: const Color(0xFF8B55B3).withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LobbyIntroCard extends StatelessWidget {
  const _LobbyIntroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 142,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(
          color: const Color(0xFF511281).withValues(alpha: 0.09),
          width: 1.3,
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
            // Decorative circles
            Positioned(
              right: -42,
              top: -55,
              child: Container(
                width: 145,
                height: 145,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8C2F0).withValues(alpha: 0.32),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              left: 30,
              bottom: -60,
              child: Container(
                width: 145,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD7E1).withValues(alpha: 0.48),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 13, 13, 13),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'مواجهة ودّية! 🏆',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF511281),
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'استعد أنت وصديقك، واضغط جاهز قبل انتهاء الوقت',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11,
                            height: 1.45,
                            color: Color(0xFF777177),
                          ),
                        ),

                        const SizedBox(height: 11),

                        const Wrap(
                          spacing: 6,
                          runSpacing: 5,
                          children: [
                            _LobbyMiniChip(
                              icon: Icons.people_alt_rounded,
                              text: 'لاعبان',
                              background: Color(0xFFE9DDF5),
                              foreground: Color(0xFF7B4AAD),
                            ),
                            _LobbyMiniChip(
                              icon: Icons.timer_rounded,
                              text: '٦٠ ثانية',
                              background: Color(0xFFFFEDC8),
                              foreground: Color(0xFFD09324),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  const SizedBox(width: 96, height: 118, child: _LobbyBunny()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyMiniChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  const _LobbyMiniChip({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _LobbyBunny extends StatelessWidget {
  const _LobbyBunny();

  @override
  Widget build(BuildContext context) {
    const Color face = Color(0xFFFFDCE7);
    const Color body = Color(0xFF8B55B3);
    const Color innerEar = Color(0xFFFFA1B7);
    const Color details = Color(0xFF4D3855);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Speech bubble
        Positioned(
          top: 2,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.90),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'جاهز؟',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: body,
              ),
            ),
          ),
        ),

        // Trophy
        const Positioned(
          top: 7,
          left: 0,
          child: Icon(
            Icons.emoji_events_rounded,
            size: 23,
            color: Color(0xFFF2B536),
          ),
        ),

        // Right ear
        Positioned(
          top: 20,
          right: 25,
          child: Container(
            width: 18,
            height: 39,
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEar.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // Left ear
        Positioned(
          top: 22,
          left: 24,
          child: Transform.rotate(
            angle: -0.20,
            child: Container(
              width: 18,
              height: 39,
              decoration: BoxDecoration(
                color: face,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 24,
                  decoration: BoxDecoration(
                    color: innerEar.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Body
        Positioned(
          bottom: 3,
          child: Container(
            width: 47,
            height: 32,
            decoration: const BoxDecoration(
              color: body,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ),

        // Head
        Positioned(
          top: 50,
          child: Container(
            width: 61,
            height: 56,
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Eyes
                const Positioned(
                  top: 20,
                  right: 14,
                  child: CircleAvatar(radius: 3, backgroundColor: details),
                ),

                const Positioned(
                  top: 20,
                  left: 14,
                  child: CircleAvatar(radius: 3, backgroundColor: details),
                ),

                // Cheeks
                Positioned(
                  top: 32,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withValues(alpha: 0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 32,
                  left: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withValues(alpha: 0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                const Positioned(
                  top: 27,
                  left: 27,
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: Color(0xFFFF7890),
                  ),
                ),

                // Smile
                const Positioned(
                  top: 34,
                  left: 22,
                  child: SizedBox(
                    width: 17,
                    height: 7,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: details, width: 1.4),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10),
                          bottomRight: Radius.circular(10),
                        ),
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
