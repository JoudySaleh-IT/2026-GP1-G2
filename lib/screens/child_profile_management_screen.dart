import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'edit_child_profile_screen.dart';
import 'style_constants.dart';
import '../utils/arabic_numbers.dart';
import '../widgets/child_store_avatar.dart';
import '../services/parent_child_progress_service.dart';

String _practiceOutcomeLabel(String outcome) {
  switch (outcome) {
    case 'winner':
      return 'فوز';

    case 'tie':
      return 'تعادل';

    case 'loser':
      return 'لم يفز';

    default:
      return 'مشاركة';
  }
}

String _formatParentActivityDate(Timestamp? timestamp) {
  if (timestamp == null) {
    return '';
  }

  final DateTime nowKsa = DateTime.now().toUtc().add(const Duration(hours: 3));

  final DateTime eventKsa = timestamp.toDate().toUtc().add(
    const Duration(hours: 3),
  );

  final DateTime today = DateTime(nowKsa.year, nowKsa.month, nowKsa.day);

  final DateTime eventDay = DateTime(
    eventKsa.year,
    eventKsa.month,
    eventKsa.day,
  );

  final int daysAgo = today.difference(eventDay).inDays;

  if (daysAgo == 0) {
    return 'اليوم';
  }

  if (daysAgo == 1) {
    return 'أمس';
  }

  if (daysAgo >= 2 && daysAgo <= 6) {
    return 'قبل ${toArabicDigits(daysAgo)} أيام';
  }

  return '${toArabicDigits(eventKsa.day)}/'
      '${toArabicDigits(eventKsa.month)}/'
      '${toArabicDigits(eventKsa.year)}';
}

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

  final ParentChildProgressService _progressService =
      ParentChildProgressService();

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

          // ── 1. توزيع الأزرار واحد يمين وواحد يسار ──
          actionsAlignment: MainAxisAlignment.spaceBetween,

          actions: [
            // ── 2. زر "حذف" (جهة اليمين) ──
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
                  // Show the global snackbar
                  NotificationService.showSuccessSnackBar(
                    'تم حذف ملف الطفل الشخصي بنجاح!',
                  );
                } catch (e) {
                  NotificationService.showErrorSnackBar('فشل الحذف');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6969),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(), // شكل دائري (Rounded)
                elevation: 0, // ليكون مظهره أنظف
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'حذف',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),

            // ── 3. زر "إلغاء" (جهة اليسار) ──
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey, // لون رمادي لتقليل التشتيت
                padding: const EdgeInsets.symmetric(horizontal: 20),
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

        final String firstName = (realData['firstName'] ?? '')
            .toString()
            .trim();

        final String lastName = (realData['lastName'] ?? '').toString().trim();

        final String nickname = (realData['nickname'] ?? '').toString().trim();

        final String legacyName = (realData['name'] ?? '').toString().trim();

        final String fullName = [
          firstName,
          lastName,
        ].where((part) => part.isNotEmpty).join(' ');

        final String displayName = nickname.isNotEmpty
            ? nickname
            : firstName.isNotEmpty
            ? firstName
            : legacyName.isNotEmpty
            ? legacyName
            : 'بدون اسم';

        final String secondaryName = fullName.isNotEmpty
            ? fullName
            : legacyName;

        final progressSummary = _progressService.buildSummary(realData);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFFCF9EA),
            body: Column(
              children: [
                _ProfileHeader(
                  childId: widget.childId,
                  onDelete: _confirmDelete,
                  name: displayName,
                  fullName: secondaryName,
                  avatar: realData['avatar'] ?? '🦁',
                  age: realData['age'] ?? 0,
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    child: ListView(
                      controller: _scrollController,
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      children: [
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: widget.childId == null
                              ? null
                              : _progressService.watchLastSevenDays(
                                  widget.childId!,
                                ),
                          builder: (context, activitySnapshot) {
                            final docs = activitySnapshot.data?.docs ?? [];

                            final int weeklyActivity = docs.length;

                            final bool activityLoading =
                                activitySnapshot.connectionState ==
                                ConnectionState.waiting;

                            final weeklyDays = _buildWeeklyActivityDays(docs);

                            return Column(
                              children: [
                                _ParentQuickOverview(
                                  summary: progressSummary,
                                  weeklyActivity: weeklyActivity,
                                  activityLoading: activityLoading,
                                ),

                                const SizedBox(height: 20),

                                _ParentWeeklyActivityCard(
                                  days: weeklyDays,
                                  loading: activityLoading,
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        _LetterJourneySummaryCard(summary: progressSummary),

                        if (progressSummary.placementDone) ...[
                          const SizedBox(height: 24),

                          _DetailedLetterProgressSection(
                            summary: progressSummary,
                          ),
                        ],

                        const SizedBox(height: 20),

                        if (widget.childId != null) ...[
                          const SizedBox(height: 24),

                          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _progressService.watchRecentActivity(
                              widget.childId!,
                            ),
                            builder: (context, recentSnapshot) {
                              final docs = recentSnapshot.data?.docs ?? [];

                              final bool loading =
                                  recentSnapshot.connectionState ==
                                  ConnectionState.waiting;

                              return _ParentRecentActivitySection(
                                docs: docs,
                                loading: loading,
                              );
                            },
                          ),
                        ],

                        const SizedBox(height: 20),
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

class _ParentQuickOverview extends StatelessWidget {
  final ParentChildProgressSummary summary;
  final int weeklyActivity;
  final bool activityLoading;

  const _ParentQuickOverview({
    required this.summary,
    required this.weeklyActivity,
    required this.activityLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'نظرة سريعة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF511281),
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _ParentMiniStatCard(
                icon: Icons.local_fire_department_rounded,
                title: 'سلسلة الأيام',
                value: '${toArabicDigits(summary.streak)} يوم',
                color: const Color(0xFFFF6969),
                background: const Color(0xFFFFF0F0),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _ParentMiniStatCard(
                icon: Icons.workspace_premium_rounded,
                title: 'الحروف المتقنة',
                value: '${toArabicDigits(summary.masteredLetters)} / ٦',
                color: const Color(0xFF5CB88A),
                background: const Color(0xFFF0F9F4),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _ParentMiniStatCard(
                icon: Icons.menu_book_rounded,
                title: 'آخر ٧ أيام',
                value: activityLoading
                    ? '...'
                    : '${toArabicDigits(weeklyActivity)} تمارين',
                color: const Color(0xFF7B4AAD),
                background: const Color(0xFFF6F0FF),
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: _ParentMiniStatCard(
                icon: Icons.star_rounded,
                title: 'مجموع النقاط',
                value: toArabicDigits(summary.lifetimePoints),
                color: const Color(0xFFF1A340),
                background: const Color(0xFFFFF8E8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ParentMiniStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final Color background;

  const _ParentMiniStatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.14), width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: color),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 2),

          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10.5,
              color: Color(0xFF777777),
            ),
          ),
        ],
      ),
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
                      '${toArabicDigits('$completed/$total')} تمارين',
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
  final String fullName;
  final String avatar;
  final int age;

  const _ProfileHeader({
    this.childId,
    required this.onDelete,
    required this.name,
    required this.fullName,
    required this.avatar,
    required this.age,
  });

  String formatAge(int age) {
    final arabicAge = toArabicDigits(age);

    // فصيح يستهدف عمر 5–13
    return age >= 11 ? '$arabicAge سنة' : '$arabicAge سنوات';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: FaseehStyle.headerDecoration,
      padding: FaseehStyle.getStandardPadding(
        context,
      ), // top: status+8, bottom:12, left/right:20
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back button – standard IconButton (size 24, tap area ~48)
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          // Avatar – larger to fit the bigger header
          // Child avatar from Firebase
          if (childId != null && childId!.isNotEmpty)
            ChildStoreAvatar(
              childId: childId!,
              fallbackAvatar: avatar,
              size: 56,
            )
          else
            Text(avatar, style: const TextStyle(fontSize: 32)),

          const SizedBox(width: 12), const SizedBox(width: 12),
          // Text column – bigger fonts (18 / 14) to match _EditHeader
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18, // matched with _EditHeader
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                if (fullName.isNotEmpty && fullName != name)
                  Text(
                    fullName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                Text(
                  formatAge(age),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
          // Edit button – standard IconButton
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditChildProfileScreen(childId: childId ?? ''),
                ),
              );
            },
          ),
          // Delete button – standard IconButton
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
      padding: FaseehStyle.getStandardPadding(context), // <--- Use this,
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
            toArabicDigits('$progress٪'),
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

class _LetterJourneySummaryCard extends StatelessWidget {
  final ParentChildProgressSummary summary;

  const _LetterJourneySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF511281).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.route_rounded,
                  size: 20,
                  color: Color(0xFF511281),
                ),
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Text(
                  'رحلة الحروف',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF511281),
                  ),
                ),
              ),

              if (summary.placementDone)
                Text(
                  'أتقن '
                  '${toArabicDigits(summary.masteredLetters)} '
                  'من ٦',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF777777),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          if (!summary.placementDone)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Text(
                'بانتظار إكمال اختبار تحديد المستوى لعرض رحلة الحروف.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  height: 1.5,
                  color: Color(0xFF777777),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: summary.letters.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 9,
                mainAxisSpacing: 10,
                childAspectRatio: 0.92,
              ),
              itemBuilder: (context, index) {
                return _ParentLetterJourneyItem(
                  progress: summary.letters[index],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ParentLetterJourneyItem extends StatelessWidget {
  final ParentLetterProgress progress;

  const _ParentLetterJourneyItem({required this.progress});

  String _levelLabel(String level) {
    switch (level) {
      case 'beginner':
        return 'سهل';

      case 'intermediate':
        return 'متوسط';

      case 'advanced':
        return 'صعب';

      default:
        return '';
    }
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'beginner':
        return const Color(0xFF65A97D);

      case 'intermediate':
        return const Color(0xFFF1A340);

      case 'advanced':
        return const Color(0xFFFF6969);

      default:
        return const Color(0xFFAAAAAA);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool mastered = progress.state == ParentLetterState.mastered;

    final bool notStarted = progress.state == ParentLetterState.notStarted;

    final Color color = mastered
        ? const Color(0xFF5CB88A)
        : notStarted
        ? const Color(0xFFAAA7AE)
        : _levelColor(progress.currentLevel);

    final String status;

    final String detail;

    if (mastered) {
      status = 'متقن';

      detail = progress.masteredByPlacement ? 'من التقييم' : 'مكتمل';
    } else if (notStarted) {
      status = 'لم يبدأ';

      detail = 'يبدأ من ${_levelLabel(progress.startingLevel)}';
    } else {
      status = 'قيد التدريب';

      detail = _levelLabel(progress.currentLevel);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(mastered ? 0.09 : 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.18)),
            ),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Text(
                    progress.letter,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF511281),
                    ),
                  ),

                  if (mastered)
                    Positioned(
                      left: -4,
                      top: -4,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 7),

          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            detail,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 8.5,
              height: 1.2,
              color: Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detailed Letter Progress
// ─────────────────────────────────────────────────────────────────────────────

String _parentLevelLabel(String level) {
  switch (level) {
    case 'beginner':
      return 'سهل';

    case 'intermediate':
      return 'متوسط';

    case 'advanced':
      return 'صعب';

    default:
      return '';
  }
}

Color _parentLevelColor(String level) {
  switch (level) {
    case 'beginner':
      return const Color(0xFF65A97D);

    case 'intermediate':
      return const Color(0xFFF1A340);

    case 'advanced':
      return const Color(0xFFFF6969);

    default:
      return const Color(0xFFAAAAAA);
  }
}

class _DetailedLetterProgressSection extends StatelessWidget {
  final ParentChildProgressSummary summary;

  const _DetailedLetterProgressSection({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'تفاصيل التقدم',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF511281),
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'تابع مستوى الاستماع والنطق لكل حرف',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11.5,
            color: Color(0xFF777777),
          ),
        ),

        const SizedBox(height: 14),

        ...summary.letters.map(
          (letter) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DetailedLetterProgressCard(progress: letter),
          ),
        ),
      ],
    );
  }
}

