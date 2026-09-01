import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'style_constants.dart';

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
  final String childId;

  const ExerciseRecordingScreen({
    super.key,
    required this.letter,
    required this.childId,
  });

  @override
  State<ExerciseRecordingScreen> createState() =>
      _ExerciseRecordingScreenState();
}

class _ExerciseRecordingScreenState extends State<ExerciseRecordingScreen>
    with SingleTickerProviderStateMixin {
  static const Color _deepPurple = Color(0xFF511281);
  static const Color _red = Color(0xFFFF6969);
  static const Color _bgYellow = Color(0xFFFCF9EA);

  int _currentExercise = 0;

  RecordingState _recordingState = RecordingState.idle;

  int _lastScore = 0;

  final List<int> _exerciseScores = [];

  int _recordingTime = 0;

  Timer? _recordingTimer;

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

  // -------------------------------------------------------------------------
  // Recording functionality
  // بدون تغيير
  // -------------------------------------------------------------------------

  void _startRecording() {
    setState(() {
      _recordingState = RecordingState.recording;
      _recordingTime = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingTime++;
      });

      if (_recordingTime >= 5) {
        timer.cancel();
        _stopRecording();
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();

    setState(() {
      _recordingState = RecordingState.analyzing;
    });

    Future.delayed(const Duration(seconds: 2), () {
      final mockScore = Random().nextInt(30) + 70;

      setState(() {
        _lastScore = mockScore;
        _recordingState = RecordingState.recorded;
      });
    });
  }

  void _handleNext() {
    if (_recordingState != RecordingState.recorded) {
      return;
    }

    final updatedScores = [..._exerciseScores, _lastScore];

    _exerciseScores.add(_lastScore);

    if (_currentExercise < recordingExercises.length - 1) {
      setState(() {
        _currentExercise++;
        _recordingState = RecordingState.idle;
        _recordingTime = 0;
      });
    } else {
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
          'childId': widget.childId,
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
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(child: _PronunciationBackground()),
                  ),

                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(overscroll: false),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 70),
                      child: _buildCard(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Header
  // نفس الهيدر والـ functionality
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      decoration: FaseehStyle.headerDecoration,
      padding: FaseehStyle.getStandardPadding(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pushNamed(
              context,
              '/child/letter-levels',
              arguments: {'letter': widget.letter, 'childId': widget.childId},
            ),
          ),

          const SizedBox(width: 8),

          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تمارين النطق',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),

                Text(
                  'انطق وسجّل صوتك',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Main content
  // -------------------------------------------------------------------------

  Widget _buildCard() {
    return Column(
      children: [
        _buildCardHeader(),

        const SizedBox(height: 12),

        _buildExercisePanel(),

        const SizedBox(height: 14),

        _buildNextButton(),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Progress
  // -------------------------------------------------------------------------

  Widget _buildCardHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _deepPurple.withOpacity(0.07)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تقدّمك',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 11,
                  color: Color(0xFF777777),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EBFA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  'تمرين ${_currentExercise + 1} من ${recordingExercises.length}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 11,
                    color: _deepPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: const Color(0xFFF0EBF3),
              valueColor: const AlwaysStoppedAnimation<Color>(_red),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Exercise Panel
  // -------------------------------------------------------------------------

  Widget _buildExercisePanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F2FF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _deepPurple.withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInstructionRow(),

          const SizedBox(height: 13),

          _buildWordDisplay(),

          const SizedBox(height: 13),

          _buildRecordingBox(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Instruction
  // -------------------------------------------------------------------------

  Widget _buildInstructionRow() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 90),
      child: Row(
        children: [
          // Cute character
          const SizedBox(
            width: 76,
            height: 90,
            child: _CutePronunciationCharacter(),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 29,
                      height: 29,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: _red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_currentExercise + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),

                    const SizedBox(width: 7),

                    const Text(
                      'هيا ننطق!',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 14,
                        color: _deepPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                Text(
                  _exercise.instruction,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  _exercise.transliteration,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10.5,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Word Display
  // -------------------------------------------------------------------------

  Widget _buildWordDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: _deepPurple.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          Text(
            _exercise.text,
            style: const TextStyle(
              fontSize: 43,
              color: _deepPurple,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 13),

          OutlinedButton.icon(
            onPressed: () {
              /* play audio */
            },
            icon: const Icon(Icons.volume_up_rounded, color: _red, size: 17),
            label: const Text(
              'استمع إلى المثال',
              style: TextStyle(
                color: _red,
                fontSize: 11.5,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _red.withOpacity(0.45)),
              backgroundColor: const Color(0xFFFFF6F7),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Recording Box
  // -------------------------------------------------------------------------

  Widget _buildRecordingBox() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 175),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _red.withOpacity(0.10)),
      ),
      child: switch (_recordingState) {
        RecordingState.idle => _buildIdleState(),
        RecordingState.recording => _buildRecordingState(),
        RecordingState.analyzing => _buildAnalyzingState(),
        RecordingState.recorded => _buildRecordedState(),
      },
    );
  }

  // -------------------------------------------------------------------------
  // Idle
  // -------------------------------------------------------------------------

  Widget _buildIdleState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _startRecording,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),

              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _red.withOpacity(0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 39,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'اضغط وابدأ النطق',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: _deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 2),

        const Text(
          'سجّل صوتك بوضوح',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10.5,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Recording
  // -------------------------------------------------------------------------

  Widget _buildRecordingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _stopRecording,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 102,
                height: 102,
                decoration: BoxDecoration(
                  color: _red.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
              ),

              Container(
                width: 82,
                height: 82,
                decoration: const BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'جاري تسجيل صوتك...',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: _deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 5),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFECEF),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '${_recordingTime}ث',
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              color: _red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'اضغط على زر الإيقاف عند الانتهاء',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 9.5,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Analyzing
  // -------------------------------------------------------------------------

  Widget _buildAnalyzingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _spinController,
          builder: (_, __) => Transform.rotate(
            angle: _spinController.value * 2 * pi,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F0FF),
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

        const SizedBox(height: 13),

        const Text(
          'جاري تحليل نطقك...',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: _deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        const Text(
          'لحظات قليلة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10.5,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Recorded
  // -------------------------------------------------------------------------

  Widget _buildRecordedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF7EF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF67AF82),
            size: 38,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '$_lastScore%',
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: _deepPurple,
          ),
        ),

        const SizedBox(height: 2),

        const Text(
          'أحسنت! هذه نتيجة نطقك',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11.5,
            color: Color(0xFF6E6E6E),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Next Button
  // بدون تغيير في الـ functionality
  // -------------------------------------------------------------------------

  Widget _buildNextButton() {
    final isLast = _currentExercise == recordingExercises.length - 1;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _recordingState == RecordingState.recorded
            ? _handleNext
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _red,
          disabledBackgroundColor: const Color(0xFFE1DDE3),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLast ? 'إنهاء' : 'التالي',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(width: 5),

            Icon(
              isLast ? Icons.check_rounded : Icons.arrow_back_rounded,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pastel Background
// ---------------------------------------------------------------------------

class _PronunciationBackground extends StatelessWidget {
  const _PronunciationBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 40,
          right: -55,
          child: _circle(145, const Color(0xFFDCC9F5).withOpacity(0.18)),
        ),

        Positioned(
          top: 240,
          left: -55,
          child: _circle(145, const Color(0xFFDDF2E3).withOpacity(0.26)),
        ),

        Positioned(
          top: 500,
          right: -45,
          child: _circle(115, const Color(0xFFFFDCE3).withOpacity(0.24)),
        ),

        Positioned(
          top: 710,
          left: 25,
          child: _circle(21, const Color(0xFFD4BDEA).withOpacity(0.35)),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

// ---------------------------------------------------------------------------
// Cute Pronunciation Character
// ---------------------------------------------------------------------------

class _CutePronunciationCharacter extends StatelessWidget {
  const _CutePronunciationCharacter();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);
    const Color purple = Color(0xFF8B55B3);
    const Color pink = Color(0xFFFF96AC);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Right ear
        Positioned(
          top: 0,
          right: 11,
          child: Container(
            width: 18,
            height: 35,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 22,
                decoration: BoxDecoration(
                  color: pink.withOpacity(0.48),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),

        // Left ear
        Positioned(
          top: 0,
          left: 11,
          child: Container(
            width: 18,
            height: 35,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 22,
                decoration: BoxDecoration(
                  color: pink.withOpacity(0.48),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),

        // Body
        Positioned(
          bottom: 0,
          child: Container(
            width: 44,
            height: 27,
            decoration: const BoxDecoration(
              color: purple,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(9),
                bottomRight: Radius.circular(9),
              ),
            ),
          ),
        ),

        // Head
        Positioned(
          top: 25,
          child: Container(
            width: 56,
            height: 52,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Eyes
                Positioned(
                  top: 18,
                  right: 13,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4D3855),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 18,
                  left: 13,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4D3855),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 30,
                  right: 6,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: pink.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 30,
                  left: 6,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: pink.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 26,
                  left: 24,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Smile
                Positioned(
                  top: 32,
                  left: 20,
                  child: Container(
                    width: 16,
                    height: 7,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF4D3855),
                          width: 1.4,
                        ),
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Tiny microphone
        Positioned(
          right: 0,
          bottom: 7,
          child: Transform.rotate(
            angle: -0.25,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 17,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6969),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),

                Container(width: 3, height: 7, color: const Color(0xFF745183)),

                Container(
                  width: 10,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF745183),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Spinner arc painter
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
      3 * pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
