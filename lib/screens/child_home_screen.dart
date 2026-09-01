import 'package:flutter/material.dart';
import '../utils/arabic_numbers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/ChildSession.dart';
import 'style_constants.dart';
import '../services/notification_service.dart';
import '../services/friend_service.dart';
import '../widgets/child_bottom_nav.dart';

// ─── Mock Data ───────────────────────────────────────────────────────────────
const _mockChild = (
  name: 'أحمد',
  avatar: '🦁',
  level: 'متوسط',
  streak: 7,
  points: 1250,
  rank: 12,
  todayExercises: 2,
  todayGoal: 5,
);

// ─── Screen ──────────────────────────────────────────────────────────────────
class ChildHomeScreen extends StatelessWidget {
  final String childId;

  const ChildHomeScreen({super.key, required this.childId});

  // ✅ دالة التحقق من إتمام التمارين
  // يجب أن تكون جميع درجات الحروف >= 70 لإعادة التقييم
  bool _canReassess(Map<String, dynamic> data) {
    final Map<String, dynamic> scores = data['letterScores'] ?? {};

    if (scores.isEmpty) return false;

    return !scores.values.any((score) => (score as num) < 70);
  }

  // ─── Friend Request Test Dialog ────────────────────────────────────────────
  Future<void> _showFriendRequestTestDialog(BuildContext context) async {
    String enteredId = '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('اختبار طلب صداقة'),
          content: TextField(
            onChanged: (value) {
              enteredId = value;
            },
            decoration: const InputDecoration(hintText: 'FSH-XXXX-XXXX'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await FriendService().sendFriendRequestByFasehId(
                    currentChildId: childId,
                    enteredFasehId: enteredId,
                  );

                  if (!dialogContext.mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال طلب الصداقة ✅')),
                  );
                } on FirebaseException catch (e) {
                  print('Friend request test error: $e');

                  if (!dialogContext.mounted) return;

                  String message = 'تعذر إرسال طلب الصداقة، حاول مرة أخرى';

                  if (e.code == 'permission-denied') {
                    message =
                        'تم إرسال طلب صداقة لهذا الطفل مسبقًا أو أنكما أصدقاء بالفعل';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: const Color(0xFF511281),
                    ),
                  );
                } catch (e) {
                  print('Friend request test error: $e');

                  if (!dialogContext.mounted) return;

                  String message = 'تعذر إرسال طلب الصداقة، حاول مرة أخرى';

                  final error = e.toString();

                  if (error.contains('CANNOT_ADD_SELF')) {
                    message = 'لا يمكنك إضافة نفسك كصديق';
                  } else if (error.contains('FASEH_ID_NOT_FOUND')) {
                    message = 'لم يتم العثور على طفل بهذا المعرّف';
                  } else if (error.contains('INVALID_FASEH_ID')) {
                    message = 'يرجى إدخال معرّف فصيح صحيح';
                  } else if (error.contains('NOT_AUTHENTICATED')) {
                    message = 'يجب تسجيل الدخول أولًا';
                  } else if (error.contains('PUBLIC_PROFILE_NOT_FOUND')) {
                    message = 'تعذر العثور على ملف الطفل';
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: const Color(0xFF511281),
                    ),
                  );
                }
              },
              child: const Text('إرسال'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .snapshots(),
      builder: (context, snapshot) {
        // ─── Loading ─────────────────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF511281)),
            ),
          );
        }

        // ─── Child Not Found ─────────────────────────────────────────────────
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('عذراً، لم يتم العثور على البيانات')),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;

        final bool hasCompletedPlacement = data['placementDone'] ?? false;

        // ✅ حساب هل يحق له إعادة التقييم
        final bool canReassess = _canReassess(data);

        // ─── Dynamic Daily Goal Logic ────────────────────────────────────────
        int assignedLettersCount = 0;

        if (data['letterScores'] != null) {
          final Map<dynamic, dynamic> scores = data['letterScores'] as Map;

          // نحسب فقط الحروف التي درجتها أقل من 70
          assignedLettersCount = scores.values.where((score) {
            final num scoreValue = (score is num) ? score : 0;

            return scoreValue < 70;
          }).length;
        } else if (data['assignedLetters'] != null) {
          assignedLettersCount = (data['assignedLetters'] as List).length;
        }

        // هدف افتراضي = 3 إذا لم يتم تعيين حروف
        final int dynamicTodayGoal = assignedLettersCount > 0
            ? assignedLettersCount
            : 3;

        final int todayCompleted = data['todayExercises'] ?? 0;
        final List<String> practiceLetters = [];

        if (data['letterScores'] != null) {
          final Map<dynamic, dynamic> scores = data['letterScores'] as Map;

          for (final entry in scores.entries) {
            final num score = entry.value is num ? entry.value : 0;

            if (score < 70) {
              practiceLetters.add(entry.key.toString());
            }
          }
        } else if (data['assignedLetters'] != null) {
          practiceLetters.addAll(
            (data['assignedLetters'] as List).map(
              (letter) => letter.toString(),
            ),
          );
        }

        // ─── Stats ───────────────────────────────────────────────────────────
        final String displayStreak = toArabicDigits(
          (data['streak'] != null && data['streak'] > 0)
              ? data['streak']
              : _mockChild.streak,
        );

        final String displayPoints = toArabicDigits(
          (data['points'] != null && data['points'] > 0)
              ? data['points']
              : _mockChild.points,
        );

        final String displayRank = toArabicDigits(
          (data['rank'] != null && data['rank'] > 0)
              ? '#${data['rank']}'
              : '#${_mockChild.rank}',
        );

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFFCF9EA),

            body: Column(
              children: [
                // ============================================================
                // HEADER
                // لم يتم تغيير تصميمه أو وظيفته
                // ============================================================
                _ChildHeader(
                  name: data['name'] ?? 'بطل فصيح',
                  avatar: data['avatar'] ?? '🦁',
                  level: hasCompletedPlacement
                      ? (data['level'] ?? 'مبتدئ')
                      : 'لم يُحدَّد المستوى بعد',
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      children: [
                        // ====================================================
                        // PLACEMENT TEST BANNER
                        // ====================================================
                        _TestBanner(
                          isReassessment: hasCompletedPlacement,
                          isLocked: hasCompletedPlacement && !canReassess,
                          onTap: () {
                            if (hasCompletedPlacement && !canReassess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'أكمل تمارينك أولاً لتتمكن من إعادة التقييم! 💪',
                                  ),
                                  backgroundColor: Color(0xFF511281),
                                ),
                              );

                              return;
                            }

                            Navigator.pushNamed(
                              context,
                              '/child/placement-test',
                              arguments: childId,
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        // ====================================================
                        // STATS
                        // ====================================================
                        Row(
                          children: [
                            // ── Streak
                            Expanded(
                              child: _StatCard(
                                icon: Icons.local_fire_department_rounded,
                                value: displayStreak,
                                label: 'المواظبة',
                                iconColor: const Color(0xFFFF6969),
                                cardColor: const Color(0xFFFFF2F2),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // ── Points
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star_rounded,
                                value: displayPoints,
                                label: 'النقاط',
                                iconColor: const Color(0xFFF3B82F),
                                cardColor: const Color(0xFFFFF9E9),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // ── Rank
                            Expanded(
                              child: _StatCard(
                                icon: Icons.emoji_events_rounded,
                                value: displayRank,
                                label: 'الترتيب',
                                iconColor: const Color(0xFF6F2DA8),
                                cardColor: const Color(0xFFF8F1FF),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ====================================================
                        // TODAY GOAL
                        // ====================================================
                        _TodayGoalCard(
                          done: todayCompleted,
                          goal: dynamicTodayGoal,
                        ),

                        const SizedBox(height: 18),

                        _PracticeLettersCard(letters: practiceLetters),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ===============================================================
            // FOOTER
            // لم يتم تغييره
            // ===============================================================
            bottomNavigationBar: ChildBottomNav(
              currentRoute: '/child/home',
              childId: childId,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────
class _ChildHeader extends StatelessWidget {
  final String name;
  final String avatar;
  final String level;

  const _ChildHeader({
    required this.name,
    required this.avatar,
    required this.level,
  });

  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _ParentPasswordDialog());
  }

  void _showChildLogoutConfirmation(
    BuildContext context,
    SharedPreferences prefs,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تأكيد تسجيل الخروج',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text('هل أنت متأكد أنك تريد تسجيل الخروج؟'),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              ElevatedButton(
                onPressed: () async {
                  final nav = Navigator.of(dialogContext, rootNavigator: true);

                  try {
                    final user = FirebaseAuth.instance.currentUser;

                    // إذا كان هذا جهاز طفل anonymous
                    // نحذف Firestore authorization أولًا
                    if (user != null && user.isAnonymous) {
                      await FirebaseFirestore.instance
                          .collection('child_device_links')
                          .doc(user.uid)
                          .delete();
                    }

                    // Clear local child session
                    await prefs.remove('saved_childId');

                    await prefs.remove('saved_parentId');

                    await prefs.remove('isChildLoggedIn');

                    ChildSession.currentChildId = null;
                    ChildSession.currentParentId = null;

                    // Sign out after deleting device link
                    await FirebaseAuth.instance.signOut();

                    nav.pushNamedAndRemoveUntil('/', (route) => false);
                  } catch (e) {
                    print('Child logout error: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6969),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
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
  }

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    final isChildLoggedIn = prefs.getBool('isChildLoggedIn') ?? false;

    if (isChildLoggedIn) {
      _showChildLogoutConfirmation(context, prefs);
    } else {
      _showLogoutDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FaseehStyle.buildLargeHeader(
      context: context,
      title: 'مرحبًا $name!',
      subtitle: level,

      leading: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Text(avatar, style: const TextStyle(fontSize: 32)),
        ),
      ),

      trailingActions: [
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () => _handleLogout(context),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Parent Password Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _ParentPasswordDialog extends StatefulWidget {
  const _ParentPasswordDialog();

  @override
  State<_ParentPasswordDialog> createState() => _ParentPasswordDialogState();
}

class _ParentPasswordDialogState extends State<_ParentPasswordDialog> {
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _hasError = false;
  bool _loading = false;

  String _errorMessage = '';
  String? _parentEmail;

  @override
  void initState() {
    super.initState();

    // Retrieve the parent email automatically
    _parentEmail = FirebaseAuth.instance.currentUser?.email;
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInParent() async {
    if (_parentEmail == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'لم يتم العثور على حساب ولي الأمر';
      });

      return;
    }

    final navigator = Navigator.of(context);

    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _parentEmail!,
        password: _passwordController.text,
      );

      if (mounted) {
        navigator.pop();
      }

      NotificationService.showSuccessSnackBar(
        'تم التحقق، يتم إعادة التوجيه لصفحة ولي الامر',
      );

      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/parent/dashboard', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;

        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          _errorMessage = 'كلمة المرور غير صحيحة';
        } else {
          _errorMessage = 'حدث خطأ، حاول مرة أخرى';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _hasError = true;
        _errorMessage = 'حدث خطأ غير متوقع';
      });

      print('Sign in error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: const Row(
          children: [
            Icon(Icons.lock_rounded, color: Color(0xFF511281), size: 22),
            SizedBox(width: 8),
            Text(
              'حساب ولي الأمر',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF222222),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'للعودة إلى حساب ولي الأمر، يرجى إدخال كلمة المرور الخاصة بك:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textDirection: TextDirection.ltr,
              onSubmitted: (_) => _signInParent(),
              decoration: InputDecoration(
                hintText: 'كلمة المرور',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF511281),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                errorText: _hasError ? _errorMessage : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: const Color(0xFF511281).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Color(0xFF511281),
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 4),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          ElevatedButton(
            onPressed: _loading ? null : _signInParent,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6969),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'دخول',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),

          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Placement Test Banner
// ─────────────────────────────────────────────────────────────────────────────

class _TestBanner extends StatefulWidget {
  final bool isReassessment;
  final bool isLocked;
  final VoidCallback onTap;

  const _TestBanner({
    required this.isReassessment,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  State<_TestBanner> createState() => _TestBannerState();
}

class _TestBannerState extends State<_TestBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _scale = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isLocked
        ? const Color(0xFFAAA5AD)
        : widget.isReassessment
        ? const Color(0xFF511281)
        : const Color(0xFFFF6969);

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (!widget.isLocked) {
            _ctrl.forward();
          }
        },
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Opacity(
          opacity: widget.isLocked ? 0.85 : 1,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: bgColor.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  // ───── دوائر خلفية كبيرة وناعمة ─────
                  Positioned(
                    right: -40,
                    bottom: -55,
                    child: Container(
                      width: 170,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Positioned(
                    left: 65,
                    top: -55,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // ───── فقاعة حرف ض ─────
                  if (!widget.isLocked)
                    Positioned(
                      top: 15,
                      left: 100,
                      child: Transform.rotate(
                        angle: -0.12,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'ض',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ───── فقاعة حرف ص ─────
                  if (!widget.isLocked)
                    Positioned(
                      bottom: 15,
                      left: 135,
                      child: Transform.rotate(
                        angle: 0.10,
                        child: Container(
                          width: 29,
                          height: 29,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'ص',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ───── زخرفة صغيرة بدون نجوم ─────
                  Positioned(
                    right: 20,
                    top: 17,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.30),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  Positioned(
                    right: 37,
                    top: 25,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // ───── المحتوى ─────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.isLocked
                                    ? 'إعادة التقييم'
                                    : widget.isReassessment
                                    ? 'إعادة تقييم المستوى'
                                    : 'تحديد المستوى',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                widget.isLocked
                                    ? 'أنهِ تمارينك لفتح الاختبار'
                                    : 'اكتشف مستوى نطقك!',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.88),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 13),

                              // زر صغير طفولي
                              if (!widget.isLocked)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.25),
                                    ),
                                  ),
                                  child: const Text(
                                    'هيا نبدأ!',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ───── شخصية طفولية مرسومة ─────
                        const SizedBox(width: 7),

                        // ───── زر التشغيل ─────
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.10),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.isLocked
                                ? Icons.lock_outline_rounded
                                : widget.isReassessment
                                ? Icons.refresh_rounded
                                : Icons.play_arrow_rounded,
                            color: bgColor,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color cardColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: iconColor.withOpacity(0.15), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ─── Small sparkle
          Positioned(
            top: 1,
            right: 6,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 12,
              color: iconColor.withOpacity(0.30),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ─── Icon bubble
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),

                const SizedBox(height: 7),

                // ─── Value
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF222222),
                  ),
                ),

                const SizedBox(height: 3),

                // ─── Label
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF777777),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Today's Goal Card
// ─────────────────────────────────────────────────────────────────────────────
class _TodayGoalCard extends StatelessWidget {
  final int done;
  final int goal;

  const _TodayGoalCard({required this.done, required this.goal});

  @override
  Widget build(BuildContext context) {
    final int safeGoal = goal <= 0 ? 1 : goal;

    final int remaining = (goal - done) < 0 ? 0 : goal - done;

    final double progress = (done / safeGoal).clamp(0.0, 1.0).toDouble();

    final bool completed = remaining == 0;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 155),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7FF),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF511281).withOpacity(0.10),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            // ───── تلة خضراء ─────
            Positioned(
              left: -35,
              bottom: -45,
              child: Container(
                width: 180,
                height: 95,
                decoration: BoxDecoration(
                  color: const Color(0xFFBDE6C0).withOpacity(0.55),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(100),
                    topRight: Radius.circular(100),
                  ),
                ),
              ),
            ),

            // ───── تلة ثانية ─────
            Positioned(
              left: 70,
              bottom: -55,
              child: Container(
                width: 165,
                height: 95,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEFCF).withOpacity(0.7),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(100),
                    topRight: Radius.circular(100),
                  ),
                ),
              ),
            ),

            // ───── سحابة ─────
            Positioned(
              left: 90,
              top: 20,
              child: Row(
                children: [
                  Container(
                    width: 25,
                    height: 17,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(-7, -5),
                    child: Container(
                      width: 21,
                      height: 21,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ───── فقاعة حرف خ ─────
            Positioned(
              left: 118,
              bottom: 21,
              child: Transform.rotate(
                angle: -0.15,
                child: Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: const Color(0xFF511281).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'خ',
                      style: TextStyle(
                        color: Color(0xFF511281),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ───── شخصية طفولية ─────
            const Positioned(
              left: 15,
              bottom: 10,
              child: SizedBox(
                width: 73,
                height: 88,
                child: _CuteCharacter(
                  faceColor: Color(0xFFFFD9E6),
                  accentColor: Color(0xFFFF8FB1),
                ),
              ),
            ),

            // ───── المحتوى ─────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.track_changes_rounded,
                            color: Color(0xFF511281),
                            size: 21,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'هدف اليوم',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ],
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6969).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          toArabicDigits('$done/$goal'),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFFFF6969),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Padding(
                    padding: const EdgeInsets.only(left: 80),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 11,
                        backgroundColor: const Color(
                          0xFFFF6969,
                        ).withOpacity(0.13),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFF6969),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Padding(
                    padding: const EdgeInsets.only(left: 82),
                    child: Text(
                      completed
                          ? 'أحسنت! حققت هدف اليوم'
                          : 'باقي ${toArabicDigits(remaining)} تدريبات لتحقيق الهدف!',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
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

class _CuteCharacter extends StatelessWidget {
  final Color faceColor;
  final Color accentColor;

  const _CuteCharacter({
    super.key,
    required this.faceColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color innerEarColor = Color(0xFFFFA1B7);
    const Color faceDetails = Color(0xFF4D3855);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // ─────────────────────────────────────────────
        // الأذن اليمنى
        // ─────────────────────────────────────────────
        Positioned(
          top: 0,
          right: 11,
          child: Container(
            width: 18,
            height: 34,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 22,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // ─────────────────────────────────────────────
        // الأذن اليسرى
        // ─────────────────────────────────────────────
        Positioned(
          top: 0,
          left: 11,
          child: Container(
            width: 18,
            height: 34,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 22,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        // ─────────────────────────────────────────────
        // الجسم
        // ─────────────────────────────────────────────
        Positioned(
          bottom: 0,
          child: Container(
            width: 42,
            height: 27,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ),

        // ─────────────────────────────────────────────
        // الرأس
        // ─────────────────────────────────────────────
        Positioned(
          top: 25,
          child: Container(
            width: 55,
            height: 52,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(26),
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
                  right: 13,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: faceDetails,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // العين اليسرى
                Positioned(
                  top: 19,
                  left: 13,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: faceDetails,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // الخد الأيمن
                Positioned(
                  top: 31,
                  right: 6,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // الخد الأيسر
                Positioned(
                  top: 31,
                  left: 6,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // الأنف
                Positioned(
                  top: 27,
                  left: 24,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // الابتسامة
                Positioned(
                  top: 33,
                  left: 20,
                  child: Container(
                    width: 15,
                    height: 7,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: faceDetails, width: 1.4),
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

class _LetterBubble extends StatelessWidget {
  final String letter;
  final Color backgroundColor;
  final Color textColor;

  const _LetterBubble({
    required this.letter,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _PracticeLettersCard extends StatelessWidget {
  final List<String> letters;

  const _PracticeLettersCard({required this.letters});

  @override
  Widget build(BuildContext context) {
    final displayLetters = letters.take(4).toList();

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 175),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: const Color(0xFF511281).withOpacity(0.09),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Stack(
          children: [
            // دائرة بنفسجية خلفية
            Positioned(
              right: -45,
              bottom: -55,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFF511281).withOpacity(0.045),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // دائرة وردية خلفية
            Positioned(
              left: -45,
              top: -55,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6969).withOpacity(0.055),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.record_voice_over_rounded,
                        color: Color(0xFF511281),
                        size: 22,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'حروفي للتدريب',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF222222),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    displayLetters.isEmpty
                        ? 'ابدأ تحديد المستوى لاكتشاف حروفك'
                        : 'تدرّب على هذه الحروف لتحسّن نطقك',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF777777),
                    ),
                  ),

                  const SizedBox(height: 18),

                  if (displayLetters.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(displayLetters.length, (index) {
                        final colors = [
                          const Color(0xFFEDE0FA),
                          const Color(0xFFFFE3E7),
                          const Color(0xFFFFF1C9),
                          const Color(0xFFDDF2EA),
                        ];

                        final textColors = [
                          const Color(0xFF6F2DA8),
                          const Color(0xFFE35F70),
                          const Color(0xFFB47A17),
                          const Color(0xFF2A8D70),
                        ];

                        return _LetterBubble(
                          letter: displayLetters[index],
                          backgroundColor: colors[index % colors.length],
                          textColor: textColors[index % textColors.length],
                        );
                      }),
                    )
                  else
                    const Center(
                      child: Icon(
                        Icons.mic_rounded,
                        size: 45,
                        color: Color(0xFFDCC9EB),
                      ),
                    ),

                  const SizedBox(height: 17),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF511281).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'كل تدريب يقربك من الإتقان',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF6F2DA8),
                          fontWeight: FontWeight.w600,
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
    );
  }
}