class _DetailedLetterProgressCard extends StatelessWidget {
  final ParentLetterProgress progress;

  const _DetailedLetterProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final bool mastered = progress.state == ParentLetterState.mastered;

    final bool notStarted = progress.state == ParentLetterState.notStarted;

    final Color accentColor = mastered
        ? const Color(0xFF5CB88A)
        : notStarted
        ? const Color(0xFF9C99A0)
        : _parentLevelColor(progress.currentLevel);

    final String statusText;

    if (mastered) {
      statusText = 'متقن';
    } else if (notStarted) {
      statusText = 'لم يبدأ';
    } else {
      statusText = 'قيد التدريب';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: accentColor.withOpacity(0.15), width: 1.4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================================================
          // HEADER
          // =========================================================
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withOpacity(0.14)),
                ),
                child: Text(
                  progress.letter,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF511281),
                    height: 1,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'حرف ${progress.letter}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF333333),
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      statusText,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  progress.masteredByPlacement
                      ? 'من التقييم'
                      : _parentLevelLabel(progress.currentLevel),
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // =========================================================
          // MASTERED DIRECTLY FROM PLACEMENT
          // =========================================================
          if (progress.masteredByPlacement) ...[
            _ParentProgressMessage(
              icon: Icons.workspace_premium_rounded,
              text:
                  'أتقن هذا الحرف من اختبار تحديد المستوى بنتيجة '
                  '${toArabicDigits(progress.placementScore)}٪',
              color: const Color(0xFF5CB88A),
            ),
          ] else ...[
            // =======================================================
            // DIFFICULTY JOURNEY
            // =======================================================
            const Text(
              'مسار الصعوبة',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF666666),
              ),
            ),

            const SizedBox(height: 9),

            _ParentDifficultyJourney(progress: progress),

            const SizedBox(height: 16),

            // =======================================================
            // NOT STARTED
            // =======================================================
            if (notStarted)
              _ParentProgressMessage(
                icon: Icons.schedule_rounded,
                text:
                    'لم يبدأ تمارين هذا الحرف بعد. '
                    'سيبدأ من المستوى '
                    '${_parentLevelLabel(progress.startingLevel)}.',
                color: const Color(0xFF888888),
              )
            else ...[
              // =====================================================
              // LISTENING
              // =====================================================
              _ParentSkillProgressRow(
                icon: Icons.headphones_rounded,
                title: 'الاستماع',
                value: progress.listeningScore == null
                    ? 'لم يبدأ'
                    : '${toArabicDigits(progress.listeningScore!)}/٨',
                status: progress.listeningPassed
                    ? 'مكتمل'
                    : progress.listeningScore == null
                    ? 'لم يبدأ'
                    : 'يحتاج تدريب',
                color: const Color(0xFF7B4AAD),
                completed: progress.listeningPassed,
              ),

              const SizedBox(height: 9),

              // =====================================================
              // SPEAKING
              // =====================================================
              _ParentSkillProgressRow(
                icon: Icons.mic_rounded,
                title: 'النطق',
                value: _speakingValue(progress),
                status: _speakingStatus(progress),
                color: const Color(0xFF5CB88A),
                completed: progress.pronunciationPassed,
                locked:
                    !progress.listeningPassed &&
                    progress.pronunciationScore == null,
              ),

              const SizedBox(height: 12),

              _ParentProgressMessage(
                icon: mastered
                    ? Icons.check_circle_rounded
                    : Icons.arrow_forward_rounded,
                text: _nextStepMessage(progress),
                color: mastered ? const Color(0xFF5CB88A) : accentColor,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _speakingValue(ParentLetterProgress progress) {
    final int? score = progress.pronunciationScore;

    if (score == null) {
      return progress.listeningPassed ? 'جاهز للبدء' : '—';
    }

    final int? correct = progress.pronunciationCorrectCount;

    if (correct == null) {
      return toArabicDigits('$score٪');
    }

    return '${toArabicDigits('$score٪')}  •  '
        '${toArabicDigits(correct)}/٨';
  }

  String _speakingStatus(ParentLetterProgress progress) {
    if (progress.pronunciationPassed) {
      return 'مكتمل';
    }

    if (!progress.listeningPassed && progress.pronunciationScore == null) {
      return 'مغلق حتى اجتياز الاستماع';
    }

    if (progress.pronunciationScore == null) {
      return 'لم يبدأ';
    }

    return 'يحتاج تدريب';
  }

  String _nextStepMessage(ParentLetterProgress progress) {
    if (progress.state == ParentLetterState.mastered) {
      return 'أكمل جميع مستويات هذا الحرف بنجاح.';
    }

    final String level = _parentLevelLabel(progress.currentLevel);

    if (!progress.listeningPassed) {
      return 'الخطوة التالية: اجتياز تمارين الاستماع في المستوى $level.';
    }

    if (!progress.pronunciationPassed) {
      if (progress.pronunciationScore == null) {
        return 'الخطوة التالية: بدء تمارين النطق في المستوى $level.';
      }

      return 'الخطوة التالية: مواصلة التدريب على النطق في المستوى $level.';
    }

    return 'استمر في التقدم إلى المستوى التالي.';
  }
}

class _ParentDifficultyJourney extends StatelessWidget {
  final ParentLetterProgress progress;

  const _ParentDifficultyJourney({required this.progress});

  @override
  Widget build(BuildContext context) {
    final List<String> levels = progress.startingLevel == 'beginner'
        ? const ['beginner', 'intermediate', 'advanced']
        : const ['intermediate', 'advanced'];

    return Row(
      textDirection: TextDirection.rtl,
      children: List.generate(levels.length, (index) {
        final String level = levels[index];

        final Color color = _parentLevelColor(level);

        final bool completed =
            progress.state == ParentLetterState.mastered ||
            index < progress.completedRequiredLevels;

        final bool current = !completed && level == progress.currentLevel;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: completed
                      ? color.withOpacity(0.12)
                      : current
                      ? color.withOpacity(0.08)
                      : const Color(0xFFF5F4F6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: completed || current
                        ? color.withOpacity(0.7)
                        : const Color(0xFFD7D4DA),
                    width: current ? 2 : 1.3,
                  ),
                ),
                child: Icon(
                  completed
                      ? Icons.check_rounded
                      : current
                      ? Icons.flag_rounded
                      : Icons.lock_outline_rounded,
                  size: 18,
                  color: completed || current ? color : const Color(0xFFAAA7AE),
                ),
              ),

              const SizedBox(height: 5),

              Text(
                _parentLevelLabel(level),
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 9.5,
                  fontWeight: completed || current
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: completed || current ? color : const Color(0xFF99969D),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ParentActivityDay {
  final DateTime date;

  final String label;

  final int listening;
  final int speaking;
  final int practiceTogether;

  const _ParentActivityDay({
    required this.date,
    required this.label,
    required this.listening,
    required this.speaking,
    required this.practiceTogether,
  });

  int get total => listening + speaking + practiceTogether;
}

class _ParentSkillProgressRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String status;
  final Color color;
  final bool completed;
  final bool locked;

  const _ParentSkillProgressRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.status,
    required this.color,
    required this.completed,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color displayColor = locked ? const Color(0xFFAAAAAA) : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: displayColor.withOpacity(0.055),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: displayColor.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              shape: BoxShape.circle,
            ),
            child: Icon(
              locked ? Icons.lock_outline_rounded : icon,
              size: 19,
              color: displayColor,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 9.5,
                    color: completed ? const Color(0xFF55AD75) : displayColor,
                  ),
                ),
              ],
            ),
          ),

          Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: locked ? const Color(0xFFAAAAAA) : const Color(0xFF444444),
            ),
          ),

          if (completed) ...[
            const SizedBox(width: 6),

            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF55AD75),
              size: 17,
            ),
          ],
        ],
      ),
    );
  }
}

