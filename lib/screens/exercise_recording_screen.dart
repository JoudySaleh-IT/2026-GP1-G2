import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Data model
// ---------------------------------------------------------------------------

class RecordingExercise {
  final int id;
  final String text;
  final String transliteration;
  final String instruction;
  final String difficulty;

  const RecordingExercise({
    required this.id,
    required this.text,
    required this.transliteration,
    required this.instruction,
    required this.difficulty,
  });
}

const List<RecordingExercise> recordingExercises = [
  RecordingExercise(
    id: 1,
    text: 'ض',
    transliteration: 'Dhad',
    instruction: 'انطق هذا الحرف المفخم',
    difficulty: 'أساسي',
  ),
  RecordingExercise(
    id: 2,
    text: 'قَلَم',
    transliteration: 'Qalam (قلم)',
    instruction: 'اقرأ الكلمة مع الحركات الصحيحة',
    difficulty: 'متوسط',
  ),
  RecordingExercise(
    id: 3,
    text: 'مَدْرَسَة',
    transliteration: 'Madrasa (مدرسة)',
    instruction: 'انطق مع السكون والفتحة بشكل صحيح',
    difficulty: 'متوسط',
  ),
  RecordingExercise(
    id: 4,
    text: 'عَيْن',
    transliteration: 'Ayn (عين)',
    instruction: "ركز على صوت الحرف الحلقي 'ع'",
    difficulty: 'متقدم',
  ),
  RecordingExercise(
    id: 5,
    text: 'الطَّالِبُ يَدْرُسُ',
    transliteration: 'Al-Talib Yadrus (الطالب يدرس)',
    instruction: 'اقرأ الجملة كاملة',
    difficulty: 'متقدم',
  ),
];

// ---------------------------------------------------------------------------
// Recording state enum
// ---------------------------------------------------------------------------

enum RecordingState { idle, recording, analyzing, recorded }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ExerciseRecordingScreen extends StatefulWidget {
  final String letter;
  const ExerciseRecordingScreen({super.key, required this.letter});

  @override
  State<ExerciseRecordingScreen> createState() =>
      _ExerciseRecordingScreenState();
}

