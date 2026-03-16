import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  // دالة لتحويل الأرقام إلى العربية
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
            // ── العنوان العلوي (Header) ──
            _buildHeader(context),

            // ── جسم الصفحة (Body) ──
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('children')
                    .where('parentId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF511281)));
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text('حدث خطأ في تحميل البيانات'));
                  }

                  final childrenDocs = snapshot.data?.docs ?? [];

                  // 1. حالة لا يوجد أطفال (تظهر واجهة الترحيب مع زر الإضافة)
                  if (childrenDocs.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  // 2. حالة وجود طفل (تظهر القائمة ويختفي زر الإضافة)
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // نمرر false لعدم إظهار زر الإضافة في العنوان لأن الطفل موجود فعلاً
                      _buildSectionTitle(context, showAddButton: false), 
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

  // ── واجهة عند عدم وجود أطفال (تظهر زر الإضافة) ──
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🧒', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            const Text(
              'مرحباً بك في فصيح!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF511281)),
            ),
            const SizedBox(height: 8),
            const Text(
              'ابدأ بإضافة طفلك لمتابعة رحلة تعلمه. (يمكنك إضافة طفل واحد فقط)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/parent/create-child'),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('إضافة طفل الآن', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF511281),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── عنوان القسم مع قيد الإضافة ──
  Widget _buildSectionTitle(BuildContext context, {required bool showAddButton}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'ملفات الأطفال',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
        ),
        // يظهر هذا الزر فقط إذا لم يضف المستخدم أي طفل بعد
        if (showAddButton)
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/parent/create-child'),
            icon: const Icon(Icons.add, size: 18, color: Color(0xFF511281)),
            label: const Text('إضافة طفل', style: TextStyle(color: Color(0xFF511281))),
          ),
      ],
    );
  }

  // ── زر التبديل لوضع الطفل ──
  Widget _buildSwitchToChildButton(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/child/home'),
        icon: const Icon(Icons.face_rounded, size: 20),
        label: const Text('التبديل إلى وضع الطفل', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6969),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── الهيدر العلوي (Header) ──
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF511281), Color(0xFF7A3FA8)]),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('لوحة تحكم الأهل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('إدارة تعلم الأطفال', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
              Row(
                children: [
                  _headerIconButton(Icons.settings_outlined, () => Navigator.pushNamed(context, '/parent/settings')),
                  const SizedBox(width: 8),
                  _headerIconButton(Icons.logout_rounded, () => _handleLogout(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  // ── دالة تسجيل الخروج ──
  void _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) Navigator.pushReplacementNamed(context, '/');
    }
  }

  // ── بطاقة الطفل (Child Card) ──
  Widget _buildChildCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final int progress = data['progress'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFFCF9EA),
          child: Text(data['avatar'] ?? '👦', style: const TextStyle(fontSize: 30)),
        ),
        title: Text(data['name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المستوى: ${data['level'] ?? 'مبتدئ'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: const Color(0xFF511281).withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF511281)),
                minHeight: 8,
              ),
            ),
          ],
        ),
        trailing: Text(
          '${toArabicNumbers(progress)}٪',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF511281)),
        ),
        onTap: () => Navigator.pushNamed(context, '/parent/child-profile', arguments: {'childId': docId}),
      ),
    );
  }
}