List<_ParentActivityDay> _buildWeeklyActivityDays(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  // Current time in Saudi Arabia.
  final DateTime nowKsa = DateTime.now().toUtc().add(const Duration(hours: 3));

  final DateTime today = DateTime(nowKsa.year, nowKsa.month, nowKsa.day);

  const dayLabels = {
    DateTime.monday: 'إث',
    DateTime.tuesday: 'ثل',
    DateTime.wednesday: 'أر',
    DateTime.thursday: 'خم',
    DateTime.friday: 'جم',
    DateTime.saturday: 'سب',
    DateTime.sunday: 'أح',
  };

  final Map<String, Map<String, int>> activityByDay = {};

  // Prepare all seven days first,
  // including days with zero activity.
  for (int i = 6; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));

    final key = _activityDateKey(date);

    activityByDay[key] = {
      'listening': 0,
      'speaking': 0,
      'practice_together': 0,
    };
  }

  // Count real motivation events.
  for (final doc in docs) {
    final data = doc.data();

    final timestamp = data['createdAt'];

    if (timestamp is! Timestamp) {
      continue;
    }

    final DateTime eventKsa = timestamp.toDate().toUtc().add(
      const Duration(hours: 3),
    );

    final DateTime eventDay = DateTime(
      eventKsa.year,
      eventKsa.month,
      eventKsa.day,
    );

    final String key = _activityDateKey(eventDay);

    if (!activityByDay.containsKey(key)) {
      continue;
    }

    final String source = data['source']?.toString() ?? '';

    if (activityByDay[key]!.containsKey(source)) {
      activityByDay[key]![source] = activityByDay[key]![source]! + 1;
    }
  }

  final List<_ParentActivityDay> result = [];

  for (int i = 6; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));

    final key = _activityDateKey(date);

    final counts = activityByDay[key]!;

    result.add(
      _ParentActivityDay(
        date: date,
        label: dayLabels[date.weekday] ?? '',
        listening: counts['listening'] ?? 0,
        speaking: counts['speaking'] ?? 0,
        practiceTogether: counts['practice_together'] ?? 0,
      ),
    );
  }

  return result;
}

