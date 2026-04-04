import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/services/ChildSession.dart';

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF511281)),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("عذراً، لم يتم العثور على البيانات")),
          );
        }

        var data = snapshot.data!.data() as Map<String, dynamic>;
        final bool hasCompletedPlacement = data['placementDone'] ?? false;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFFCF9EA),
            body: Column(
              children: [
                _ChildHeader(
                  name: data['name'] ?? 'بطل فصيح',
                  avatar: data['avatar'] ?? '🦁',
                  level: data['gradeLevel'] ?? 'مبتدئ',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      children: [
                        // ── Smart banner: يتغير حسب حالة الاختبار ────────────
                        _TestBanner(
                          isReassessment: hasCompletedPlacement,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/child/placement-test',
                            arguments: childId,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Stats row ──────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.local_fire_department,
                                value: (data['streak'] ?? 0).toString(),
                                label: 'المواظبة',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star,
                                value: (data['points'] ?? 0).toString(),
                                label: 'النقاط',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.emoji_events,
                                value: '#${data['rank'] ?? '-'}',
                                label: 'الترتيب',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Today's goal ───────────────────────────────────
                        _TodayGoalCard(
                          done: data['todayExercises'] ?? 0,
                          goal: data['todayGoal'] ?? 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _ChildBottomNav(
              currentRoute: '/child/home',
              childId: childId,
            ),
          ),
        );
      },
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────
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
    // Parent password dialog
    showDialog(context: context, builder: (_) => const _ParentPasswordDialog());
  }

  // ─── UPDATED: Confirmation Dialog for Child Device ────────────────────────
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
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: const [
                Icon(Icons.logout_rounded, color: Color(0xFF511281)),
                SizedBox(width: 8),
                Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF222222),
                  ),
                ),
              ],
            ),
            content: const Text(
              'هل أنت متأكد أنك تريد الخروج والعودة إلى شاشة البداية؟',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                ), // Cancel simply pops the dialog
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  // 1. Capture the Navigator using the dialog's context BEFORE any awaits
                  final nav = Navigator.of(dialogContext, rootNavigator: true);

                  // 2. Clear session data from SharedPreferences
                  await prefs.remove('saved_childId');
                  await prefs.remove('saved_parentId');
                  await prefs.remove('isChildLoggedIn');
                  ChildSession.currentChildId = null;

                  // 3. Navigate away FIRST!
                  // We do NOT call Navigator.pop(). This push will automatically
                  // clear the dialog AND the home screen in one action.
                  nav.pushNamedAndRemoveUntil('/', (route) => false);

                  // 4. Sign out SECOND!
                  await FirebaseAuth.instance.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6969),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text('نعم، خروج'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Smart Logout Logic ──────────────────────────────────────────
  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isChildLoggedIn = prefs.getBool('isChildLoggedIn') ?? false;

    if (isChildLoggedIn) {
      // Flow 1: Child Device (Logged in via 6-digit code)
      // We removed context.mounted check here to prevent silent failures in stateless widgets
      _showChildLogoutConfirmation(context, prefs);
    } else {
      // Flow 2: Parent Device (Logged in from parent dashboard)
      _showLogoutDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A3A9E), Color(0xFF511281)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        right: 16,
        left: 16,
      ),
      child: Row(
        children: [
          // Avatar
          Text(avatar, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 10),

          // Name + level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مرحبا $name!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  level,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          // Logout button
          InkWell(
            onTap: () => _handleLogout(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Parent Password Dialog ───────────────────────────────────────────────────
class _ParentPasswordDialog extends StatefulWidget {
  const _ParentPasswordDialog();

  @override
  State<_ParentPasswordDialog> createState() => _ParentPasswordDialogState();
}

class _ParentPasswordDialogState extends State<_ParentPasswordDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _hasError = false;
  bool _loading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInParent() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _loading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Sign in as parent using email/password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Dismiss the dialog
      if (mounted) navigator.pop();

      // Show success message
      messenger.showSnackBar(
        SnackBar(
          content: const Text(
            'تم التحقق.. جاري العودة لصفحة ولي الأمر',
            style: TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: const Color(0xFF511281),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to parent dashboard and clear all previous routes
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
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          _errorMessage = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'صيغة البريد الإلكتروني غير صحيحة';
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
        title: Row(
          children: const [
            Icon(Icons.lock_rounded, color: Color(0xFF511281), size: 22),
            SizedBox(width: 8),
            Text(
              'تسجيل دخول ولي الأمر',
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
              'للعودة إلى حساب ولي الأمر، يرجى إدخال بياناتك',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Email field
            TextField(
              controller: _emailController,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'البريد الإلكتروني',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
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
            const SizedBox(height: 16),
            // Password field
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
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              side: BorderSide(
                color: const Color(0xFF511281).withOpacity(0.2),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Color(0xFF511281)),
            ),
          ),
          ElevatedButton(
            onPressed: _loading ? null : _signInParent,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6969),
              foregroundColor: Colors.white,
              elevation: 2,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                : const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}

// ─── Smart Test Banner (placement + reassessment in one) ────────────────────
class _TestBanner extends StatefulWidget {
  final bool isReassessment;
  final VoidCallback onTap;
  const _TestBanner({required this.isReassessment, required this.onTap});

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
      begin: 1.0,
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
    final isReassessment = widget.isReassessment;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: isReassessment
                ? const Color(0xFF511281)
                : const Color(0xFFFF6969),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: isReassessment
                    ? const Color(0x44511281)
                    : const Color(0x44FF6969),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isReassessment
                          ? 'إعادة تقييم المستوى'
                          : 'اختبار تحديد المستوى',
                      key: ValueKey(isReassessment),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isReassessment
                          ? 'تحقق من تطورك اللغوي!'
                          : 'استكشف مستواك اللغوي!',
                      key: ValueKey('sub_$isReassessment'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              // Icon
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  isReassessment
                      ? Icons.refresh_rounded
                      : Icons.play_circle_fill,
                  key: ValueKey('icon_$isReassessment'),
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF511281).withOpacity(0.1),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF511281), size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ─── Today's Goal Card ────────────────────────────────────────────────────────
class _TodayGoalCard extends StatelessWidget {
  final int done;
  final int goal;

  const _TodayGoalCard({required this.done, required this.goal});

  @override
  Widget build(BuildContext context) {
    final remaining = goal - done;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF511281).withOpacity(0.1),
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'هدف اليوم',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222222),
                ),
              ),
              Text(
                '$done/$goal',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFFF6969),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / goal,
              minHeight: 8,
              backgroundColor: const Color(0xFFFF6969).withOpacity(0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF6969),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تحتاج $remaining تدريبات لتحقيق الهدف!',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────
class _ChildBottomNav extends StatelessWidget {
  final String currentRoute;
  final String childId;

  const _ChildBottomNav({required this.currentRoute, required this.childId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A3A9E), Color(0xFF511281)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: 'التمارين',
                  isActive: currentRoute == '/child/exercises',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/child/exercises',
                    arguments: childId,
                  ),
                ),
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isActive: currentRoute == '/child/home',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/child/home',
                    arguments: childId,
                  ),
                ),
                _NavItem(
                  icon: Icons.leaderboard_rounded,
                  label: 'المتصدرون',
                  isActive: currentRoute == '/child/leaderboard',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/child/leaderboard',
                    arguments: childId,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFFFF6969) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