class _ExerciseRecordingScreenState extends State<ExerciseRecordingScreen>
    with SingleTickerProviderStateMixin {
  // Colors
  static const Color _purple = Color(0xFF6A3A9E);
  static const Color _deepPurple = Color(0xFF511281);
  static const Color _red = Color(0xFFFF6969);
  static const Color _bgYellow = Color(0xFFFCF9EA);

  int _currentExercise = 0;
  RecordingState _recordingState = RecordingState.idle;
  int _lastScore = 0;
  final List<int> _exerciseScores = [];
  int _recordingTime = 0;

  Timer? _recordingTimer;

  // Spinner animation
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  double get _progress => (_currentExercise + 1) / recordingExercises.length;
  RecordingExercise get _exercise => recordingExercises[_currentExercise];

  void _startRecording() {
    setState(() {
      _recordingState = RecordingState.recording;
      _recordingTime = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingTime++);
      if (_recordingTime >= 5) {
        timer.cancel();
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    setState(() => _recordingState = RecordingState.analyzing);

    Future.delayed(const Duration(seconds: 2), () {
      final mockScore = Random().nextInt(30) + 70;
      setState(() {
        _lastScore = mockScore;
        _recordingState = RecordingState.recorded;
      });
    });
  }

  void _handleNext() {
    if (_recordingState != RecordingState.recorded) return;

    final updatedScores = [..._exerciseScores, _lastScore];
    _exerciseScores.add(_lastScore);

    if (_currentExercise < recordingExercises.length - 1) {
      setState(() {
        _currentExercise++;
        _recordingState = RecordingState.idle;
        _recordingTime = 0;
      });
    } else {
      // All done – compute average and navigate to feedback
      final avgScore =
          (updatedScores.reduce((a, b) => a + b) / recordingExercises.length)
              .round();

      final questionsData = List.generate(
        recordingExercises.length,
        (i) => {
          'questionText': recordingExercises[i].text,
          'score': updatedScores[i],
        },
      );

      Navigator.pushNamed(
        context,
        '/child/exercise/recording-result',
        arguments: {
          'score': avgScore,
          'total': 100,
          'type': 'تسجيل',
          'questions': questionsData,
        },
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgYellow,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: _buildCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12,
        right: 16,
        left: 16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_purple, _deepPurple],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'تمارين التسجيل الصوتي',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'سجل صوتك وحسن نطقك',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Main card ─────────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _deepPurple.withOpacity(0.1), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCardHeader(),
            const SizedBox(height: 16),
            _buildExercisePanel(),
            const SizedBox(height: 16),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Column(
      children: [
        Text(
          'تمرين ${_currentExercise + 1} من ${recordingExercises.length}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'التقدم',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            Text(
              '${_currentExercise + 1}/${recordingExercises.length}',
              style: const TextStyle(
                fontSize: 13,
                color: _red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: Colors.grey.shade200,
            color: _red,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ── Exercise panel ────────────────────────────────────────────────────────

  Widget _buildExercisePanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _red.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildInstructionRow(),
          const SizedBox(height: 16),
          _buildWordDisplay(),
          const SizedBox(height: 16),
          _buildRecordingBox(),
        ],
      ),
    );
  }

  Widget _buildInstructionRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '${_currentExercise + 1}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _exercise.instruction,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              Text(
                _exercise.transliteration,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWordDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _deepPurple.withOpacity(0.1), width: 2),
      ),
      child: Column(
        children: [
          Text(
            _exercise.text,
            style: const TextStyle(fontSize: 48),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              /* play audio */
            },
            icon: const Icon(Icons.volume_up, color: _red, size: 16),
            label: const Text(
              'استمع إلى المثال',
              style: TextStyle(color: _red, fontSize: 13),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Recording box (state machine) ─────────────────────────────────────────

  Widget _buildRecordingBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _deepPurple.withOpacity(0.1), width: 2),
      ),
      child: switch (_recordingState) {
        RecordingState.idle => _buildIdleState(),
        RecordingState.recording => _buildRecordingState(),
        RecordingState.analyzing => _buildAnalyzingState(),
        RecordingState.recorded => _buildRecordedState(),
      },
    );
  }

  Widget _buildIdleState() {
    return Column(
      children: [
        GestureDetector(
          onTap: _startRecording,
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: _red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.mic, color: Colors.white, size: 48),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'اضغط لبدء التسجيل',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildRecordingState() {
    return Column(
      children: [
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'إيقاف',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'جاري التسجيل...',
          style: TextStyle(fontSize: 18, color: Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          '${_recordingTime}ث',
          style: const TextStyle(
            fontSize: 22,
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _spinController,
          builder: (_, __) => Transform.rotate(
            angle: _spinController.value * 2 * pi,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _red,
                  width: 4,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: ClipOval(child: CustomPaint(painter: _ArcPainter())),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'جاري تحليل النطق...',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildRecordedState() {
    return Column(
      children: [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
        const SizedBox(height: 8),
        Text(
          '$_lastScore%',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'نتيجة التمرين',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ],
    );
  }

  // ── Next button ───────────────────────────────────────────────────────────

  Widget _buildNextButton() {
    final isLast = _currentExercise == recordingExercises.length - 1;
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton(
        onPressed: _recordingState == RecordingState.recorded
            ? _handleNext
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _red,
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(
          isLast ? 'إنهاء' : 'التالي',
          style: const TextStyle(fontSize: 15),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spinner arc painter (matches the CSS border-t-transparent trick)
// ---------------------------------------------------------------------------

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6969)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -pi / 2,
      3 * pi / 2, // 270° visible arc, leaving a 90° "transparent" gap
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