String _activityDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');

  final day = date.day.toString().padLeft(2, '0');

  return '${date.year}-$month-$day';
}

class _ParentProgressMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ParentProgressMessage({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),

          const SizedBox(width: 7),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10.5,
                height: 1.45,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentWeeklyActivityCard extends StatelessWidget {
  final List<_ParentActivityDay> days;
  final bool loading;

  const _ParentWeeklyActivityCard({required this.days, required this.loading});

  @override
  Widget build(BuildContext context) {
    final int totalListening = days.fold(0, (sum, day) => sum + day.listening);

    final int totalSpeaking = days.fold(0, (sum, day) => sum + day.speaking);

    final int totalPractice = days.fold(
      0,
      (sum, day) => sum + day.practiceTogether,
    );

    final int total = totalListening + totalSpeaking + totalPractice;

    int maxActivity = 1;

    for (final day in days) {
      if (day.total > maxActivity) {
        maxActivity = day.total;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================================================
          // HEADER
          // =========================================================
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF7B4AAD).withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF7B4AAD),
                  size: 20,
                ),
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'النشاط خلال آخر ٧ أيام',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF511281),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'عدد التمارين المكتملة يوميًا',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 10,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),

              if (!loading)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${toArabicDigits(total)} تمرين',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7B4AAD),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          if (loading)
            const SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF511281)),
              ),
            )
          else if (total == 0)
            _buildEmptyState()
          else
            _buildChart(maxActivity),

          const SizedBox(height: 16),

          // =========================================================
          // BREAKDOWN
          // =========================================================
          Row(
            children: [
              Expanded(
                child: _ParentActivityTypeChip(
                  icon: Icons.headphones_rounded,
                  label: 'استماع',
                  value: totalListening,
                  color: const Color(0xFF7B4AAD),
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _ParentActivityTypeChip(
                  icon: Icons.mic_rounded,
                  label: 'نطق',
                  value: totalSpeaking,
                  color: const Color(0xFF5CB88A),
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _ParentActivityTypeChip(
                  icon: Icons.people_alt_rounded,
                  label: 'تدريب مشترك',
                  value: totalPractice,
                  color: const Color(0xFFF1A340),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(int maxActivity) {
    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: days.map((day) {
          final double ratio = day.total / maxActivity;

          final double barHeight = day.total == 0 ? 7 : 20 + (ratio * 72);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 20,
                  child: day.total == 0
                      ? null
                      : Text(
                          toArabicDigits(day.total),
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF666666),
                          ),
                        ),
                ),

                const SizedBox(height: 3),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 24,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: day.total == 0
                        ? const Color(0xFFEAE7ED)
                        : const Color(0xFFB999D4),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  day.label,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF777777),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  toArabicDigits(day.date.day),
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 8,
                    color: Color(0xFFAAAAAA),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 23),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F6FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: Color(0xFFAAA7AE),
            size: 27,
          ),
          SizedBox(height: 7),
          Text(
            'لا يوجد نشاط مسجل خلال آخر ٧ أيام',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentActivityTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _ParentActivityTypeChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: color),

          const SizedBox(height: 4),

          Text(
            toArabicDigits(value),
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF333333),
            ),
          ),

          const SizedBox(height: 1),

          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 8.5,
              color: Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentRecentActivitySection extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;

  final bool loading;

  const _ParentRecentActivitySection({
    required this.docs,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آخر الأنشطة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF511281),
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'أحدث التمارين التي أكملها الطفل',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11.5,
            color: Color(0xFF777777),
          ),
        ),

        const SizedBox(height: 13),

        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 25),
              child: CircularProgressIndicator(color: Color(0xFF511281)),
            ),
          )
        else if (docs.isEmpty)
          _buildEmptyState()
        else
          Container(
            width: double.infinity,
            decoration: _cardDecoration(),
            child: Column(
              children: List.generate(docs.length, (index) {
                final data = docs[index].data();

                return Column(
                  children: [
                    _ParentRecentActivityTile(data: data),

                    if (index < docs.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 1, color: Color(0xFFF0EDF2)),
                      ),
                  ],
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: _cardDecoration(),
      child: const Column(
        children: [
          Icon(Icons.history_rounded, size: 29, color: Color(0xFFAAA7AE)),
          SizedBox(height: 8),
          Text(
            'لا توجد أنشطة مسجلة بعد',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11.5,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentRecentActivityTile extends StatelessWidget {
  final Map<String, dynamic> data;

  const _ParentRecentActivityTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final String source = data['source']?.toString() ?? '';

    final String letter = data['letter']?.toString() ?? '';

    final String level = data['level']?.toString() ?? '';

    final int correctCount = (data['correctCount'] as num?)?.toInt() ?? 0;

    final int points = (data['pointsAwarded'] as num?)?.toInt() ?? 0;

    final Timestamp? timestamp = data['createdAt'] is Timestamp
        ? data['createdAt'] as Timestamp
        : null;

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String result;

    switch (source) {
      // ============================================================
      // LISTENING
      // ============================================================
      case 'listening':
        icon = Icons.headphones_rounded;
        color = const Color(0xFF7B4AAD);

        title = 'تمارين الاستماع • حرف $letter';

        result = '${toArabicDigits(correctCount)}/٨ إجابات صحيحة';

        break;

      // ============================================================
      // SPEAKING
      // ============================================================
      case 'speaking':
        icon = Icons.mic_rounded;
        color = const Color(0xFF5CB88A);

        title = 'تمارين النطق • حرف $letter';

        final int averageScore = (data['averageScore'] as num?)?.toInt() ?? 0;

        result =
            '${toArabicDigits('$averageScore٪')}'
            ' • '
            '${toArabicDigits(correctCount)}/٨ نطق صحيح';

        break;

      // ============================================================
      // PRACTICE TOGETHER
      // ============================================================
      case 'practice_together':
        icon = Icons.people_alt_rounded;
        color = const Color(0xFFF1A340);

        title = 'تدريب مشترك • حرف $letter';

        final String exerciseType = data['exerciseType']?.toString() ?? '';

        final String outcome = data['outcome']?.toString() ?? '';

        final String exerciseLabel = exerciseType == 'speaking'
            ? 'نطق'
            : 'استماع';

        result =
            '$exerciseLabel'
            ' • '
            '${toArabicDigits(correctCount)}/٨ صحيحة'
            ' • '
            '${_practiceOutcomeLabel(outcome)}';

        break;

      default:
        icon = Icons.school_rounded;
        color = const Color(0xFF888888);

        title = 'نشاط تدريبي';

        result = '';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =========================================================
          // ICON
          // =========================================================
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 21, color: color),
          ),

          const SizedBox(width: 11),

          // =========================================================
          // ACTIVITY DETAILS
          // =========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      _formatParentActivityDate(timestamp),
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 8.5,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                Text(
                  'المستوى '
                  '${_parentLevelLabel(level)}',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: _parentLevelColor(level),
                  ),
                ),

                if (result.isNotEmpty) ...[
                  const SizedBox(height: 4),

                  Text(
                    result,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // =========================================================
          // POINTS
          // =========================================================
          if (points > 0) ...[
            const SizedBox(width: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 13,
                    color: Color(0xFFF1A340),
                  ),

                  const SizedBox(width: 2),

                  Text(
                    '+${toArabicDigits(points)}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC18824),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
