import 'package:flutter/material.dart';

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

const _mcqQuestions = [
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

// ─── Screen ──────────────────────────────────────────────────────────────────
class ExerciseMCQScreen extends StatefulWidget {
  final String letter;
  const ExerciseMCQScreen({super.key, required this.letter});

  @override
  State<ExerciseMCQScreen> createState() => _ExerciseMCQScreenState();
}

class _ExerciseMCQScreenState extends State<ExerciseMCQScreen> {
  int _currentIndex = 0;
  int? _selectedAnswer;
  bool _showFeedback = false;
  int _score = 0;

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
    if (_currentIndex < _mcqQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showFeedback = false;
      });
    } else {
      Navigator.pushNamed(
        context,
        '/child/feedback',
        arguments: {
          'score': _score,
          'total': _mcqQuestions.length,
          'type': 'MCQ',
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
            // ── Header ──────────────────────────────────────────
            _MCQHeader(onBack: () => Navigator.pop(context)),

            // ── Scrollable content ───────────────────────────────
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
                      // ── Progress header inside card ────────────
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
                                  '${_currentIndex + 1}/${_mcqQuestions.length}',
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

                      // ── Question body ──────────────────────────
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question number + text
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6969)
                                    .withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFF6969)
                                      .withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Number circle - الآن على اليمين (لأن RTL)
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
                                          _question.question,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF333333),
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Arabic text display
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFF511281)
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    child: Text(
                                      _question.arabicText,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 38,
                                        color: Color(0xFF511281),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Listen button
                                  OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.volume_up_rounded,
                                        size: 16,
                                        color: Color(0xFFFF6969)),
                                    label: const Text(
                                      'استمع إلى النطق',
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ── Answer options ─────────────────────
                            ..._question.options
                                .asMap()
                                .entries
                                .map((e) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 10),
                                      child: _AnswerOption(
                                        text: e.value,
                                        index: e.key,
                                        selectedAnswer: _selectedAnswer,
                                        correctAnswer:
                                            _question.correctAnswer,
                                        showFeedback: _showFeedback,
                                        onTap: () =>
                                            _handleAnswer(e.key),
                                      ),
                                    )),

                            // ── Feedback banner ────────────────────
                            if (_showFeedback) ...[
                              const SizedBox(height: 6),
                              _FeedbackBanner(
                                isCorrect: _selectedAnswer ==
                                    _question.correctAnswer,
                              ),
                            ],
                          ],
                        ),
                      ),

                      // ── Score + Next button ────────────────────
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'النتيجة: $_score/${_currentIndex + (_showFeedback ? 1 : 0)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF888888),
                              ),
                            ),
                            ElevatedButton(
                              onPressed:
                                  _showFeedback ? _handleNext : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFFF6969),
                                disabledBackgroundColor:
                                    const Color(0xFFCCCCCC),
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                elevation: 3,
                              ),
                              child: Text(
                                _currentIndex <
                                        _mcqQuestions.length - 1
                                    ? 'السؤال التالي'
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
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _MCQHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _MCQHeader({required this.onBack});

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
          // سهم الرجوع على اليمين - تم التغيير إلى arrow_back_ios_rounded
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios_rounded, // تم التغيير هنا
                    color: Colors.white, size: 22),
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
                ),
              ),
              SizedBox(height: 2),
              Text(
                'اختر الإجابة الصحيحة',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Answer Option ────────────────────────────────────────────────────────────
class _AnswerOption extends StatelessWidget {
  final String text;
  final int index;
  final int? selectedAnswer;
  final int correctAnswer;
  final bool showFeedback;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.text,
    required this.index,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.showFeedback,
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
      bgColor = Colors.green.withOpacity(0.07);
      textColor = Colors.green.shade700;
    } else if (showWrong) {
      borderColor = Colors.red;
      bgColor = Colors.red.withOpacity(0.07);
      textColor = Colors.red.shade700;
    } else if (isSelected) {
      borderColor = const Color(0xFFFF6969);
      bgColor = const Color(0xFFFF6969).withOpacity(0.08);
    } else {
      borderColor = const Color(0xFF511281).withOpacity(0.1);
      bgColor = Colors.white;
    }

    return GestureDetector(
      onTap: showFeedback ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          children: [
            // Text on the right (RTL)
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Icon on the left (RTL)
            if (showCorrect)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    color: Colors.white, size: 14),
              )
            else if (showWrong)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 14),
              ),
          ],
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
            : 'إجابة خاطئة. الإجابة الصحيحة مظللة. استمر في المحاولة!',
        style: TextStyle(
          fontSize: 13,
          color:
              isCorrect ? Colors.green.shade700 : Colors.orange.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}