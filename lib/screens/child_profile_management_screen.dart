import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'edit_child_profile_screen.dart';

// ─── Mock Data ────────────────────────────────────────────────────────────────
class _WeekDay {
  final String day;
  final int exercises;
  const _WeekDay(this.day, this.exercises);
}

const _weeklyDataMock = [
  _WeekDay('الإثنين', 4),
  _WeekDay('الثلاثاء', 7),
  _WeekDay('الأربعاء', 3),
  _WeekDay('الخميس', 8),
  _WeekDay('الجمعة', 5),
  _WeekDay('السبت', 9),
  _WeekDay('الأحد', 2),
];

const Map<String, dynamic> _letterProgressMock = {
  'ر': {'level': 'مبتدئ', 'completed': 2, 'total': 10},
  'س': {'level': 'متوسط', 'completed': 6, 'total': 10},
  'ق': {'level': 'مبتدئ', 'completed': 1, 'total': 10},
  'ص': {'level': 'متقدم', 'completed': 9, 'total': 10},
  'خ': {'level': 'متوسط', 'completed': 5, 'total': 10},
};

// ─── Main Screen ─────────────────────────────────────────────────────────────
class ChildProfileManagementScreen extends StatefulWidget {
  final String? childId;
  const ChildProfileManagementScreen({super.key, this.childId});

  @override
  State<ChildProfileManagementScreen> createState() =>
      _ChildProfileManagementScreenState();
}

class _ChildProfileManagementScreenState
    extends State<ChildProfileManagementScreen> {
  final AuthService _authService = AuthService();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'حذف ملف الطفل؟',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('سيتم حذف ملف الطفل وجميع بياناته بشكل نهائي.'),
          actions: [
            //  زر "حذف" سيكون في جهة اليمين
            ElevatedButton(
              onPressed: () async {
                try {
                  await _authService.deleteChild(widget.childId!);
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/parent/dashboard',
                      (route) => false,
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('فشل الحذف')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6969),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(), // شكل دائري متناسق مع الداشبورد
                elevation: 2,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text('حذف', style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            //  زر "إلغاء" سيكون في جهة اليسار (نص فقط بدون بوكس)
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey, // لون رمادي هادئ لتقليل التشتيت
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('children')
          .doc(widget.childId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF511281)),
            ),
          );
        }

        var realData = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.data() as Map<String, dynamic>
            : {'name': 'تحميل...', 'avatar': '👤', 'age': 0};

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFFCF9EA),
            body: Column(
              children: [
                _ProfileHeader(
                  childId: widget.childId,
                  onDelete: _confirmDelete,
                  name: realData['name'] ?? 'بدون اسم',
                  avatar: realData['avatar'] ?? '🦁',
                  age: realData['age'] ?? 0,
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    child: ListView(
                      controller: _scrollController,
                      physics:
                          const ClampingScrollPhysics(), // <-- No bounce = no drift
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      children: const [
                        _StatCard(
                          key: ValueKey('stat_exercises'),
                          icon: Icons.menu_book_rounded,
                          title: 'التمارين المنجزة',
                          value: '42',
                          subtitle: 'أداء رائع هذا الشهر',
                        ),
                        SizedBox(height: 12),
                        _StatCard(
                          key: ValueKey('stat_streak'),
                          icon: Icons.emoji_events_rounded,
                          title: 'سلسلة الأيام',
                          value: '12 يوم',
                          subtitle: 'بطل فصيح مستمر',
                        ),
                        SizedBox(height: 12),
                        _ProgressCard(progress: 74),
                        SizedBox(height: 24),
                        Text(
                          'حروف تحتاج تحسين',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF511281),
                          ),
                        ),
                        SizedBox(height: 12),
                        _LetterListTile(
                          key: ValueKey('letter_ر'),
                          letter: 'ر',
                          level: 'مبتدئ',
                          completed: 2,
                          total: 10,
                        ),
                        SizedBox(height: 12),
                        _LetterListTile(
                          key: ValueKey('letter_س'),
                          letter: 'س',
                          level: 'متوسط',
                          completed: 6,
                          total: 10,
                        ),
                        SizedBox(height: 12),
                        _LetterListTile(
                          key: ValueKey('letter_ق'),
                          letter: 'ق',
                          level: 'مبتدئ',
                          completed: 1,
                          total: 10,
                        ),
                        SizedBox(height: 12),
                        _LetterListTile(
                          key: ValueKey('letter_ص'),
                          letter: 'ص',
                          level: 'متقدم',
                          completed: 9,
                          total: 10,
                        ),
                        SizedBox(height: 12),
                        _LetterListTile(
                          key: ValueKey('letter_خ'),
                          letter: 'خ',
                          level: 'متوسط',
                          completed: 5,
                          total: 10,
                        ),
                        SizedBox(height: 12),
                        _WeeklyChartCard(
                          key: ValueKey('weekly_chart'),
                          weeklyData: _weeklyDataMock,
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── UI Components ──────────────────────────────────────────────────────────

class _LetterListTile extends StatelessWidget {
  final String letter;
  final String level;
  final int completed;
  final int total;
  const _LetterListTile({
    super.key,
    required this.letter,
    required this.level,
    required this.completed,
    required this.total,
  });

  Color _getLevelColor(String level) {
    if (level == 'مبتدئ') return const Color(0xFFFF6969);
    if (level == 'متوسط') return const Color(0xFFFFB347);
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _getLevelColor(level);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      level,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '$completed/$total تمارين',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: completed / total,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
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

class _ProfileHeader extends StatelessWidget {
  final String? childId;
  final VoidCallback onDelete;
  final String name;
  final String avatar;
  final int age;
  const _ProfileHeader({
    this.childId,
    required this.onDelete,
    required this.name,
    required this.avatar,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6A3A9E), Color(0xFF511281)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        right: 16,
        left: 16,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(avatar, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$age سنوات | متفاعل',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    EditChildProfileScreen(childId: childId ?? ''),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  const _StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFFF6969)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int progress;
  const _ProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph, size: 18, color: Color(0xFFFF6969)),
              SizedBox(width: 8),
              Text(
                'التقدم الإجمالي',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$progress%',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF6969),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color: const Color(0xFF511281).withOpacity(0.05),
    width: 1.5,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ],
);

class _WeeklyChartCard extends StatelessWidget {
  final List<_WeekDay> weeklyData;
  const _WeeklyChartCard({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'النشاط الأسبوعي',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyData.map((day) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: day.exercises * 10.0,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6969),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        day.day.substring(0, 2),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
