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
      end: 1.1,
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

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFCF9EA),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 650,
                    maxHeight: isTablet ? screenHeight * 0.92 : double.infinity,
                  ),
                  child: Padding(
                    // Reduced top and bottom padding to save those 4.5 pixels
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                          _buildProgressSection(),
                          const Divider(height: 1),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildInstructionBox(isTablet),
                                  _buildAudioPlayer(isTablet),
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 10,
                                    mainAxisSpacing: 10,
                                    // Flattened buttons more (2.8) to guarantee space
                                    childAspectRatio: isTablet ? 2.8 : 1.4,
                                    children: _exercise.options
                                        .map(
                                          (opt) => _AnswerTile(
                                            text: opt,
                                            selectedAnswer: _selectedAnswer,
                                            correctAnswer:
                                                _exercise.correctAnswer,
                                            showFeedback: _showFeedback,
                                            enabled:
                                                _playCount > 0 &&
                                                !_showFeedback,
                                            onTap: () => _handleAnswer(opt),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                  _buildFeedbackNoticeArea(isTablet),
                                ],
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Text(
            'تمرين ${_currentIndex + 1} من ${_listeningExercises.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 5,
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

  Widget _buildInstructionBox(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 8 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6969).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6969).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: const Color(0xFFFF6969),
            child: Text(
              '${_currentIndex + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _exercise.instruction,
              style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(bool isTablet) {
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
            child: Container(
              width: isTablet
                  ? 65
                  : 88, // Slightly smaller to save those crucial pixels
              height: isTablet ? 65 : 88,
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
                                : const Color(0xFFFF6969))
                            .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: isTablet ? 32 : 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isPlaying ? 'جاري التشغيل...' : 'اضغط للتشغيل',
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildFeedbackNoticeArea(bool isTablet) {
    return SizedBox(
      height: isTablet ? 45 : 55, // Shorter height for tablet
      child: _showFeedback
          ? _FeedbackBanner(
              isCorrect: _selectedAnswer == _exercise.correctAnswer,
            )
          : (_playCount == 0
                ? Center(
                    child: Text(
                      'يرجى تشغيل الصوت أولاً 🔊',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  )
                : const SizedBox.shrink()),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'النتيجة: $_score/${_currentIndex + (_showFeedback ? 1 : 0)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF888888)),
          ),
          ElevatedButton(
            onPressed: _showFeedback ? _handleNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6969),
              disabledBackgroundColor: const Color(0xFFFFB8B8),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: Text(
              _currentIndex < _listeningExercises.length - 1
                  ? 'التالي'
                  : 'إنهاء',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 8,
        right: 16,
        left: 16,
      ),
      child: Row(
        children: [
          _HeaderIconBtn(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تمارين الاستماع',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'استمع واختر الإجابة الصحيحة',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: showCorrect
              ? Colors.green.withOpacity(0.08)
              : (showWrong ? Colors.red.withOpacity(0.08) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: showCorrect
                ? Colors.green
                : (showWrong
                      ? Colors.red
                      : (isSelected
                            ? const Color(0xFFFF6969)
                            : const Color(0xFF511281).withOpacity(0.1))),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final bool isCorrect;
  const _FeedbackBanner({required this.isCorrect});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
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
        isCorrect ? 'أحسنت! 🎉' : 'حاول مرة أخرى! 👂',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
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
    child: SizedBox(
      width: 38,
      height: 38,
      child: Icon(icon, color: Colors.white, size: 24),
    ),
  );
}
