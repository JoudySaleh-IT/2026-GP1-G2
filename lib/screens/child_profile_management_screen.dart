import 'package:flutter/material.dart';

// ─── Mock Data ────────────────────────────────────────────────────────────────
class _WeekDay {
  final String day;
  final int exercises;
  const _WeekDay(this.day, this.exercises);
}

const _name = 'أحمد';
const _avatar = '🦁';
const _age = 10;
const _level = 'متوسط';
const _progress = 65;
const _streak = 7;
const _exercisesCompleted = 23;
const _weeklyData = [
  _WeekDay('الإثنين', 3),
  _WeekDay('الثلاثاء', 5),
  _WeekDay('الأربعاء', 2),
  _WeekDay('الخميس', 4),
  _WeekDay('الجمعة', 6),
  _WeekDay('السبت', 3),
  _WeekDay('الأحد', 0),
];

// ─── Screen ──────────────────────────────────────────────────────────────────
class ChildProfileManagementScreen extends StatefulWidget {
  final String? childId;
  const ChildProfileManagementScreen({super.key, this.childId});

  @override
  State<ChildProfileManagementScreen> createState() =>
      _ChildProfileManagementScreenState();
}

class _ChildProfileManagementScreenState
    extends State<ChildProfileManagementScreen> {
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
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          content: const Text(
            'لا يمكن التراجع عن هذا الإجراء. سيتم حذف ملف الطفل وجميع بياناته بشكل نهائي.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                side: BorderSide(
                  color: const Color(0xFF511281).withOpacity(0.2),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'إلغاء',
                style: TextStyle(color: Color(0xFF511281)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/parent/dashboard',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6969),
                foregroundColor: Colors.white,
                elevation: 3,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: Column(
          children: [
            _ProfileHeader(childId: widget.childId, onDelete: _confirmDelete),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ── التمارين ──────────────────────────────────────
                    _StatCard(
                      icon: Icons.menu_book_rounded,
                      title: 'التمارين',
                      value: '$_exercisesCompleted',
                      subtitle: 'تم إكمالها',
                    ),
                    const SizedBox(height: 12),

                    // ── سلسلة الأيام ──────────────────────────────────
                    _StatCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'سلسلة الأيام',
                      value: '$_streak أيام',
                      subtitle: 'السلسلة الحالية',
                    ),
                    const SizedBox(height: 12),

                    // ── التقدم ────────────────────────────────────────
                    _ProgressCard(progress: _progress),
                    const SizedBox(height: 16),

                    // ── النشاط الأسبوعي ───────────────────────────────
                    _WeeklyChartCard(weeklyData: _weeklyData),
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
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String? childId;
  final VoidCallback onDelete;
  const _ProfileHeader({required this.childId, required this.onDelete});

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
          _HeaderIconBtn(
            icon: Icons.arrow_forward,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 10),
          Text(_avatar, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$_age سنوات • المستوى $_level',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          _HeaderIconBtn(
            icon: Icons.edit_outlined,
            onTap: () => Navigator.pushNamed(
              context,
              '/parent/child-profile/edit',
              arguments: {'childId': childId ?? '1'},
            ),
          ),
          const SizedBox(width: 4),
          _HeaderIconBtn(icon: Icons.delete_outline_rounded, onTap: onDelete),
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
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

// ─── Stat Card — vertical layout matching Figma ───────────────────────────────
// Layout: [icon  title] at top-right, big number below, subtitle below number
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // RTL: start = right
        children: [
          // ── Top row: title + icon ────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, size: 16, color: const Color(0xFFFF6969)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Big value ────────────────────────────────────────
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),

          // ── Subtitle ─────────────────────────────────────────
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }
}

// ─── Progress Card — number above bar ────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final int progress;
  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // RTL: start = right
        children: [
          // ── Top row: title + icon ────────────────────────────
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.mic, size: 16, color: Color(0xFFFF6969)),
              SizedBox(width: 6),
              Text(
                'التقدم',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Percentage number ────────────────────────────────
          Text(
            '$progress%',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),

          // ── Progress bar below number ────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
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

// ─── Shared card decoration ───────────────────────────────────────────────────
BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(
    color: const Color(0xFF511281).withOpacity(0.08),
    width: 1.5,
  ),
  boxShadow: const [
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ],
);

// ─── Weekly Chart Card ────────────────────────────────────────────────────────
class _WeeklyChartCard extends StatelessWidget {
  final List<_WeekDay> weeklyData;
  const _WeeklyChartCard({required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final maxVal = weeklyData
        .map((e) => e.exercises)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // RTL: start = right
        children: [
          const Text(
            'النشاط الأسبوعي',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 16),

          // Bars + Y-axis
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-axis
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(maxVal + 1, (i) {
                      return Text(
                        '${maxVal - i}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFBBBBBB),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),

                // Bars with dashed grid
                Expanded(
                  child: CustomPaint(
                    painter: _GridPainter(steps: maxVal),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: weeklyData.map((day) {
                        final ratio = maxVal == 0
                            ? 0.0
                            : day.exercises / maxVal;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (day.exercises > 0)
                                  Text(
                                    '${day.exercises}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFFFF6969),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                const SizedBox(height: 3),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOut,
                                  height: ratio * 130,
                                  decoration: BoxDecoration(
                                    color: day.exercises == 0
                                        ? const Color(0xFFEEEEEE)
                                        : const Color(0xFFFF6969),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(5),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.only(right: 26),
            child: const Divider(
              height: 8,
              thickness: 1,
              color: Color(0xFFEEEEEE),
            ),
          ),

          // X-axis: full day names, rotated
          Padding(
            padding: const EdgeInsets.only(right: 26, top: 4),
            child: Row(
              children: weeklyData.map((day) {
                return Expanded(
                  child: Transform.rotate(
                    angle: -0.45,
                    child: Text(
                      day.day,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ─── Dashed grid painter ──────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final int steps;
  const _GridPainter({required this.steps});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEEEEEE)
      ..strokeWidth = 1;

    for (int i = 0; i <= steps; i++) {
      final y = size.height * (1 - i / steps);
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(Offset(x, y), Offset(x + 4, y), paint);
        x += 8;
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.steps != steps;
}
