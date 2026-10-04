import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/practice_together_service.dart';
import 'style_constants.dart';

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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? const Color(0xFFD7685B) : _purple,
        content: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            message,
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Tajawal', color: Colors.white),
          ),
        ),
      ),
    );
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

    final receiverAvatar = receiverProfile['avatar']?.toString() ?? '🌟';

    return Column(
      children: [
        FaseehStyle.buildLargeHeader(
          context: context,
          title: 'تدرّب معًا',
          subtitle: 'استعد للتحدي مع صديقك',
          leading: const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Icon(Icons.groups_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),

        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(receiverAvatar, style: const TextStyle(fontSize: 72)),

                  const SizedBox(height: 18),

                  Text(
                    receiverName,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: _purple,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    status == 'pending'
                        ? 'بانتظار قبول الدعوة...'
                        : 'يختار صديقك تمرينه الآن...',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      color: Color(0xFF777177),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const CircularProgressIndicator(color: _purple),

                  if (status == 'pending' && isSender) ...[
                    const SizedBox(height: 30),

                    OutlinedButton(
                      onPressed: _cancelPendingInvitation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _coral,
                        side: const BorderSide(color: _coral),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'إلغاء الدعوة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
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

    return Column(
      children: [
        FaseehStyle.buildLargeHeader(
          context: context,
          title: 'استعدوا للتحدي!',
          subtitle: 'جاهزون للتدرّب معًا؟',
          leading: const SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: Icon(
                Icons.sports_esports_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),

        Expanded(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(
                          child: _PlayerCard(
                            profile: senderProfile,
                            ready: senderReady,
                            isMe: currentChildIsSender,
                          ),
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: _coral,
                            ),
                          ),
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

                    const SizedBox(height: 35),

                    if (status == 'lobby') ...[
                      const Text(
                        'اضغط عندما تكون مستعدًا',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _purple,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        'الوقت المتبقي: $secondsLeft ثانية',
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          color: Color(0xFF777177),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: currentChildReady || _readyBusy
                              ? null
                              : _markReady,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _purple,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: currentChildReady
                                ? _green
                                : const Color(0xFFD6CEDC),
                            shape: const StadiumBorder(),
                          ),
                          child: _readyBusy
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
                                      : 'أنا جاهز!',
                                  style: const TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],

                    if (status == 'countdown')
                      Expanded(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _getCountdownText(data),
                              key: ValueKey(_getCountdownText(data)),
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 68,
                                fontWeight: FontWeight.w900,
                                color: _coral,
                              ),
                            ),
                          ),
                        ),
                      ),

                    if (status == 'active')
                      const Expanded(
                        child: Center(
                          child: Text(
                            'ابدأ!',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 54,
                              fontWeight: FontWeight.w900,
                              color: _coral,
                            ),
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

    final avatar = profile['avatar']?.toString() ?? '🌟';

    Widget avatarWidget = Text(avatar, style: const TextStyle(fontSize: 58));

    // Grey out the avatar until this child presses ready.
    if (!ready) {
      avatarWidget = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: Opacity(opacity: 0.45, child: avatarWidget),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 10),
      decoration: BoxDecoration(
        color: ready ? const Color(0xFFF0F8F2) : const Color(0xFFF2F0F2),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: ready
              ? green.withValues(alpha: 0.45)
              : Colors.grey.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          avatarWidget,

          const SizedBox(height: 12),

          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: ready ? purple : const Color(0xFFAAA5AA),
            ),
          ),

          if (isMe) ...[
            const SizedBox(height: 4),
            Text(
              'أنت',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                color: ready ? purple : const Color(0xFFAAA5AA),
              ),
            ),
          ],

          const SizedBox(height: 10),

          Text(
            ready ? 'جاهز ✓' : 'غير جاهز',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: ready ? green : const Color(0xFFA5A0A5),
            ),
          ),
        ],
      ),
    );
  }
}
