import 'package:flutter/material.dart';

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

// ─── Screen ──────────────────────────────────────────────────────────────────
class ExerciseListeningScreen extends StatefulWidget {
  final String letter;
  const ExerciseListeningScreen({super.key, required this.letter});

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

  // ── 1. LIST TO TRACK ALL ANSWERS ─────────────────────────────────────────
  final List<Map<String, String>> _answers = [];

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  static const int _maxPlays = 3;

  _Exercise get _exercise => _listeningExercises[_currentIndex];
  double get _progress => (_currentIndex + 1) / _listeningExercises.length;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handlePlay() {
    if (_isPlaying || _playCount >= _maxPlays) return;
    setState(() {
      _isPlaying = true;
      _playCount++;
    });
    _pulseCtrl.repeat(reverse: true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isPlaying = false);
        _pulseCtrl.stop();
        _pulseCtrl.reset();
      }
    });
  }

  void _handleAnswer(String answer) {
    if (_showFeedback || _playCount == 0) return;
    setState(() {
      _selectedAnswer = answer;
      _showFeedback = true;
      if (answer == _exercise.correctAnswer) _score++;
    });
  }

  void _handleNext() {
    // ── 2. SAVE THIS ANSWER BEFORE MOVING ────────────────────────────────
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
      // ── 3. NAVIGATE TO RESULT SCREEN WITH ALL ANSWERS ─────────────────
      Navigator.pushNamed(
        context,
        '/child/exercise-listening-result',
        arguments: {
          'score': _score,
          'total': _listeningExercises.length,
          'answers': List<Map<String, String>>.from(_answers),
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
            _ListeningHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: Padding(
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
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ── Progress ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: Column(
                          children: [
                            Text(
                              'تمرين ${_currentIndex + 1} من ${_listeningExercises.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text(
                                  'التقدم',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_currentIndex + 1}/${_listeningExercises.length}',
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
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFFF6969),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(height: 1),

                      // ── Scrollable body ───────────────────────────
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: ScrollConfiguration.of(
                            context,
                          ).copyWith(overscroll: false),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Instruction
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFF6969,
                                    ).withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFF6969,
                                      ).withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
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
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _exercise.instruction,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF333333),
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Audio Player
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 28,
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF511281,
                                      ).withOpacity(0.1),
                                      width: 2,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 6,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      GestureDetector(
                                        onTap: _handlePlay,
                                        child: AnimatedBuilder(
                                          animation: _pulseAnim,
                                          builder: (_, child) =>
                                              Transform.scale(
                                                scale: _isPlaying
                                                    ? _pulseAnim.value
                                                    : 1.0,
                                                child: child,
                                              ),
                                          child: Container(
                                            width: 88,
                                            height: 88,
                                            decoration: BoxDecoration(
                                              color: _playCount >= _maxPlays
                                                  ? const Color(0xFFCCCCCC)
                                                  : const Color(0xFFFF6969),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      (_playCount >= _maxPlays
                                                              ? Colors.grey
                                                              : const Color(
                                                                  0xFFFF6969,
                                                                ))
                                                          .withOpacity(0.4),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _isPlaying
                                                  ? Icons.pause_rounded
                                                  : Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 48,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _isPlaying
                                            ? 'جاري التشغيل...'
                                            : 'اضغط للتشغيل',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'عدد مرات الاستماع المتبقية: ${_maxPlays - _playCount}/$_maxPlays',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF999999),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Answer Grid
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.4,
                                  children: _exercise.options
                                      .map(
                                        (opt) => _AnswerTile(
                                          text: opt,
                                          selectedAnswer: _selectedAnswer,
                                          correctAnswer:
                                              _exercise.correctAnswer,
                                          showFeedback: _showFeedback,
                                          enabled:
                                              _playCount > 0 && !_showFeedback,
                                          onTap: () => _handleAnswer(opt),
                                        ),
                                      )
                                      .toList(),
                                ),

                                const SizedBox(height: 12),

                                // Play-first notice
                                if (_playCount == 0 && !_showFeedback)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.blue.withOpacity(0.25),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'يرجى تشغيل الصوت قبل اختيار الإجابة',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF1565C0),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(
                                          Icons.volume_up_rounded,
                                          color: Color(0xFF1565C0),
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                  ),

                                // Feedback banner
                                if (_showFeedback) ...[
                                  const SizedBox(height: 4),
                                  _FeedbackBanner(
                                    isCorrect:
                                        _selectedAnswer ==
                                        _exercise.correctAnswer,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Score + Next ──────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'النتيجة: $_score/${_currentIndex + (_showFeedback ? 1 : 0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _showFeedback ? _handleNext : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6969),
                                disabledBackgroundColor: const Color(
                                  0xFFFFB8B8,
                                ),
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                elevation: 3,
                              ),
                              child: Text(
                                _currentIndex < _listeningExercises.length - 1
                                    ? 'التالي'
                                    : 'إنهاء',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
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
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _ListeningHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _ListeningHeader({required this.onBack});

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
          Material(
            color: Colors.transparent,
            child: _HeaderIconBtn(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تمارين الاستماع',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'استمع واختر الإجابة الصحيحة',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Answer Tile ──────────────────────────────────────────────────────────────
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
    final isSelected = selectedAnswer == text;
    final isCorrect = text == correctAnswer;
    final showCorrect = showFeedback && isCorrect;
    final showWrong = showFeedback && isSelected && !isCorrect;

    Color borderColor;
    Color bgColor;
    Color textColor = const Color(0xFF333333);

    if (showCorrect) {
      borderColor = Colors.green;
      bgColor = Colors.green.withOpacity(0.08);
      textColor = Colors.green.shade700;
    } else if (showWrong) {
      borderColor = Colors.red;
      bgColor = Colors.red.withOpacity(0.08);
      textColor = Colors.red.shade700;
    } else if (isSelected) {
      borderColor = const Color(0xFFFF6969);
      bgColor = const Color(0xFFFF6969).withOpacity(0.08);
    } else if (!enabled) {
      borderColor = const Color(0xFF511281).withOpacity(0.08);
      bgColor = const Color(0xFFF5F5F5);
    } else {
      borderColor = const Color(0xFF511281).withOpacity(0.1);
      bgColor = Colors.white;
    }

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Feedback Banner ──────────────────────────────────────────────────────────
class _FeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  const _FeedbackBanner({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCorrect
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Text(
        isCorrect
            ? 'أحسنت! مهارات الاستماع لديك تتحسن! 👂'
            : 'للأسف، استمع جيداً وحاول مرة أخرى!',
        style: TextStyle(
          fontSize: 13,
          color: isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.w500,
        ),
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
      child: Icon(icon, color: Colors.white, size: 25),
    ),
  );
}
