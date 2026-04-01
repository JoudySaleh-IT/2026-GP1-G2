import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ChildSession.dart'; 

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
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF511281)));
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
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
      ),
      boxShadow: [
        BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4))
      ],
    ),
    // 1️⃣ هنا نتحكم في الحجم الكلي للهيدر
    padding: EdgeInsets.only(
      top: MediaQuery.of(context).padding.top + 8, // مساحة علوية بسيطة
      bottom: 12, // مسافة سفلية قليلة لجعله نحيفاً
      right: 16,
      left: 16,
    ),
    // 2️⃣ ابدئي بالـ Row مباشرة واحذفي الـ SafeArea والـ Padding اللي كانوا هنا
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'لوحة تحكم الأهل', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white) // تصغير الخط لـ 18 أجمل
            ),
            Text(
              'إدارة تعلم الأطفال', 
              style: TextStyle(fontSize: 11, color: Colors.white70)
            ),
          ],
        ),
        Row(
          children: [
            _headerIconButton(
              Icons.settings_outlined,
              () => Navigator.pushNamed(context, '/parent/settings'),
            ),
            const SizedBox(width: 8),
            _headerIconButton(
              Icons.logout_rounded,
              () => _handleLogout(context),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _headerIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  // ─── عنوان القسم (يحتوي على زر إضافة طفل) ───
  Widget _buildSectionTitle(BuildContext context, {required bool showAddButton}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('ملفات الأطفال', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (showAddButton)
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/parent/create-child'),
            icon: const Icon(Icons.add, size: 20, color: Color(0xFF511281)),
            label: const Text('إضافة طفل', style: TextStyle(color: Color(0xFF511281), fontWeight: FontWeight.bold)),
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
        label: const Text('التبديل لوضع الطفل', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6969),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final int progress = data['progress'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFFFCF9EA),
          child: Text(data['avatar'] ?? '👦', style: const TextStyle(fontSize: 30)),
        ),
        title: Text(data['name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.bold)),
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
        trailing: Text('${toArabicNumbers(progress)}٪'),
        onTap: () => Navigator.pushNamed(context, '/parent/child-profile', arguments: {'childId': docId}),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    // ... كود تسجيل الخروج كما هو ...
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/parent/login');
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧒', style: TextStyle(fontSize: 80)),
          const Text('مرحباً بك في فصيح!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/parent/create-child'),
            child: const Text('إضافة طفل الآن'),
          ),
        ],
      ),
    );
  }
}