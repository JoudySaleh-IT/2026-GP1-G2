import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final String childId; // ✅ أضيفي هذا المتغير

  const ChildHomeScreen({
    super.key,
    required this.childId,
  }); // ✅ تحديث الـ Constructor

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      // ✅ نراقب بيانات الطفل في Firestore لحظة بلحظة
      stream: FirebaseFirestore.instance
          .collection('children')
          .doc(childId)
          .snapshots(),
      builder: (context, snapshot) {
        // حالة الانتظار
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF511281)),
            ),
          );
        }

        // في حال عدم وجود بيانات
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("عذراً، لم يتم العثور على البيانات")),
          );
        }

        // استخراج البيانات الحقيقية
        var data = snapshot.data!.data() as Map<String, dynamic>;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFFCF9EA),
            body: Column(
              children: [
                // ✅ الهيدر ببيانات حقيقية
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
                        _PlacementTestBanner(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/child/placement-test',
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ── Stats row ببيانات حقيقية ──────────────────────
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

                        // ✅ هدف اليوم ببيانات حقيقية
                        _TodayGoalCard(
                          done: data['todayExercises'] ?? 0,
                          goal: data['todayGoal'] ?? 5, // افتراضي 5 لو مش موجود
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _ChildBottomNav(
              currentRoute: '/child/home',
              childId: childId, // مرري الـ ID للناف بار إذا كنتِ تحتاجينه
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
    showDialog(context: context, builder: (_) => const _ParentPasswordDialog());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
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

          // Logout icon button — left side in RTL
          InkWell(
            onTap: () => _showLogoutDialog(context),
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
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _hasError = false;
  bool _loading = false;

  // ── In a real app, validate against the stored parent password ────────────
  static const String _mockParentPassword = '123456';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _loading = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (_controller.text == _mockParentPassword) {
        Navigator.pop(context); // close dialog
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/parent/dashboard',
          (route) => false,
        );
      } else {
        setState(() {
          _hasError = true;
          _loading = false;
          _controller.clear();
        });
      }
    });
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
              'تحقق من الهوية',
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
              'أدخل كلمة مرور ولي الأمر للعودة إلى حسابه',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              obscureText: _obscure,
              textDirection: TextDirection.ltr,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: const TextStyle(color: Colors.grey),
                errorText: _hasError ? 'كلمة المرور غير صحيحة' : null,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF511281),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
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
          // Cancel
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
          // Confirm
          ElevatedButton(
            onPressed: _loading ? null : _submit,
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
                : const Text('تأكيد'),
          ),
        ],
      ),
    );
  }
}

// ─── Placement Test Banner ────────────────────────────────────────────────────
class _PlacementTestBanner extends StatefulWidget {
  final VoidCallback onTap;
  const _PlacementTestBanner({required this.onTap});

  @override
  State<_PlacementTestBanner> createState() => _PlacementTestBannerState();
}

class _PlacementTestBannerState extends State<_PlacementTestBanner>
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
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6969),
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x44FF6969),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Text
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اختبار تحديد المستوى',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'استكشف مستواك اللغوي!',
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
              // Play icon
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 60),
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
          // Title row
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

          // Progress bar
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

          // Remaining text
          Text(
            'تحتاج $remaining تدريبات لتحقيق الهدف!',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ChildBottomNav extends StatelessWidget {
  final String currentRoute;
  final String childId; // ✅ 1. أضفنا هذا السطر لتعريف المتغير داخل الكلاس

  const _ChildBottomNav({
    required this.currentRoute,
    required this.childId, // ✅ 2. أضفناه هنا ليكون مطلوباً عند استدعاء الكلاس
  });

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
                    arguments: childId, // ✅ 3. نمرر الـ ID لصفحة التمارين
                  ),
                ),
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'الرئيسية',
                  isActive: currentRoute == '/child/home',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/child/home',
                    arguments: childId, // ✅ نمرره لصفحة الرئيسية أيضاً
                  ),
                ),
                _NavItem(
                  icon: Icons.leaderboard_rounded,
                  label: 'المتصدرون',
                  isActive: currentRoute == '/child/leaderboard',
                  onTap: () => Navigator.pushNamed(
                    context,
                    '/child/leaderboard',
                    arguments: childId, // ✅ نمرره لصفحة المتصدرين
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
