import 'package:flutter/material.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _purple = Color(0xFF511281);
const _coral  = Color(0xFFFF6969);
const _bgColor = Color(0xFFFCF9EA);

// ─── Mock Questions ───────────────────────────────────────────────────────────
class _Question {
  final String question;
  final String arabicText;
  final List<String> options;
  final int correctAnswer;

  const _Question({
    required this.question,
    required this.arabicText,
    required this.options,
    required this.correctAnswer,
  });
}

const List<_Question> _mcqQuestions = [
  _Question(
    question: "ما الحرف الذي يمثل صوت 'ذ' في كلمة 'this'؟",
    arabicText: 'ذ',
    options: ['ذ (dhal)', 'ث (tha)', 'د (dal)', 'ز (zay)'],
    correctAnswer: 0,
  ),
  _Question(
    question: "اختر الحركة الصحيحة لكلمة 'فَ':",
    arabicText: 'فَتْحَة',
    options: ['فتحة (َ)', 'كسرة (ِ)', 'ضمة (ُ)', 'سكون (ْ)'],
    correctAnswer: 0,
  ),
  _Question(
    question: "ما اسم الحرف 'ض'؟",
    arabicText: 'ض',
    options: ['داد', 'ضاد', 'زاد', 'صاد'],
    correctAnswer: 1,
  ),
  _Question(
    question: 'أي زوج من الحروف يمثل الحروف المفخمة؟',
    arabicText: 'ص - س',
    options: ['ص - س', 'ت - ط', 'د - ذ', 'ك - ق'],
    correctAnswer: 1,
  ),
  _Question(
    question: 'اختر الكلمة ذات النطق الصحيح:',
    arabicText: 'كِتَاب',
    options: ['كَتَاب', 'كِتَاب', 'كُتَاب', 'كِتَابُ'],
    correctAnswer: 1,
  ),
];

// ─── Screen ───────────────────────────────────────────────────────────────────
class ExerciseMCQScreen extends StatefulWidget {
  final String letter;
  final String childId;
  const ExerciseMCQScreen({super.key, required this.letter, required this.childId});

  @override
  State<ExerciseMCQScreen> createState() => _ExerciseMCQScreenState();
}

class _ExerciseMCQScreenState extends State<ExerciseMCQScreen> {
  int  _currentIndex  = 0;
  int? _selectedAnswer;
  bool _showFeedback  = false;
  int  _score         = 0;

  final List<({int selected, int correct})> _answers = [];

  _Question get _question => _mcqQuestions[_currentIndex];
  double    get _progress => (_currentIndex + 1) / _mcqQuestions.length;

  void _handleAnswer(int index) {
    if (_showFeedback) return;
    setState(() {
      _selectedAnswer = index;
      _showFeedback   = true;
      if (index == _question.correctAnswer) _score++;
    });
  }

  void _handleNext() {
    _answers.add((
      selected: _selectedAnswer!,
      correct: _question.correctAnswer,
    ));

    if (_currentIndex < _mcqQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showFeedback   = false;
      });
    } else {
      // ── Navigate to separate result screen ──
      Navigator.pushNamed(
        context,
        '/child/exercise/mcq-result',
        arguments: {
          'score':    _score,
          'total':    _mcqQuestions.length,
          'answers':  _answers
              .map((a) => {'selected': a.selected, 'correct': a.correct})
              .toList(),
          'questions': _mcqQuestions
              .map((q) => {'question': q.question, 'options': q.options})
              .toList(),
          'letter': widget.letter,
          'childId': widget.childId,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _purple.withOpacity(0.1),
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
                              'تمرين ${_currentIndex + 1} من ${_mcqQuestions.length}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                                fontFamily: 'Tajawal',
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
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_currentIndex + 1}/${_mcqQuestions.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _coral,
                                    fontFamily: 'Tajawal',
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
                                    const AlwaysStoppedAnimation<Color>(_coral),
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
                                // Instruction + Arabic text (same as listening)
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _coral.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _coral.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: const BoxDecoration(
                                              color: _coral,
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
                                              _question.question,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Color(0xFF333333),
                                                height: 1.5,
                                                fontFamily: 'Tajawal',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: _purple.withOpacity(0.1)),
                                        ),
                                        child: Text(
                                          _question.arabicText,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 38,
                                            color: _purple,
                                            height: 1.2,
                                            fontFamily: 'Tajawal',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: AlignmentDirectional.centerStart,
                                        child: OutlinedButton.icon(
                                          onPressed: () {},
                                          icon: const Icon(
                                              Icons.volume_up_rounded,
                                              size: 16,
                                              color: _coral),
                                          label: const Text(
                                            'استمع إلى النطق',
                                            style: TextStyle(
                                                color: _coral,
                                                fontSize: 13,
                                                fontFamily: 'Tajawal'),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            side:
                                                const BorderSide(color: _coral),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Answer Grid (exact same as listening)
                                GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.4, // Exact same ratio
                                  children: _question.options
                                      .asMap()
                                      .entries
                                      .map(
                                        (entry) => _AnswerTile(
                                          text: entry.value,
                                          index: entry.key,
                                          selectedAnswer: _selectedAnswer,
                                          correctAnswer: _question.correctAnswer,
                                          showFeedback: _showFeedback,
                                          enabled: !_showFeedback,
                                          onTap: () => _handleAnswer(entry.key),
                                        ),
                                      )
                                      .toList(),
                                ),

                                const SizedBox(height: 12),

                                // Feedback banner (exact same as listening)
                                if (_showFeedback) ...[
                                  const SizedBox(height: 4),
                                  _FeedbackBanner(
                                    isCorrect:
                                        _selectedAnswer ==
                                        _question.correctAnswer,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ── Score + Next (exact same as listening) ─────
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
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            ElevatedButton(
                              onPressed: _showFeedback ? _handleNext : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _coral,
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
                                _currentIndex < _mcqQuestions.length - 1
                                    ? 'التالي'
                                    : 'إنهاء',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Tajawal',
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

  // ── Header ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF511281), Color(0xFF7A3FA8)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
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
          Material(
            color: Colors.transparent,
            child: _HeaderIconBtn(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pushNamed(
                context,
                '/child/letter-levels',
                arguments: {'letter': widget.letter, 'childId': widget.childId},

              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تمارين الاختيار من متعدد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Tajawal',
                ),
              ),
              SizedBox(height: 2),
              Text(
                'اختر الإجابة الصحيحة',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Answer Tile (exact same as listening) ───────────────────────────────────
class _AnswerTile extends StatelessWidget {
  final String text;
  final int index;
  final int? selectedAnswer;
  final int correctAnswer;
  final bool showFeedback;
  final bool enabled;
  final VoidCallback onTap;

  const _AnswerTile({
    required this.text,
    required this.index,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.showFeedback,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedAnswer == index;
    final isCorrect = index == correctAnswer;
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
      borderColor = _coral;
      bgColor = _coral.withOpacity(0.08);
    } else if (!enabled) {
      borderColor = _purple.withOpacity(0.08);
      bgColor = const Color(0xFFF5F5F5);
    } else {
      borderColor = _purple.withOpacity(0.1);
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
              fontSize: 20, // Slightly smaller to fit longer text
              color: textColor,
              fontWeight: FontWeight.w500,
              fontFamily: 'Tajawal',
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Feedback Banner (exact same as listening) ───────────────────────────────
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
            ? 'أحسنت! إجابة صحيحة 🎉'
            : 'إجابة خاطئة. استمر في المحاولة!',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 13,
          color: isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.w500,
          fontFamily: 'Tajawal',
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