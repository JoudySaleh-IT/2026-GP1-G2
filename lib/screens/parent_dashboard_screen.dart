import 'package:flutter/material.dart';

// ── Mock Data Model ────────────────────────────────────────────────────────
class ChildProfile {
  final String id;
  final String name;
  final String avatar;
  final String level;
  final int progress;
  final int streak;
  final int exercisesCompleted;
  final String lastActive;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.level,
    required this.progress,
    required this.streak,
    required this.exercisesCompleted,
    required this.lastActive,
  });
}

final List<ChildProfile> mockChildren = [
  const ChildProfile(
    id: '1',
    name: 'أحمد',
    avatar: '🦁',
    level: 'متوسط',
    progress: 65,
    streak: 7,
    exercisesCompleted: 23,
    lastActive: 'منذ ساعتين',
  ),
  const ChildProfile(
    id: '2',
    name: 'فاطمة',
    avatar: '🦊',
    level: 'مبتدئ',
    progress: 35,
    streak: 3,
    exercisesCompleted: 12,
    lastActive: 'منذ يوم',
  ),
  const ChildProfile(
    id: '3',
    name: 'سارة',
    avatar: '🐼',
    level: 'متقدم',
    progress: 85,
    streak: 15,
    exercisesCompleted: 47,
    lastActive: 'منذ ٣٠ دقيقة',
  ),
];

// ── Helper: Western → Arabic numerals ─────────────────────────────────────
String toArabicNumbers(int num) {
  const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return num.toString().replaceAllMapped(
    RegExp(r'\d'),
    (m) => arabic[int.parse(m.group(0)!)],
  );
}

// ── Screen ─────────────────────────────────────────────────────────────────
class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: Column(
          children: [
            // ── Sticky Header ──────────────────────────────────
            _buildHeader(context),

            // ── Scrollable Body ────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Section title + Add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ملفات الأطفال',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF222222),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            '/parent/create-child',
                          ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'إضافة طفل',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF511281),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Children cards list
                    ...mockChildren.map(
                      (child) => _buildChildCard(context, child),
                    ),

                    const SizedBox(height: 24),

                    // Switch to child mode button
                    SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/child/selection'),
                        icon: const Icon(Icons.person, size: 18),
                        label: const Text(
                          'التبديل إلى وضع الطفل',
                          style: TextStyle(fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6969),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header with gradient ───────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
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
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title & subtitle
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'لوحة تحكم الأهل',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'إدارة تعلم الأطفال',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),

              // Settings + Logout
              Row(
                children: [
                  _headerIconButton(
                    icon: Icons.settings_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, '/parent/settings'),
                  ),
                  const SizedBox(width: 4),
                 // ✅ Fix
_headerIconButton(
  icon: Icons.logout_rounded,
  onTap: () async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'تسجيل الخروج',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            color: Color(0xFF511281),
          ),
        ),
        content: const Text(
          'هل أنت متأكد من تسجيل الخروج؟',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            color: Color(0xFF444444),
          ),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          // ── نعم ──
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6969),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
            ),
            child: const Text(
              'نعم',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
          // ── لا ──
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF511281),
              side: const BorderSide(color: Color(0xFF511281)),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 10),
            ),
            child: const Text(
              'لا',
              style: TextStyle(fontFamily: 'Tajawal'),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      );
    }
  },
),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  // ── Child Card ─────────────────────────────────────────────────────────
  Widget _buildChildCard(BuildContext context, ChildProfile child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          '/parent/child-profile',
          arguments: {'childId': child.id},
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF511281).withOpacity(0.1),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Avatar + name + level
                Row(
                  children: [
                    Text(child.avatar, style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222222),
                            ),
                          ),
                          Text(
                            child.level,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Last active badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF511281).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        child.lastActive,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF511281),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Progress bar
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'التقدم',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '${toArabicNumbers(child.progress)}٪',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF511281),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: child.progress / 100,
                        minHeight: 6,
                        backgroundColor: const Color(
                          0xFF511281,
                        ).withOpacity(0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF511281),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
