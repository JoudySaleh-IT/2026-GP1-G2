import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_friend_screen.dart';
import 'friend_requests_screen.dart';
import '../widgets/child_bottom_nav.dart';
import '../services/friend_service.dart';
import '../services/practice_together_service.dart';
import 'style_constants.dart';
import 'practice_lobby_screen.dart';
import '../../services/notification_service.dart';
import '../widgets/child_store_avatar.dart';

class FriendsScreen extends StatelessWidget {
  final String childId;

  const FriendsScreen({super.key, required this.childId});

  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  // ─────────────────────────────────────────────
  // Standard app SnackBar
  // بدون تغيير
  // ─────────────────────────────────────────────

  // ─────────────────────────────────────────────
  // Confirm + Remove Friend
  // بدون تغيير
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
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
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

      NotificationService.showSuccessSnackBar(
        'تمت إزالة $friendName من قائمة أصدقائك',
      );
    } catch (_) {
      if (!context.mounted) return;

      NotificationService.showErrorSnackBar(
        'تعذّرت إزالة الصديق. حاول مرة أخرى.',
      );
    }
  }

  Color _exerciseLevelColor(String level) {
    switch (level) {
      case 'beginner':
        return const Color(0xFF65A97D);

      case 'intermediate':
        return const Color(0xFFF1A340);

      case 'advanced':
        return const Color(0xFFFF6969);

      default:
        return _purple;
    }
  }

  Color _exerciseLevelBackground(String level) {
    switch (level) {
      case 'beginner':
        return const Color(0xFFEAF7EF);

      case 'intermediate':
        return const Color(0xFFFFF3DB);

      case 'advanced':
        return const Color(0xFFFFF0F1);

      default:
        return const Color(0xFFF7F0FF);
    }
  }

  Future<void> _showPracticeTogetherDialog(
    BuildContext context, {
    required String friendId,
    required String friendName,
  }) async {
    final service = PracticeTogetherService();

    // Check whether the child is eligible to invite friends.
    try {
      final bool placementDone = await service.hasCompletedPlacement(childId);

      if (!context.mounted) return;

      if (!placementDone) {
        NotificationService.showErrorSnackBar(
          'أكمل اختبار تحديد المستوى أولًا لتتمكن من التدرّب مع أصدقائك',
        );

        return;
      }

      final bool journeyCompleted = await service.hasCompletionCertificate(
        childId,
      );

      if (!context.mounted) return;

      if (journeyCompleted) {
        NotificationService.showSuccessSnackBar(
          'أحسنت! لقد أكملت رحلتك في فصيح وأتقنت جميع حروفك 🎉',
        );

        return;
      }
    } catch (e) {
      if (!context.mounted) return;

      NotificationService.showErrorSnackBar(
        'تعذّر التحقق من إمكانية التدريب مع الأصدقاء، حاول مرة أخرى',
      );

      return;
    }

    PracticeExerciseType selectedType = PracticeExerciseType.listening;

    PracticeAvailableExercise? selectedExercise;

    Future<List<PracticeAvailableExercise>> exercisesFuture = service
        .getAvailableExercises(childId: childId, exerciseType: selectedType);

    final bool? shouldSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: _background,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),

                title: Text(
                  'تدرّب مع $friendName',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: _purple,
                  ),
                ),

                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'اختر نوع التمرين',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      SegmentedButton<PracticeExerciseType>(
                        showSelectedIcon: false,

                        style: ButtonStyle(
                          padding: const WidgetStatePropertyAll(
                            EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                          ),

                          textStyle: const WidgetStatePropertyAll(
                            TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),

                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return selectedType ==
                                          PracticeExerciseType.listening
                                      ? const Color(0xFFE9D8F5)
                                      : const Color(0xFFE1F3E7);
                                }

                                return Colors.white;
                              }),

                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return selectedType ==
                                          PracticeExerciseType.listening
                                      ? _purple
                                      : const Color(0xFF55936B);
                                }

                                return const Color(0xFF777777);
                              }),

                          side: const WidgetStatePropertyAll(
                            BorderSide(color: Color(0xFFE5D8F1)),
                          ),

                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: PracticeExerciseType.listening,
                            label: Text('الاستماع'),
                            icon: Icon(Icons.hearing_rounded),
                          ),
                          ButtonSegment(
                            value: PracticeExerciseType.speaking,
                            label: Text('النطق'),
                            icon: Icon(Icons.mic_rounded),
                          ),
                        ],
                        selected: {selectedType},
                        onSelectionChanged: (selection) {
                          final newType = selection.first;

                          setDialogState(() {
                            selectedType = newType;

                            // Clear the old selection because
                            // availability changes by exercise type.
                            selectedExercise = null;

                            exercisesFuture = service.getAvailableExercises(
                              childId: childId,
                              exerciseType: selectedType,
                            );
                          });
                        },
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'اختر تمرينك',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      FutureBuilder<List<PracticeAvailableExercise>>(
                        future: exercisesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.all(18),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _purple,
                                ),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'تعذّر تحميل تمارينك. حاول مرة أخرى.',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: _coral,
                                ),
                              ),
                            );
                          }

                          final exercises = snapshot.data ?? [];

                          if (exercises.isEmpty) {
                            final message =
                                selectedType == PracticeExerciseType.speaking
                                ? 'لا توجد تمارين نطق متاحة حاليًا. أكمل تمارين الاستماع أولًا.'
                                : 'لا توجد تمارين متاحة حاليًا.';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                message,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontFamily: 'Tajawal',
                                  color: Color(0xFF777777),
                                  height: 1.5,
                                ),
                              ),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            key: ValueKey(selectedType),

                            value: selectedExercise?.id,

                            isExpanded: true,

                            menuMaxHeight: 350,

                            dropdownColor: Colors.white,

                            borderRadius: BorderRadius.circular(20),

                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _purple,
                            ),

                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF7F0FF),

                              hintText: 'اختر حرفًا',

                              hintStyle: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 13,
                                color: Color(0xFF9A8BA5),
                              ),

                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),

                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Color(0xFFDCC9F5),
                                ),
                              ),

                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: _purple,
                                  width: 1.5,
                                ),
                              ),

                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),

                            items: exercises.map((exercise) {
                              final color = _exerciseLevelColor(exercise.level);

                              final background = _exerciseLevelBackground(
                                exercise.level,
                              );

                              return DropdownMenuItem<String>(
                                value: exercise.id,

                                child: Row(
                                  children: [
                                    // Letter bubble
                                    Container(
                                      width: 35,
                                      height: 35,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: background,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        exercise.letter,
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 23,
                                          fontWeight: FontWeight.w800,
                                          color: _purple,
                                          height: 1,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: Text(
                                        'حرف ${exercise.letter}',
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: _purple,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 4),

                                    // Difficulty indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: background,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: Text(
                                        exercise.arabicLevel,
                                        style: TextStyle(
                                          fontFamily: 'Tajawal',
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),

                            onChanged: (value) {
                              if (value == null) return;

                              final exercise = exercises.firstWhere(
                                (item) => item.id == value,
                              );

                              setDialogState(() {
                                selectedExercise = exercise;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (selectedExercise == null) {
                        NotificationService.showErrorSnackBar(
                          'اختر تمرينك أولًا',
                        );

                        return;
                      }

                      Navigator.pop(dialogContext, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _coral,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'إرسال الدعوة',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (shouldSend != true || selectedExercise == null) {
      return;
    }

    try {
      final sessionId = await service.sendInvitation(
        senderChildId: childId,
        receiverChildId: friendId,
        exerciseType: selectedType,
        letter: selectedExercise!.letter,
        level: selectedExercise!.level,
      );

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PracticeLobbyScreen(sessionId: sessionId, childId: childId),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      if (e.toString().contains('RECEIVER_JOURNEY_COMPLETED')) {
        NotificationService.showSuccessSnackBar(
          'لقد أكمل $friendName رحلته في فصيح وأتقن حروفه! 🎓',
        );

        return;
      }

      if (e.toString().contains('RECEIVER_PLACEMENT_NOT_DONE')) {
        NotificationService.showErrorSnackBar(
          '$friendName يحتاج إلى إكمال اختبار تحديد المستوى أولًا',
        );

        if (e.toString().contains('EXERCISE_NOT_AVAILABLE')) {
          NotificationService.showErrorSnackBar(
            'تغيّرت تمارينك المتاحة، اختر تمرينك مرة أخرى',
          );

          if (e.toString().contains('SENDER_JOURNEY_COMPLETED')) {
            NotificationService.showSuccessSnackBar(
              'لقد أكملت رحلتك في فصيح بنجاح! 🎓',
            );

            return;
          }

          return;
        }

        return;
      }

      NotificationService.showErrorSnackBar(
        'تعذّر إرسال الدعوة. حاول مرة أخرى.',
      );

      debugPrint('Practice Together invitation error: $e');
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
            // HEADER
            // بدون تغيير
            // ===============================================================
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
              trailingActions: const [SizedBox(width: 48, height: 48)],
            ),

            // ===============================================================
            // CONTENT
            // ===============================================================
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(child: _FriendsBackground()),
                  ),

                  SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // =================================================
                          // Cute Intro
                          // =================================================
                          const _FriendsWelcomeCard(),

                          const SizedBox(height: 14),

                          // =================================================
                          // Add friend
                          // =================================================
                          _MainActionCard(
                            icon: Icons.person_add_alt_1_rounded,
                            title: 'إضافة صديق',
                            subtitle: 'أضف صديقًا باستخدام رمز QR',
                            color: _coral,
                            backgroundColor: const Color(0xFFFFF1F3),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AddFriendScreen(childId: childId),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 11),

                          // =================================================
                          // Friend requests
                          // =================================================
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('friend_requests')
                                .where('receiverId', isEqualTo: childId)
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
                                backgroundColor: const Color(0xFFF5F0FA),
                                badgeCount: requestCount,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FriendRequestsScreen(
                                        childId: childId,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 23),

                          // =================================================
                          // Friends title
                          // =================================================
                          const _FriendsSectionTitle(),

                          const SizedBox(height: 11),

                          // =================================================
                          // Friendships childA
                          // =================================================
                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('friendships')
                                .where('childA', isEqualTo: childId)
                                .snapshots(),
                            builder: (context, childASnapshot) {
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

                              // =============================================
                              // Friendships childB
                              // =============================================
                              return StreamBuilder<
                                QuerySnapshot<Map<String, dynamic>>
                              >(
                                stream: FirebaseFirestore.instance
                                    .collection('friendships')
                                    .where('childB', isEqualTo: childId)
                                    .snapshots(),
                                builder: (context, childBSnapshot) {
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
                                      message: 'أضف صديقًا لتتمرّنا معًا',
                                    );
                                  }

                                  return Column(
                                    children: friendships.map((friendship) {
                                      final data = friendship.data();

                                      final String childA =
                                          data['childA']?.toString() ?? '';

                                      final String childB =
                                          data['childB']?.toString() ?? '';

                                      if (childA.isEmpty || childB.isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      final String friendId = childA == childId
                                          ? childB
                                          : childA;

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        child: _FriendProfileCard(
                                          key: ValueKey(friendId),
                                          friendId: friendId,

                                          onPracticeTogether: (friendName) {
                                            _showPracticeTogetherDialog(
                                              context,
                                              friendId: friendId,
                                              friendName: friendName,
                                            );
                                          },

                                          onRemove: (friendName) {
                                            _confirmRemoveFriend(
                                              context,
                                              friendId: friendId,
                                              friendName: friendName,
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ===============================================================
        // FOOTER
        // بدون تغيير
        // ===============================================================
        bottomNavigationBar: ChildBottomNav(
          currentRoute: '/child/friends',
          childId: childId,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Welcome Card
// ─────────────────────────────────────────────────────────────────────────────

class _FriendsWelcomeCard extends StatelessWidget {
  const _FriendsWelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 125),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF511281).withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // دائرة بنفسجية بالخلفية
            Positioned(
              right: -45,
              top: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5).withOpacity(0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // دائرة وردية بالخلفية
            Positioned(
              left: 40,
              bottom: -55,
              child: Container(
                width: 130,
                height: 105,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9E2).withOpacity(0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // الأرنب مع أصدقائه
                  SizedBox(
                    width: 100,
                    height: 105,
                    child: _FriendsGroupBunny(),
                  ),

                  SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الأصدقاء يجعلون التدريب أمتع!',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF511281),
                          ),
                        ),

                        SizedBox(height: 5),

                        Text(
                          'أضف أصدقاءك وتدرّبوا معًا في فصيح',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11.5,
                            height: 1.5,
                            color: Color(0xFF777777),
                          ),
                        ),

                        SizedBox(height: 9),

                        Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFFFF8DA6),
                              size: 16,
                            ),

                            SizedBox(width: 5),

                            Text(
                              'تعلّم • تدرّب • تقدّم',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B55B3),
                              ),
                            ),
                          ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Main Action Card
// ─────────────────────────────────────────────────────────────────────────────

class _MainActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onTap;
  final int badgeCount;

  const _MainActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.backgroundColor,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withOpacity(0.11)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
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
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.78),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withOpacity(0.10)),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),

                  if (badgeCount > 0)
                    Positioned(
                      top: -5,
                      left: -5,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6969),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF333333),
                        fontFamily: 'Tajawal',
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF808080),
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.72),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withOpacity(0.75),
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────────────────────

class _FriendsSectionTitle extends StatelessWidget {
  const _FriendsSectionTitle();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 38,
          height: 38,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xFFF1E8FA),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_alt_rounded,
              color: Color(0xFF7B4AAD),
              size: 20,
            ),
          ),
        ),

        SizedBox(width: 9),

        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'قائمة الأصدقاء',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF511281),
                fontFamily: 'Tajawal',
              ),
            ),

            SizedBox(height: 1),

            Text(
              'اختَر صديقًا وابدأوا تحديًا ممتعًا',
              style: TextStyle(
                fontSize: 10.5,
                color: Color(0xFF888888),
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Friend Profile Card
// نفس functionality
// ─────────────────────────────────────────────────────────────────────────────

class _FriendProfileCard extends StatelessWidget {
  final String friendId;

  final void Function(String friendName) onPracticeTogether;

  final void Function(String friendName) onRemove;

  const _FriendProfileCard({
    super.key,
    required this.friendId,
    required this.onPracticeTogether,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('child_public_profiles')
          .doc(friendId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const _FriendLoadingCard();
        }

        if (snapshot.hasError) {
          debugPrint(
            '❌ PUBLIC PROFILE ERROR '
            '$friendId: ${snapshot.error}',
          );

          return const SizedBox.shrink();
        }

        if (!snapshot.hasData ||
            !snapshot.data!.exists ||
            snapshot.data!.data() == null) {
          debugPrint('❌ MISSING PUBLIC PROFILE = $friendId');

          return const SizedBox.shrink();
        }

        final profile = snapshot.data!.data()!;

        final String firstName = (profile['firstName'] ?? '').toString().trim();

        final String lastName = (profile['lastName'] ?? '').toString().trim();

        final String legacyName = (profile['name'] ?? '').toString().trim();

        final String fullName = [
          firstName,
          lastName,
        ].where((part) => part.isNotEmpty).join(' ');

        final String displayName = fullName.isNotEmpty
            ? fullName
            : legacyName.isNotEmpty
            ? legacyName
            : 'صديق';

        final String avatar = profile['avatar']?.toString() ?? '🌟';

        final dynamic rawPlacementDone = profile['placementDone'];

        final bool placementDone = rawPlacementDone == true;

        final bool journeyCompleted = profile['journeyCompleted'] == true;

        debugPrint(
          '👥 FRIEND $displayName '
          '($friendId) → '
          'placementDone=$rawPlacementDone '
          'type=${rawPlacementDone.runtimeType}',
        );

        final String? avatarId = profile['equippedAvatarId']?.toString();

        final String? backgroundId = profile['equippedBackgroundId']
            ?.toString();

        return _FriendCard(
          name: displayName,
          avatar: avatar,
          avatarId: avatarId,
          backgroundId: backgroundId,
          canPracticeTogether: placementDone && !journeyCompleted,
          journeyCompleted: journeyCompleted,
          onPracticeTogether: () {
            onPracticeTogether(displayName);
          },
          onRemove: () {
            onRemove(displayName);
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Friend Card
// ─────────────────────────────────────────────────────────────────────────────

class _FriendCard extends StatelessWidget {
  final String name;
  final String avatar;
  final String? avatarId;
  final String? backgroundId;
  final bool canPracticeTogether;
  final bool journeyCompleted;
  final VoidCallback onPracticeTogether;
  final VoidCallback onRemove;

  const _FriendCard({
    required this.name,
    required this.avatar,
    required this.canPracticeTogether,
    this.journeyCompleted = false,
    this.avatarId,
    this.backgroundId,
    required this.onPracticeTogether,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF511281);
    const coral = Color(0xFFFF6969);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: canPracticeTogether
              ? const Color(0xFFE5D8F1)
              : const Color(0xFFE8E5E9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // ==================================
              // AVATAR
              // ==================================
              Container(
                width: 66,
                height: 66,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F0FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFDCC9F5)),
                ),
                child: StoreAvatarImage(
                  avatar: avatar,
                  avatarId: avatarId,
                  backgroundId: backgroundId,
                  size: 60,
                ),
              ),

              const SizedBox(width: 13),

              // ==================================
              // NAME + STATUS
              // ==================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: purple,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: journeyCompleted
                            ? const Color(0xFFFFF3D5)
                            : canPracticeTogether
                            ? const Color(0xFFEAF7EF)
                            : const Color(0xFFF3F1F4),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        journeyCompleted
                            ? 'أكمل رحلة فصيح! 🎓'
                            : canPracticeTogether
                            ? 'جاهز يتدرّب معك! 🌟'
                            : 'يكمل اختبار المستوى أولًا',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: journeyCompleted
                              ? const Color(0xFFA97919)
                              : canPracticeTogether
                              ? const Color(0xFF55936B)
                              : const Color(0xFF8E8A91),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================
              // REMOVE — LESS PROMINENT
              // ==================================
              Container(
                width: 35,
                height: 35,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF4F5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  tooltip: 'إزالة الصديق',
                  padding: EdgeInsets.zero,
                  onPressed: onRemove,
                  icon: const Icon(
                    Icons.person_remove_outlined,
                    color: Color(0xFFD99A9A),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // ====================================
          // MAIN FUN ACTION
          // ====================================
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: canPracticeTogether ? onPracticeTogether : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1E7FA),
                foregroundColor: purple,

                disabledBackgroundColor: journeyCompleted
                    ? const Color(0xFFFFF5E0)
                    : const Color(0xFFF2F0F3),

                disabledForegroundColor: journeyCompleted
                    ? const Color(0xFFA97919)
                    : const Color(0xFFA8A5AA),

                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: const StadiumBorder(),
              ),
              icon: Icon(
                journeyCompleted
                    ? Icons.workspace_premium_rounded
                    : canPracticeTogether
                    ? Icons.sports_esports_rounded
                    : Icons.lock_outline_rounded,
                size: 18,
              ),
              label: Text(
                journeyCompleted
                    ? 'أتمّ رحلته بنجاح'
                    : canPracticeTogether
                    ? 'تدرّب معًا 🌟'
                    : 'لم يكمل اختبار تحديد المستوى',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Friend Loading Card
// ─────────────────────────────────────────────────────────────────────────────

class _FriendLoadingCard extends StatelessWidget {
  const _FriendLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(21),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF511281)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF511281).withOpacity(0.07)),
      ),
      child: Column(
        children: [
          const SizedBox(width: 82, height: 88, child: _WaitingFriendsBunny()),

          const SizedBox(height: 8),

          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF511281),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Tajawal',
            ),
          ),

          const SizedBox(height: 5),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 11.5,
              fontFamily: 'Tajawal',
            ),
          ),

          const SizedBox(height: 9),

          Icon(
            icon,
            color: const Color(0xFF8B55B3).withOpacity(0.45),
            size: 21,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background
// دوائر pastel فقط
// ─────────────────────────────────────────────────────────────────────────────

class _FriendsBackground extends StatelessWidget {
  const _FriendsBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 35,
          right: -55,
          child: _circle(145, const Color(0xFFDCC9F5).withOpacity(0.18)),
        ),

        Positioned(
          top: 280,
          left: -60,
          child: _circle(150, const Color(0xFFDDF2E3).withOpacity(0.26)),
        ),

        Positioned(
          top: 520,
          right: -45,
          child: _circle(120, const Color(0xFFFFDCE3).withOpacity(0.23)),
        ),

        Positioned(
          top: 720,
          left: 28,
          child: _circle(20, const Color(0xFFD5C0ED).withOpacity(0.36)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Cute Bunny
// نفس شكل الأرنب المستخدم في الصفحات الأخرى
// ─────────────────────────────────────────────────────────────────────────────

class _CuteFriendsBunny extends StatelessWidget {
  const _CuteFriendsBunny();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);
    const Color bodyColor = Color(0xFF8B55B3);
    const Color innerEarColor = Color(0xFFFFA1B7);
    const Color detailsColor = Color(0xFF4D3855);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Right ear
        Positioned(
          top: 0,
          right: 13,
          child: Container(
            width: 19,
            height: 37,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // Left ear
        Positioned(
          top: 0,
          left: 13,
          child: Container(
            width: 19,
            height: 37,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // Body
        Positioned(
          bottom: 0,
          child: Container(
            width: 45,
            height: 29,
            decoration: const BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
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
              color: faceColor,
              borderRadius: BorderRadius.circular(28),
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
                Positioned(
                  top: 20,
                  right: 14,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 20,
                  left: 14,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 32,
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
                  top: 32,
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

                Positioned(
                  top: 28,
                  left: 26,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 34,
                  left: 22,
                  child: Container(
                    width: 15,
                    height: 7,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: detailsColor, width: 1.4),
                      ),
                      borderRadius: BorderRadius.only(
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

class _WaitingFriendsBunny extends StatelessWidget {
  const _WaitingFriendsBunny();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);
    const Color bodyColor = Color(0xFFB694CE);
    const Color innerEarColor = Color(0xFFFFA1B7);
    const Color detailsColor = Color(0xFF4D3855);
    const Color pink = Color(0xFFFF7890);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // ─────────────────────────────────────────
        // الأذن اليمنى - واقفة
        // ─────────────────────────────────────────
        Positioned(
          top: 0,
          right: 14,
          child: Transform.rotate(
            angle: 0.12,
            child: Container(
              width: 19,
              height: 38,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 24,
                  decoration: BoxDecoration(
                    color: innerEarColor.withOpacity(0.52),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ─────────────────────────────────────────
        // الأذن اليسرى - مائلة ونازلة شوي
        // تعطي شكل لطيف ومختلف
        // ─────────────────────────────────────────
        Positioned(
          top: 9,
          left: 6,
          child: Transform.rotate(
            angle: -0.62,
            child: Container(
              width: 19,
              height: 38,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 24,
                  decoration: BoxDecoration(
                    color: innerEarColor.withOpacity(0.52),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // ─────────────────────────────────────────
        // الجسم
        // ─────────────────────────────────────────
        Positioned(
          bottom: 0,
          child: Container(
            width: 46,
            height: 29,
            decoration: const BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
            ),
          ),
        ),

        // ─────────────────────────────────────────
        // الرأس
        // ─────────────────────────────────────────
        Positioned(
          top: 27,
          child: Container(
            width: 59,
            height: 55,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(28),
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
                // العين اليمنى
                Positioned(
                  top: 19,
                  right: 14,
                  child: Container(
                    width: 6,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // العين اليسرى
                Positioned(
                  top: 19,
                  left: 14,
                  child: Container(
                    width: 6,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // لمعة العين اليمنى
                Positioned(
                  top: 20,
                  right: 15,
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // لمعة العين اليسرى
                Positioned(
                  top: 20,
                  left: 15,
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // الخد الأيمن
                Positioned(
                  top: 32,
                  right: 6,
                  child: Container(
                    width: 10,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // الخد الأيسر
                Positioned(
                  top: 32,
                  left: 6,
                  child: Container(
                    width: 10,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // الأنف
                Positioned(
                  top: 28,
                  left: 26,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: pink,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // ابتسامة صغيرة
                Positioned(
                  top: 34,
                  left: 22,
                  child: Container(
                    width: 15,
                    height: 7,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: detailsColor, width: 1.4),
                      ),
                      borderRadius: BorderRadius.only(
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

        // ─────────────────────────────────────────
        // يد يمين
        // ─────────────────────────────────────────
        Positioned(
          right: 19,
          bottom: 7,
          child: Transform.rotate(
            angle: -0.30,
            child: Container(
              width: 10,
              height: 20,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // ─────────────────────────────────────────
        // يد يسار
        // ─────────────────────────────────────────
        Positioned(
          left: 19,
          bottom: 7,
          child: Transform.rotate(
            angle: 0.30,
            child: Container(
              width: 10,
              height: 20,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // ─────────────────────────────────────────
        // قلب صغير بين اليدين
        // ─────────────────────────────────────────
        Positioned(
          bottom: 10,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 4),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF7890),
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendsGroupBunny extends StatelessWidget {
  const _FriendsGroupBunny();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);
    const Color bodyColor = Color(0xFF8B55B3);
    const Color innerEarColor = Color(0xFFFFA1B7);
    const Color detailsColor = Color(0xFF4D3855);

    Widget miniFriend({required double size, required Color bgColor}) {
      final double eyeW = size * 0.12;
      final double eyeH = size * 0.15;
      final double gap = size * 0.18;
      final double smileW = size * 0.34;
      final double smileH = size * 0.18;

      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Color(0x0C000000), blurRadius: 4)],
        ),
        child: Center(
          child: Transform.translate(
            offset: const Offset(0, 1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: eyeW,
                      height: eyeH,
                      decoration: const BoxDecoration(
                        color: detailsColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: gap),
                    Container(
                      width: eyeW,
                      height: eyeH,
                      decoration: const BoxDecoration(
                        color: detailsColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: size * 0.10),
                Container(
                  width: smileW,
                  height: smileH,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: detailsColor, width: 1.2),
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // ============================================================
        // الصديق الصغير - يمين
        // ============================================================
        Positioned(
          right: 0,
          bottom: 8,
          child: miniFriend(size: 34, bgColor: const Color(0xFFFFE4EA)),
        ),

        // ============================================================
        // الصديق الصغير - يسار
        // ============================================================
        Positioned(
          left: 0,
          bottom: 10,
          child: miniFriend(size: 32, bgColor: const Color(0xFFDDF2E3)),
        ),

        // ============================================================
        // أذن الأرنب الرئيسية - يمين
        // ============================================================
        Positioned(
          top: 0,
          right: 25,
          child: Container(
            width: 19,
            height: 37,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // ============================================================
        // أذن الأرنب الرئيسية - يسار
        // ============================================================
        Positioned(
          top: 0,
          left: 25,
          child: Container(
            width: 19,
            height: 37,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // ============================================================
        // جسم الأرنب الرئيسية
        // ============================================================
        Positioned(
          bottom: 0,
          child: Container(
            width: 46,
            height: 29,
            decoration: const BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
            ),
          ),
        ),

        // ============================================================
        // رأس الأرنب الرئيسية
        // ============================================================
        Positioned(
          top: 27,
          child: Container(
            width: 59,
            height: 55,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(28),
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
                Positioned(
                  top: 20,
                  right: 14,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 20,
                  left: 14,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 21,
                  right: 15,
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 21,
                  left: 15,
                  child: Container(
                    width: 2,
                    height: 2,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 32,
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
                  top: 32,
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

                Positioned(
                  top: 28,
                  left: 26,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 34,
                  left: 22,
                  child: Container(
                    width: 15,
                    height: 7,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: detailsColor, width: 1.4),
                      ),
                      borderRadius: BorderRadius.only(
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

        // ============================================================
        // قلب الصداقة
        // ============================================================
        Positioned(
          top: 14,
          left: 4,
          child: Container(
            width: 25,
            height: 25,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 4),
              ],
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF7890),
              size: 14,
            ),
          ),
        ),
      ],
    );
  }
}
