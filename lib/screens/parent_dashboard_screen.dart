import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ChildSession.dart';
import 'style_constants.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  String toArabicNumbers(int num) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return num.toString().replaceAllMapped(
      RegExp(r'\d'),
      (m) => arabic[int.parse(m.group(0)!)],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: Column(
          children: [
            // الهيدر الرشيق (نفس حجم اختيار الطفل)
            _buildHeader(context),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('children')
                    .where('parentId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF511281),
                      ),
                    );
                  }

                  final childrenDocs = snapshot.data?.docs ?? [];

                  if (childrenDocs.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSectionTitle(context, showAddButton: true),
                      const SizedBox(height: 12),

                      ...childrenDocs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildChildCard(context, doc.id, data);
                      }),

                      const SizedBox(height: 24),
                      _buildSwitchToChildButton(context),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      decoration: FaseehStyle.headerDecoration,
      padding: FaseehStyle.getStandardPadding(context),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('parents')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                String parentName = '';

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  parentName = data?['fullName'] ?? '';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parentName.isNotEmpty ? 'أهلاً $parentName' : 'أهلاً',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const Text(
                      'إدارة تعلم الأطفال',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () =>
                    Navigator.pushNamed(context, '/parent/settings'),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => _handleLogout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Update _headerIconButton to match the EXACT size and style of _ChildHeader logout button
  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
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
        child: Icon(icon, color: Colors.white, size: 18), // size 18, not 22
      ),
    );
  }

  // ─── عنوان القسم (يحتوي على زر إضافة طفل) ───
  Widget _buildSectionTitle(
    BuildContext context, {
    required bool showAddButton,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'ملفات الأطفال',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (showAddButton)
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/parent/create-child'),
            icon: const Icon(Icons.add, size: 20, color: Color(0xFF511281)),
            label: const Text(
              'إضافة طفل',
              style: TextStyle(
                color: Color(0xFF511281),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  // ... (باقي الدوال: _buildSwitchToChildButton, _buildChildCard, _handleLogout, _buildEmptyState بنفس الكود السابق)

  Widget _buildSwitchToChildButton(BuildContext context) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/parent/select-child'),
        icon: const Icon(Icons.swap_horiz_rounded),
        label: const Text(
          'التبديل لوضع الطفل',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6969),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildChildCard(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final int progress = data['progress'] ?? 0;
    // 1. 👈 استخراج حالة اكتمال الاختبار من قاعدة البيانات
    final bool hasCompletedPlacement = data['placementDone'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFFCF9EA),
          child: Text(
            data['avatar'] ?? '👦',
            style: const TextStyle(fontSize: 30),
          ),
        ),
        title: Text(
          data['name'] ?? 'بدون اسم',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // 2. 👈 تحديث واجهة المستوى بناءً على حالة الاختبار مع ألوان ديناميكية
            Text(
              hasCompletedPlacement
                  ? 'المستوى: ${data['level'] ?? 'مبتدئ'} 🌟'
                  : 'لم يتم تحديد المستوى ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                // إذا لم يكمل الاختبار، يظهر باللون الأحمر/البرتقالي للتنبيه، وإلا باللون البنفسجي
                color: hasCompletedPlacement
                    ? const Color(0xFF511281)
                    : const Color.fromARGB(147, 255, 105, 105),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: const Color(0xFF511281).withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF511281),
                ),
                minHeight: 8,
              ),
            ),
          ],
        ),
        trailing: Text('${toArabicNumbers(progress)}٪'),
        onTap: () => Navigator.pushNamed(
          context,
          '/parent/child-profile',
          arguments: {'childId': docId},
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
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

          // ── 1. إضافة خاصية التباعد بين الأزرار ──
          actionsAlignment: MainAxisAlignment.spaceBetween,

          actions: [
            // ── 2. زر تسجيل الخروج (سيكون في جهة اليمين) ──
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (ctx.mounted) {
                  Navigator.of(
                    ctx,
                    rootNavigator: true,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6969),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(), // حواف دائرية بالكامل
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

            // ── 3. زر الإلغاء (سيكون في جهة اليسار - نص فقط بدون بوكس) ──
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey, // لون هادئ لتقليل التشتيت
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧒', style: TextStyle(fontSize: 80)),
          const Text(
            'مرحباً بك في فصيح!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/parent/create-child'),
            child: const Text('إضافة طفل الآن'),
          ),
        ],
      ),
    );
  }
}
