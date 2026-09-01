import 'package:flutter/material.dart';
import 'style_constants.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class _Exercise {
  final String instruction;
  final String audioDescription;
  final List<String> options;
  final String correctAnswer;

  const _Exercise({
    required this.instruction,
    required this.audioDescription,
    required this.options,
    required this.correctAnswer,
  });
}

// ─── Exercises ────────────────────────────────────────────────────────────────
const _listeningExercises = [
  _Exercise(
    instruction: "استمع إلى الصوت واختر الحرف الصحيح:",
    audioDescription: "نطق حرف 'ع'",
    options: ['ع', 'غ', 'ء', 'ح'],
    correctAnswer: 'ع',
  ),
  _Exercise(
    instruction: "أي كلمة سمعتها؟",
    audioDescription: "كلمة 'سَمَك'",
    options: ['سَمَك', 'سَمَح', 'سَمَع', 'سَمَا'],
    correctAnswer: 'سَمَك',
  ),
  _Exercise(
    instruction: "حدد الحركة الصحيحة التي سمعتها:",
    audioDescription: "صوت مع كسرة",
    options: ['فتحة (َ)', 'كسرة (ِ)', 'ضمة (ُ)', 'سكون (ْ)'],
    correctAnswer: 'كسرة (ِ)',
  ),
  _Exercise(
    instruction: "استمع واختر الحرف المفخم:",
    audioDescription: "نطق حرف 'ط'",
    options: ['ت', 'ط', 'د', 'ث'],
    correctAnswer: 'ط',
  ),
  _Exercise(
    instruction: "اختر الكلمة التي سمعتها:",
    audioDescription: "كلمة 'قَلَم'",
    options: ['قَلَم', 'كَلَم', 'قَلْب', 'كَلْب'],
    correctAnswer: 'قَلَم',
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class ExerciseListeningScreen extends StatefulWidget {
  final String letter;
  final String childId;

  const ExerciseListeningScreen({
    super.key,
    required this.letter,
    required this.childId,
  });

  @override
  State<ExerciseListeningScreen> createState() =>
      _ExerciseListeningScreenState();
}

class _ExerciseListeningScreenState extends State<ExerciseListeningScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String? _selectedAnswer;
  bool _showFeedback = false;
  int _score = 0;
  bool _isPlaying = false;
  int _playCount = 0;

  final List<Map<String, String>> _answers = [];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const int _maxPlays = 3;

  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _cream = Color(0xFFFCF9EA);

  _Exercise get _exercise => _listeningExercises[_currentIndex];

  double get _progress => (_currentIndex + 1) / _listeningExercises.length;

  // ───────────────────────────────────────────────────────────────────────────
  // Init
  // ───────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Play
  // نفس الـfunctionality
  // ───────────────────────────────────────────────────────────────────────────
  void _handlePlay() {
    if (_isPlaying || _playCount >= _maxPlays) {
      return;
    }

    setState(() {
      _isPlaying = true;
      _playCount++;
    });

    _pulseCtrl.repeat(reverse: true);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });

        _pulseCtrl.stop();
        _pulseCtrl.reset();
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Answer
  // نفس الـfunctionality
  // ───────────────────────────────────────────────────────────────────────────
  void _handleAnswer(String answer) {
    if (_showFeedback || _playCount == 0) {
      return;
    }

    setState(() {
      _selectedAnswer = answer;
      _showFeedback = true;

      if (answer == _exercise.correctAnswer) {
        _score++;
      }
    });
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Next
  // نفس الـfunctionality
  // ───────────────────────────────────────────────────────────────────────────
  void _handleNext() {
    _answers.add({
      'selected': _selectedAnswer ?? '',
      'correct': _exercise.correctAnswer,
      'instruction': _exercise.instruction,
    });

    if (_currentIndex < _listeningExercises.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showFeedback = false;
        _playCount = 0;
        _isPlaying = false;
      });
    } else {
      Navigator.pushNamed(
        context,
        '/child/exercise-listening-result',
        arguments: {
          'score': _score,
          'total': _listeningExercises.length,
          'answers': List<Map<String, String>>.from(_answers),
          'letter': widget.letter,
          'childId': widget.childId,
        },
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    final double screenWidth = MediaQuery.of(context).size.width;

    final bool isTablet = screenWidth > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _cream,

        body: Column(
          children: [
            // ================================================================
            // HEADER
            // نفس الهيدر بدون تغيير
            // ================================================================
            _buildHeader(),

            // ================================================================
            // CONTENT
            // ================================================================
            Expanded(
              child: Stack(
                children: [
                  // ─── Pastel Background ────────────────────────────────────
                  const Positioned.fill(
                    child: IgnorePointer(child: _ListeningBackground()),
                  ),

                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 650,
                        maxHeight: isTablet
                            ? screenHeight * 0.92
                            : double.infinity,
                      ),

                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(15, 8, 15, 10),

                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: _purple.withOpacity(0.09),
                              width: 1.4,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 9,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),

                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),

                            child: Column(
                              children: [
                                // ─── Progress
                                _buildProgressSection(),

                                // ─────────────────────────────────────────────
                                // Main Exercise Area
                                // ─────────────────────────────────────────────
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),

                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,

                                      children: [
                                        // ─── Cute instruction card
                                        _buildInstructionBox(isTablet),

                                        // ─── Audio Player
                                        _buildAudioPlayer(isTablet),

                                        // ─── Answers
                                        GridView.count(
                                          padding: EdgeInsets.zero,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          crossAxisCount: 2,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                          childAspectRatio: isTablet
                                              ? 3.0
                                              : 1.6,

                                          children: _exercise.options
                                              .map(
                                                (opt) => _AnswerTile(
                                                  text: opt,
                                                  selectedAnswer:
                                                      _selectedAnswer,
                                                  correctAnswer:
                                                      _exercise.correctAnswer,
                                                  showFeedback: _showFeedback,
                                                  enabled:
                                                      _playCount > 0 &&
                                                      !_showFeedback,
                                                  onTap: () =>
                                                      _handleAnswer(opt),
                                                ),
                                              )
                                              .toList(),
                                        ),

                                        // ─── Feedback
                                        _buildFeedbackNoticeArea(isTablet),
                                      ],
                                    ),
                                  ),
                                ),

                                // ─── Bottom Actions
                                _buildFooter(),
                              ],
                            ),
                          ),
                        ),
                      ),
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

  // ───────────────────────────────────────────────────────────────────────────
  // Progress
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildProgressSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F4FF).withOpacity(0.80),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تقدّمك',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF777777),
                  fontFamily: 'Tajawal',
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'تمرين ${_currentIndex + 1} من ${_listeningExercises.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _purple,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 7,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(_coral),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Instruction Card
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildInstructionBox(bool isTablet) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _purple.withOpacity(0.10), width: 1.3),
      ),

      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),

        child: Stack(
          children: [
            // Soft purple circle
            Positioned(
              right: -30,
              top: -35,
              child: Container(
                width: 105,
                height: 105,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5).withOpacity(0.32),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Soft pink circle
            Positioned(
              left: 70,
              bottom: -45,
              child: Container(
                width: 95,
                height: 85,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDCE4).withOpacity(0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),

              child: Row(
                children: [
                  // ─── Number
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _coral,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${_currentIndex + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // ─── Instruction text
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'استمع جيدًا',
                          style: TextStyle(
                            fontSize: 11,
                            color: _purple,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          _exercise.instruction,
                          style: TextStyle(
                            fontSize: isTablet ? 13 : 13.5,
                            color: const Color(0xFF333333),
                            height: 1.35,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  // ─── Cute Character
                  const SizedBox(
                    width: 67,
                    height: 84,
                    child: _CuteListeningCharacter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Audio Player
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAudioPlayer(bool isTablet) {
    final bool disabled = _playCount >= _maxPlays;

    final Color audioColor = disabled ? const Color(0xFFBEBEBE) : _coral;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handlePlay,

          child: AnimatedBuilder(
            animation: _pulseAnim,

            builder: (_, child) => Transform.scale(
              scale: _isPlaying ? _pulseAnim.value : 1.0,
              child: child,
            ),

            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer soft circle
                Container(
                  width: isTablet ? 82 : 104,
                  height: isTablet ? 82 : 104,
                  decoration: BoxDecoration(
                    color: audioColor.withOpacity(0.09),
                    shape: BoxShape.circle,
                  ),
                ),

                // Middle circle
                Container(
                  width: isTablet ? 70 : 90,
                  height: isTablet ? 70 : 90,
                  decoration: BoxDecoration(
                    color: audioColor.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                ),

                // Main button
                Container(
                  width: isTablet ? 58 : 74,
                  height: isTablet ? 58 : 74,
                  decoration: BoxDecoration(
                    color: audioColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: audioColor.withOpacity(0.27),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: isTablet ? 29 : 37,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 5),

        Text(
          _isPlaying
              ? 'جاري التشغيل...'
              : disabled
              ? 'استخدمت جميع مرات الاستماع'
              : 'اضغط للاستماع',
          style: TextStyle(
            fontSize: 10.5,
            color: disabled ? Colors.grey : const Color(0xFF666666),
            fontFamily: 'Tajawal',
          ),
        ),

        const SizedBox(height: 3),

        // ─── Play count
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_maxPlays, (index) {
            final bool used = index < _playCount;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: used ? _coral : const Color(0xFFE5E5E5),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Feedback area
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFeedbackNoticeArea(bool isTablet) {
    return SizedBox(
      height: isTablet ? 45 : 55,

      child: _showFeedback
          ? _FeedbackBanner(
              isCorrect: _selectedAnswer == _exercise.correctAnswer,
            )
          : (_playCount == 0
                ? const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hearing_rounded,
                          size: 17,
                          color: Color(0xFF7B4AAD),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'شغّل الصوت أولًا ثم اختر إجابتك',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFF7B4AAD),
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Footer
  // نفس الـFunctionality
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 7, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        border: Border(top: BorderSide(color: _purple.withOpacity(0.07))),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F0FF).withOpacity(0.80),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'النتيجة: $_score/${_currentIndex + (_showFeedback ? 1 : 0)}',
              style: const TextStyle(
                fontSize: 10.5,
                color: _purple,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
          ),

          ElevatedButton(
            onPressed: _showFeedback ? _handleNext : null,

            style: ElevatedButton.styleFrom(
              backgroundColor: _coral,
              disabledBackgroundColor: const Color(0xFFFFD1D1),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 9),
            ),

            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentIndex < _listeningExercises.length - 1
                      ? 'التالي'
                      : 'إنهاء',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 4),

                const Icon(Icons.arrow_back_rounded, size: 17),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HEADER
  // نفس الهيدر الأصلي بدون تغيير
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: FaseehStyle.headerDecoration,

      padding: FaseehStyle.getStandardPadding(context),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'تمارين الاستماع',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),
                Text(
                  'استمع واختر الإجابة الصحيحة',
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Answer Tile
// ─────────────────────────────────────────────────────────────────────────────
class _AnswerTile extends StatelessWidget {
  final String text;
  final String? selectedAnswer;
  final String correctAnswer;
  final bool showFeedback;
  final bool enabled;
  final VoidCallback onTap;

  const _AnswerTile({
    required this.text,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.showFeedback,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSelected = selectedAnswer == text;

    final bool isCorrect = text == correctAnswer;

    final bool showCorrect = showFeedback && isCorrect;

    final bool showWrong = showFeedback && isSelected && !isCorrect;

    Color backgroundColor = Colors.white;

    Color borderColor = const Color(0xFF511281).withOpacity(0.10);

    Color textColor = const Color(0xFF333333);

    if (showCorrect) {
      backgroundColor = const Color(0xFFEAF8EE);

      borderColor = const Color(0xFF66B884);

      textColor = const Color(0xFF398A58);
    } else if (showWrong) {
      backgroundColor = const Color(0xFFFFEEEE);

      borderColor = const Color(0xFFFF6969);

      textColor = const Color(0xFFD84F4F);
    } else if (isSelected) {
      backgroundColor = const Color(0xFFFFF1F3);

      borderColor = const Color(0xFFFF6969);
    }

    return GestureDetector(
      onTap: enabled ? onTap : null,

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),

          border: Border.all(color: borderColor, width: 1.6),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Stack(
          children: [
            // Tiny pastel decoration
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: text.length > 7 ? 14 : 19,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),

            if (showCorrect)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF59AC76),
                  size: 18,
                ),
              ),

            if (showWrong)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.close_rounded,
                  color: Color(0xFFFF6969),
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feedback
// ─────────────────────────────────────────────────────────────────────────────
class _FeedbackBanner extends StatelessWidget {
  final bool isCorrect;

  const _FeedbackBanner({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final Color color = isCorrect
        ? const Color(0xFF4CA66D)
        : const Color(0xFFE49A3C);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.23)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect
                ? Icons.check_circle_outline_rounded
                : Icons.refresh_rounded,
            color: color,
            size: 18,
          ),

          const SizedBox(width: 6),

          Text(
            isCorrect
                ? 'أحسنت! إجابة صحيحة'
                : 'حاول مرة أخرى في التمرين القادم',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background Decoration
// ─────────────────────────────────────────────────────────────────────────────
class _ListeningBackground extends StatelessWidget {
  const _ListeningBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Purple
        Positioned(
          top: 40,
          right: -55,
          child: _circle(150, const Color(0xFFDCC9F5).withOpacity(0.20)),
        ),

        // Pink small
        Positioned(
          top: 160,
          left: 20,
          child: _circle(23, const Color(0xFFFFC8D3).withOpacity(0.48)),
        ),

        // Green
        Positioned(
          top: 280,
          left: -55,
          child: _circle(145, const Color(0xFFD9F1E0).withOpacity(0.30)),
        ),

        // Purple small
        Positioned(
          top: 430,
          right: 25,
          child: _circle(23, const Color(0xFFD4BDEA).withOpacity(0.42)),
        ),

        // Pink large
        Positioned(
          top: 540,
          right: -45,
          child: _circle(125, const Color(0xFFFFDCE3).withOpacity(0.28)),
        ),

        // Green small
        Positioned(
          top: 680,
          left: 38,
          child: _circle(19, const Color(0xFFCDEFD9).withOpacity(0.52)),
        ),

        // Purple lower
        Positioned(
          top: 780,
          left: -45,
          child: _circle(135, const Color(0xFFDCC9F5).withOpacity(0.18)),
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

// ─────────────────────────────────────────────────────────────────────────────
// Cute Listening Character
// مرسوم بالـFlutter فقط
// ─────────────────────────────────────────────────────────────────────────────
class _CuteListeningCharacter extends StatelessWidget {
  const _CuteListeningCharacter();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);

    const Color accentColor = Color(0xFF8B55B3);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Right ear
        Positioned(
          top: 1,
          right: 10,
          child: Transform.rotate(
            angle: 0.15,
            child: Container(
              width: 18,
              height: 35,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9CB5).withOpacity(0.62),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Left ear
        Positioned(
          top: 1,
          left: 10,
          child: Transform.rotate(
            angle: -0.15,
            child: Container(
              width: 18,
              height: 35,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 22,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9CB5).withOpacity(0.62),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Headphones band
        Positioned(
          top: 22,
          child: Container(
            width: 56,
            height: 44,
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: accentColor, width: 4),
                left: BorderSide(color: accentColor, width: 4),
                right: BorderSide(color: accentColor, width: 4),
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
          ),
        ),

        // Body
        Positioned(
          bottom: 0,
          child: Container(
            width: 39,
            height: 22,
            decoration: const BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
            ),
          ),
        ),

        // Head
        Positioned(
          top: 26,
          child: Container(
            width: 55,
            height: 52,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: Stack(
              children: [
                // Headphone sides
                const Positioned(
                  top: 18,
                  right: -1,
                  child: SizedBox(
                    width: 7,
                    height: 18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                    ),
                  ),
                ),

                const Positioned(
                  top: 18,
                  left: -1,
                  child: SizedBox(
                    width: 7,
                    height: 18,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                    ),
                  ),
                ),

                // Eyes
                Positioned(
                  top: 19,
                  right: 13,
                  child: Container(
                    width: 6,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4D3855),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 19,
                  left: 13,
                  child: Container(
                    width: 6,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4D3855),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 31,
                  right: 6,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8EA6).withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 31,
                  left: 6,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8EA6).withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 27,
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
                  top: 33,
                  left: 20,
                  child: Container(
                    width: 15,
                    height: 7,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF4D3855),
                          width: 1.5,
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
      ],
    );
  }
}
