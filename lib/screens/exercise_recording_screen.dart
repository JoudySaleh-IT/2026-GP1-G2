import 'package:flutter/material.dart';

// ─── Mock Exercises ───────────────────────────────────────────────────────────
class _RecordingExercise {
  final String text;
  final String transliteration;
  final String instruction;
  final String difficulty;

  const _RecordingExercise({
    required this.text,
    required this.transliteration,
    required this.instruction,
    required this.difficulty,
  });
}

const _exercises = [
  _RecordingExercise(
    text: 'ض',
    transliteration: 'Dhad',
    instruction: 'انطق هذا الحرف المفخم',
    difficulty: 'أساسي',
  ),
  _RecordingExercise(
    text: 'قَلَم',
    transliteration: 'Qalam (قلم)',
    instruction: 'اقرأ الكلمة مع الحركات الصحيحة',
    difficulty: 'متوسط',
  ),
  _RecordingExercise(
    text: 'مَدْرَسَة',
    transliteration: 'Madrasa (مدرسة)',
    instruction: 'انطق مع السكون والفتحة بشكل صحيح',
    difficulty: 'متوسط',
  ),
  _RecordingExercise(
    text: 'عَيْن',
    transliteration: "Ayn (عين)",
    instruction: "ركز على صوت الحرف الحلقي 'ع'",
    difficulty: 'متقدم',
  ),
  _RecordingExercise(
    text: 'الطَّالِبُ يَدْرُسُ',
    transliteration: 'Al-Talib Yadrus',
    instruction: 'اقرأ الجملة كاملة',
    difficulty: 'متقدم',
  ),
];

enum _RecordingState { idle, recording, analyzing, recorded }

// ─── Screen ──────────────────────────────────────────────────────────────────
class ExerciseRecordingScreen extends StatefulWidget {
  final String letter;
  const ExerciseRecordingScreen({super.key, required this.letter});

  @override
  State<ExerciseRecordingScreen> createState() =>
      _ExerciseRecordingScreenState();
}

