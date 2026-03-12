import 'package:flutter/material.dart';

// ─── Helper: Convert Western digits to Arabic-Indic numerals ────────────────
String toArabicNumbers(int num) {
  const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  return num.toString().replaceAllMapped(
    RegExp(r'\d'),
    (m) => arabicDigits[int.parse(m[0]!)],
  );
}

// ─── Data Model ──────────────────────────────────────────────────────────────
class ChildData {
  final String id;
  final String name;
  final String avatar; // emoji string
  final int age;
  final String level;

  const ChildData({
    required this.id,
    required this.name,
    required this.avatar,
    required this.age,
    required this.level,
  });
}

// ─── Mock Data ───────────────────────────────────────────────────────────────
// In a real app this would come from the parent's account / backend
const List<ChildData> mockChildren = [
  ChildData(id: '1', name: 'أحمد', avatar: '🦁', age: 8, level: 'متوسط'),
  ChildData(id: '2', name: 'فاطمة', avatar: '🦋', age: 6, level: 'مبتدئ'),
  ChildData(id: '3', name: 'عمر', avatar: '🚀', age: 10, level: 'متقدم'),
  ChildData(id: '4', name: 'ليلى', avatar: '🌸', age: 7, level: 'متوسط'),
];

// ─── Screen ──────────────────────────────────────────────────────────────────
class ChildSelectionScreen extends StatelessWidget {
  const ChildSelectionScreen({super.key});

  void _onChildSelected(BuildContext context, String childId) {
    // In the real app, save the selected child to state/provider, then navigate
    Navigator.pushNamed(
      context,
      '/child/home',
      arguments: {'childId': childId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9EA),
      body: Column(
        children: [
          // ── Sticky gradient header ─────────────────────────────────────
          _ChildSelectionHeader(),

          // ── Children grid ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.82, // slightly taller than square
                ),
                itemCount: mockChildren.length,
                itemBuilder: (context, index) {
                  final child = mockChildren[index];
                  return _ChildCard(
                    child: child,
                    onTap: () => _onChildSelected(context, child.id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header Widget ───────────────────────────────────────────────────────────
class _ChildSelectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
          begin: Alignment.centerRight, // RTL: start from right
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
      // Respect the system status bar height
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 12,
        right: 16,
        left: 16,
      ),
      child: Row(
        children: [
          // Back button (arrow points right for RTL → goes "back")
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pushNamed(context, '/parent/dashboard'),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_forward, // RTL back arrow
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Titles
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'من سيتعلم اليوم؟',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
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

// ─── Child Card Widget ───────────────────────────────────────────────────────
class _ChildCard extends StatefulWidget {
  final ChildData child;
  final VoidCallback onTap;

  const _ChildCard({required this.child, required this.onTap});

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
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnim.value, child: child),
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
            border: Border.all(
              color: const Color(0xFF511281).withOpacity(0.08),
              width: 1.5,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Avatar emoji ──────────────────────────────────
              Text(widget.child.avatar, style: const TextStyle(fontSize: 62)),
              const SizedBox(height: 12),

              // ── Name ─────────────────────────────────────────
              Text(
                widget.child.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 5),

              // ── Age — coral color like Figma ──────────────────
              Text(
                'العمر: ${toArabicNumbers(widget.child.age)} سنوات',
                style: const TextStyle(fontSize: 12, color: Color(0xFFFF6969)),
              ),
              const SizedBox(height: 8),

              // ── Level badge ──────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6969).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.child.level,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF6969),
                    fontWeight: FontWeight.w600,
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
