import 'dart:math';
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

class ChildSelectionScreen extends StatelessWidget {
  const ChildSelectionScreen({super.key});

  void _showPairingDialog(
    BuildContext context,
    String childId,
    String childName,
  ) async {
    final String pairingCode = (Random().nextInt(900000) + 100000).toString();
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    try {
      await FirebaseFirestore.instance.collection('pairing_codes').add({
        'code': pairingCode,
        'parentId': userId,
        'childId': childId,
        'childName': childName,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': DateTime.now().add(const Duration(minutes: 10)),
      });

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('ربط جهاز جديد', textAlign: TextAlign.center),
            content: ConstrainedBox(
              // Prevents the dialog from stretching too wide on tablets
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'أدخل هذا الكود في جهاز $childName:',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF511281),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      pairingCode,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Color(0xFF511281),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'هذا الكود صالح لمدة ١٠ دقائق فقط',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'تم',
                  style: TextStyle(color: Color(0xFF511281)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('حدث خطأ في إنشاء الكود')));
    }
  }

  void _onChildSelected(BuildContext context, String childId) {
    ChildSession.currentChildId = childId;
    Navigator.pushNamed(context, '/child/home', arguments: childId);
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Determine if we are on a tablet (usually width > 600)
    bool isTablet = screenWidth > 600;

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
                      child: CircularProgressIndicator(
                        color: Color(0xFF511281),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return _buildEmptyState(context);

                  return GridView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? screenWidth * 0.1 : 24,
                      vertical: 24,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      // 3 columns for tablets, 2 for phones
                      crossAxisCount: isTablet ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final String docId = docs[index].id;
                      final String name = data['name'] ?? 'بدون اسم';

                      return _ChildCard(
                        name: name,
                        avatar: data['avatar'] ?? '👦',
                        age: data['age'] ?? 0,
                        level: data['level'] ?? 'مبتدئ',
                        onTap: () => _onChildSelected(context, docId),
                        onPairingTap: () =>
                            _showPairingDialog(context, docId, name),
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
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200, // Capping the button width
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/parent/create-child'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF511281),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إضافة طفل الآن'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header Widget ───
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
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 16, // Increased slightly for tablet balance
        right: 20,
        left: 20,
      ),
      child: Row(
        children: [
          _HeaderIconBtn(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'من سيتعلم اليوم؟',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20, // Slightly larger for clarity
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'اختر طفلاً للمتابعة',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 40,
      height: 40,
      child: Icon(icon, color: Colors.white, size: 28),
    ),
  );
}

// ─── Child Card Widget ───
class _ChildCard extends StatefulWidget {
  final String name;
  final String avatar;
  final int age;
  final String level;
  final VoidCallback onTap;
  final VoidCallback onPairingTap;

  const _ChildCard({
    required this.name,
    required this.avatar,
    required this.age,
    required this.level,
    required this.onTap,
    required this.onPairingTap,
  });

  @override
  State<_ChildCard> createState() => _ChildCardState();
}

class _ChildCardState extends State<_ChildCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Using a flexible layout for the avatar so it doesn't
                      // push the text out on smaller tablets
                      Flexible(
                        child: Text(
                          widget.avatar,
                          style: const TextStyle(fontSize: 60),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'العمر: ${toArabicNumbers(widget.age)} سنوات',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFF6969),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6969).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.level,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFF6969),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: const Icon(
                    Icons.phonelink_setup,
                    color: Color(0xFF511281),
                    size: 22,
                  ),
                  onPressed: widget.onPairingTap,
                  tooltip: 'ربط بجهاز آخر',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
