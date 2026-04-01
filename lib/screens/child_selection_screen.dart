import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ChildSession.dart'; 

// ─── Helper: تحويل الأرقام إلى العربية ────────────────
String toArabicNumbers(int num) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return num.toString().replaceAllMapped(
    RegExp(r'\d'),
    (m) => arabicDigits[int.parse(m[0]!)],
  );
}

// ─── الشاشة الرئيسية لاختيار الطفل ────────────────
class ChildSelectionScreen extends StatelessWidget {
  const ChildSelectionScreen({super.key});

  void _onChildSelected(BuildContext context, String childId) {
    ChildSession.currentChildId = childId;
    Navigator.pushNamed(
      context,
      '/child/home', 
      arguments: childId, 
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
            const _ChildSelectionHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('children')
                    .where('parentId', isEqualTo: userId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF511281)),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final String docId = docs[index].id;

                      return _ChildCard(
                        name: data['name'] ?? 'بدون اسم',
                        avatar: data['avatar'] ?? '👦',
                        age: data['age'] ?? 0,
                        level: data['level'] ?? 'مبتدئ',
                        onTap: () => _onChildSelected(context, docId),
                      );
                    },
                  );
                },
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
          const Text('🌵', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            'لا يوجد أطفال مضافين بعد',
            style: TextStyle(
              color: Color(0xFF511281), 
              fontWeight: FontWeight.bold,
              fontSize: 18
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/parent/create-child'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF511281),
              foregroundColor: Colors.white,
            ),
            child: const Text('إضافة طفل الآن'),
          )
        ],
      ),
    );
  }
}

// ─── ويدجت الهيدر ───
class _ChildSelectionHeader extends StatelessWidget {
  const _ChildSelectionHeader();

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
          BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4))
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
          // تم استخدام Icons.arrow_back ليتطابق مع صفحة الإدارة
          _HeaderIconBtn(
            icon: Icons.arrow_back, 
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12), 
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'من سيتعلم اليوم؟',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600),
              ),
              Text(
                'اختر طفلاً للمتابعة',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── زر الأيقونة المخصص (مطابق لصفحة المانجمنت وبدون خلفية بيضاء) ───
class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          // تم حذف الـ decoration (اللون الأبيض الشفاف) كما طلبتِ
          child: Icon(icon, color: Colors.white, size: 25),
        ),
      );
}

// ─── ويدجت بطاقة الطفل ───
class _ChildCard extends StatefulWidget {
  final String name;
  final String avatar;
  final int age;
  final String level;
  final VoidCallback onTap;

  const _ChildCard({
    required this.name,
    required this.avatar,
    required this.age,
    required this.level,
    required this.onTap,
  });

  @override
  State<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<_ChildCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 100)
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000), 
                blurRadius: 10, 
                offset: Offset(0, 3)
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.avatar, style: const TextStyle(fontSize: 62)),
              const SizedBox(height: 12),
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF1A1A1A)
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'العمر: ${toArabicNumbers(widget.age)} سنوات',
                style: const TextStyle(fontSize: 12, color: Color(0xFFFF6969)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6969).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.level,
                  style: const TextStyle(
                    fontSize: 12, 
                    color: Color(0xFFFF6969), 
                    fontWeight: FontWeight.w600
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}