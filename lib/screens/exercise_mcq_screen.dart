import 'package:flutter/material.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _purple = Color(0xFF511281);
const _coral = Color(0xFFFF6969);
const _bgColor = Color(0xFFFCF9EA);

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

class ExerciseMCQScreen extends StatefulWidget {
  final String letter;
  final String childId;
  const ExerciseMCQScreen({
    super.key,
    required this.letter,
    required this.childId,
  });
  @override
  State<ExerciseMCQScreen> createState() => _ExerciseMCQScreenState();
}

class _ExerciseMCQScreenState extends State<ExerciseMCQScreen> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _showFeedback = false;
  int _score = 0;
  final List<({int selected, int correct})> _answers = [];

  _Question get _question => _mcqQuestions[_currentIndex];
  double get _progress => (_currentIndex + 1) / _mcqQuestions.length;

  void _handleAnswer(int index) {
    if (_showFeedback) return;
    setState(() {
      _selectedAnswer = index;
      _showFeedback = true;
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
        _showFeedback = false;
      });
    } else {
      Navigator.pushNamed(
        context,
        '/child/exercise/mcq-result',
        arguments: {
          'score': _score,
          'total': _mcqQuestions.length,
          'answers': _answers
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
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth > 600;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 650,
                    // Increased to 0.9 to prevent that 18px overflow
                    maxHeight: isTablet ? screenHeight * 0.90 : double.infinity,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                          _buildProgressSection(),
                          const Divider(height: 1),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment
                                    .center, // Better than spaceEvenly for overflow
                                children: [
                                  const SizedBox(height: 10),
                                  _buildQuestionBox(isTablet),
                                  const SizedBox(height: 15),
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: isTablet
                                        ? 2.5
                                        : 1.5, // Slimmer buttons on tablet
                                    children: _question.options
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                          return _AnswerTile(
                                            text: entry.value,
                                            index: entry.key,
                                            selectedAnswer: _selectedAnswer,
                                            correctAnswer:
                                                _question.correctAnswer,
                                            showFeedback: _showFeedback,
                                            enabled: !_showFeedback,
                                            onTap: () =>
                                                _handleAnswer(entry.key),
                                          );
                                        })
                                        .toList(),
                                  ),
                                  const SizedBox(height: 10),
                                  // Reduced fixed height to save space
                                  SizedBox(
                                    height: 50,
                                    child: _showFeedback
                                        ? _FeedbackBanner(
                                            isCorrect:
                                                _selectedAnswer ==
                                                _question.correctAnswer,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
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
            'تمرين ${_currentIndex + 1} من ${_mcqQuestions.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 5,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: const AlwaysStoppedAnimation<Color>(_coral),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBox(bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 10 : 16),
      decoration: BoxDecoration(
        color: _coral.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _coral.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: _coral,
                child: Text(
                  '${_currentIndex + 1}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _question.question,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF333333),
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _purple.withOpacity(0.1)),
            ),
            child: Text(
              _question.arabicText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 28 : 38,
                color: _purple,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'النتيجة: $_score/${_currentIndex + (_showFeedback ? 1 : 0)}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF888888),
              fontFamily: 'Tajawal',
            ),
          ),
          ElevatedButton(
            onPressed: _showFeedback ? _handleNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _coral,
              disabledBackgroundColor: const Color(0xFFFFB8B8),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: Text(
              _currentIndex < _mcqQuestions.length - 1 ? 'التالي' : 'إنهاء',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [_purple, Color(0xFF7A3FA8)]),
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
          const Text(
            'تمارين الاختيار من متعدد',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Support Widgets ──────────────────────────────────────────────────────────
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
                      : (isSelected ? _coral : _purple.withOpacity(0.1))),
            width: 2,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Tajawal',
              ),
            ),
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
      padding: const EdgeInsets.all(8),
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
        isCorrect ? 'أحسنت! إجابة صحيحة 🎉' : 'إجابة خاطئة. استمر في المحاولة!',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.w600,
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