class _ExerciseRecordingScreenState extends State<ExerciseRecordingScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  _RecordingState _recordingState = _RecordingState.idle;
  int? _currentScore;
  int _totalScore = 0;
  int _recordingTime = 0;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _spinCtrl;

  _RecordingExercise get _exercise => _exercises[_currentIndex];
  double get _progress => (_currentIndex + 1) / _exercises.length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.18)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _pulseCtrl.stop();

    _spinCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _spinCtrl.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _recordingState = _RecordingState.recording;
      _recordingTime = 0;
    });
    _pulseCtrl.repeat(reverse: true);

    // Simulate recording timer
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_recordingState != _RecordingState.recording) return false;
      setState(() => _recordingTime++);
      if (_recordingTime >= 5) {
        _stopRecording();
        return false;
      }
      return true;
    });
  }

  void _stopRecording() {
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    setState(() => _recordingState = _RecordingState.analyzing);
    _spinCtrl.repeat();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _spinCtrl.stop();
      _spinCtrl.reset();
      final score = 70 + (DateTime.now().millisecond % 31); // mock 70–100
      setState(() {
        _currentScore = score;
        _totalScore += score;
        _recordingState = _RecordingState.recorded;
      });
    });
  }

  void _retry() {
    setState(() {
      _recordingState = _RecordingState.idle;
      _currentScore = null;
      _recordingTime = 0;
    });
  }

  void _handleNext() {
    if (_currentIndex < _exercises.length - 1) {
      setState(() {
        _currentIndex++;
        _recordingState = _RecordingState.idle;
        _currentScore = null;
        _recordingTime = 0;
      });
    } else {
      final avg = (_totalScore / _exercises.length).round();
      Navigator.pushNamed(
        context,
        '/child/feedback',
        arguments: {
          'score': avg,
          'total': 100,
          'type': 'Recording',
          'letter': widget.letter,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: Column(
          children: [
            _RecordingHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF511281).withOpacity(0.1),
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0D000000),
                          blurRadius: 8,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ── Progress ───────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Column(
                          children: [
                            Text(
                              'تمرين ${_currentIndex + 1} من ${_exercises.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('التقدم',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF888888))),
                                const Spacer(),
                                Text(
                                  '${_currentIndex + 1}/${_exercises.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFFF6969),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _progress,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFEEEEEE),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFFF6969)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // ── Instruction row ────────────────────
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6969)
                                    .withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFF6969)
                                      .withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  // الرقم على اليمين (لأن RTL)
                                  Container(
                                    width: 30,
                                    height: 30,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFF6969),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${_currentIndex + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Difficulty badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF6969)
                                          .withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _exercise.difficulty,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFFF6969),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // النص والمحتوى
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _exercise.instruction,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF333333),
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _exercise.transliteration,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF888888),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ── Text to pronounce ──────────────────
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF511281)
                                      .withOpacity(0.1),
                                  width: 2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _exercise.text,
                                    style: const TextStyle(
                                      fontSize: 52,
                                      color: Color(0xFF1A1A1A),
                                      fontWeight: FontWeight.w400,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                        Icons.volume_up_rounded,
                                        size: 16,
                                        color: Color(0xFFFF6969)),
                                    label: const Text(
                                      'استمع إلى المثال',
                                      style: TextStyle(
                                          color: Color(0xFFFF6969),
                                          fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Color(0xFFFF6969)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // ── Recording interface ────────────────
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF511281)
                                      .withOpacity(0.1),
                                  width: 2,
                                ),
                              ),
                              child: _buildRecordingInterface(),
                            ),
                          ],
                        ),
                      ),

                      // ── Score + Next ───────────────────────────
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'متوسط النتيجة: ${_currentIndex > 0 ? (_totalScore / (_currentIndex + (_recordingState == _RecordingState.recorded ? 1 : 0))).round() : 0}%',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                              ),
                            ),
                            ElevatedButton(
                              onPressed:
                                  _recordingState == _RecordingState.recorded
                                      ? _handleNext
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6969),
                                disabledBackgroundColor:
                                    const Color(0xFFFFB8B8),
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                elevation: 3,
                              ),
                              child: Text(
                                _currentIndex < _exercises.length - 1
                                    ? 'التالي'
                                    : 'إنهاء',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingInterface() {
    switch (_recordingState) {
      case _RecordingState.idle:
        return Column(
          children: [
            GestureDetector(
              onTap: _startRecording,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6969),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6969).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(Icons.mic_rounded,
                    color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 14),
            const Text('اضغط لبدء التسجيل',
                style: TextStyle(fontSize: 14, color: Color(0xFF666666))),
          ],
        );

      case _RecordingState.recording:
        return Column(
          children: [
            GestureDetector(
              onTap: _stopRecording,
              child: AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, child) =>
                    Transform.scale(scale: _pulseAnim.value, child: child),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.stop_rounded,
                      color: Colors.white, size: 48),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('جاري التسجيل...',
                style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Text(
              '${_recordingTime}ث',
              style: const TextStyle(
                  fontSize: 22,
                  color: Colors.red,
                  fontWeight: FontWeight.bold),
            ),
          ],
        );

      case _RecordingState.analyzing:
        return Column(
          children: [
            RotationTransition(
              turns: _spinCtrl,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFF6969),
                    width: 4,
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFF6969)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('جاري تحليل النطق...',
                style: TextStyle(fontSize: 15, color: Color(0xFF333333))),
          ],
        );

      case _RecordingState.recorded:
        final score = _currentScore!;
        final isExcellent = score >= 90;
        final isGood = score >= 70;
        final scoreColor = isExcellent
            ? Colors.green.shade600
            : isGood
                ? Colors.orange.shade600
                : Colors.red.shade600;
        final feedback = isExcellent
            ? 'نطق ممتاز! 🎉'
            : isGood
                ? 'عمل جيد! استمر في الممارسة! 👍'
                : 'حاول مرة أخرى! ستتحسن بالممارسة! 💪';

        return Column(
          children: [
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(feedback,
                style: const TextStyle(
                    fontSize: 15, color: Color(0xFF333333))),
            const SizedBox(height: 16),

            // Retry + Listen row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh_rounded,
                      size: 16, color: Color(0xFF511281)),
                  label: const Text('حاول مرة أخرى',
                      style: TextStyle(
                          color: Color(0xFF511281), fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color:
                            const Color(0xFF511281).withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow_rounded,
                      size: 16, color: Color(0xFF511281)),
                  label: const Text('استمع للتسجيل',
                      style: TextStyle(
                          color: Color(0xFF511281), fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color:
                            const Color(0xFF511281).withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Pronunciation details
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color:
                    const Color(0xFFFF6969).withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF6969).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تقييم النطق:',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333))),
                  const SizedBox(height: 10),
                  _EvalRow(label: 'الدقة', value: '✓ ممتاز',
                      color: Colors.green.shade600),
                  const SizedBox(height: 6),
                  _EvalRow(label: 'الوضوح', value: '✓ واضح',
                      color: Colors.green.shade600),
                  const SizedBox(height: 6),
                  _EvalRow(label: 'الطلاقة', value: '~ جيد',
                      color: Colors.orange.shade600),
                ],
              ),
            ),
          ],
        );
    }
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _RecordingHeader extends StatelessWidget {
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
          BoxShadow(
              color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
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
          // سهم الرجوع على اليمين (لأن RTL)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تمارين التسجيل الصوتي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'سجل صوتك وحسن نطقك',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Eval Row ─────────────────────────────────────────────────────────────────
class _EvalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _EvalRow(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // القيمة على اليسار (لأن RTL)
        Text(value,
            style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600)),
        const Spacer(),
        // النص على اليمين
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF666666))),
      ],
    );
  }
}