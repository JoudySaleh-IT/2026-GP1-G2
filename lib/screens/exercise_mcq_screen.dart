import 'package:flutter/material.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _purple = Color(0xFF511281);
const _purple2 = Color(0xFF6A3A9E);
const _coral = Color(0xFFFF6969);
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

// ─── Result Message ───────────────────────────────────────────────────────────
({String text, Color color}) _getResultMessage(int score, int total) {
  final ratio = score / total;
  if (ratio == 1)   return (text: 'ممتاز! أتقنت جميع الأسئلة! 🏆', color: const Color(0xFFB45309));
  if (ratio >= 0.8) return (text: 'رائع! أداء متميز جداً! 🌟',       color: const Color(0xFF16A34A));
  if (ratio >= 0.6) return (text: 'جيد! يمكنك تحسين أدائك! 💪',      color: const Color(0xFF2563EB));
  return                   (text: 'استمر في التدريب، ستتحسن! 🌱',      color: const Color(0xFFEA580C));
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class ExerciseMCQScreen extends StatefulWidget {
  final String letter;
  const ExerciseMCQScreen({super.key, required this.letter});

  @override
  State<ExerciseMCQScreen> createState() => _ExerciseMCQScreenState();
}

class _ExerciseMCQScreenState extends State<ExerciseMCQScreen> {
  int  _currentIndex  = 0;
  int? _selectedAnswer;
  bool _showFeedback  = false;
  int  _score         = 0;
  bool _isFinished    = false;

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
    _answers.add((selected: _selectedAnswer!, correct: _question.correctAnswer));
    if (_currentIndex < _mcqQuestions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _showFeedback   = false;
      });
    } else {
      setState(() => _isFinished = true);
    }
  }

  // ════════════════════════════════════════════════════════════
  //  RESULTS SCREEN
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: _isFinished ? _resultsScaffold() : _quizScaffold(),
    );
  }

  // ── Results scaffold ──────────────────────────────────────────────────────
  Widget _resultsScaffold() {
    final result     = _getResultMessage(_score, _mcqQuestions.length);
    final percentage = (_score / _mcqQuestions.length * 100).round();

    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          // Header
          _header(
            title: 'نتيجة التمرين',
            subtitle: 'ملخص أدائك',
            onBack: () => Navigator.pop(context),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Score card ──
                  _scoreCard(percentage, result),
                  const SizedBox(height: 16),

                  // ── Breakdown ──
                  _breakdownCard(),
                  const SizedBox(height: 24),

                  // ── Home button ──
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/child/home'),
                      icon: const Icon(Icons.home_rounded, size: 20),
                      label: const Text(
                        'الرئيسية',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _purple,
                        side: const BorderSide(color: _purple, width: 2),
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Score Card ──────────────────────────────────────────────────────────────
  Widget _scoreCard(int percentage, ({String text, Color color}) result) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withOpacity(0.1), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Purple gradient section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_purple2, _purple],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
            child: Column(
              children: [
                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_mcqQuestions.length, (i) {
                    final filled = i < _score;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: filled
                            ? const Color(0xFFFFD700)
                            : Colors.white30,
                        size: 32,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),

                // Big score number
                RichText(
                  textDirection: TextDirection.ltr,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$_score',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      TextSpan(
                        text: '/${_mcqQuestions.length}',
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white54,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  '$percentage% إجابات صحيحة',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),

          // Result message
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Text(
              result.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: result.color,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Breakdown Card ──────────────────────────────────────────────────────────
  Widget _breakdownCard() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _purple.withOpacity(0.1), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.fromSTEB(16, 16, 16, 10),
          child: Text(
            'تفاصيل الإجابات',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
              fontFamily: 'Tajawal',
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: List.generate(_mcqQuestions.length, (i) {
              final ans = _answers[i];
              final isCorrect = ans.selected == ans.correct;
              // ── Get actual option text ──
              final selectedText = _mcqQuestions[i].options[ans.selected];
              final correctText  = _mcqQuestions[i].options[ans.correct];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.withOpacity(0.06)
                      : Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Question row ──
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        // Number circle
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? Colors.green.shade500
                                : Colors.red.shade500,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Question text
                        Expanded(
                          child: Text(
                            _mcqQuestions[i].question,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF444444),
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Wrong answer details ──
                    if (!isCorrect) ...[
                      const SizedBox(height: 10),
                      // User's wrong answer
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 40),
                        child: RichText(
                          textDirection: TextDirection.rtl,
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'إجابتك: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626),
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                              TextSpan(
                                text: selectedText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFDC2626),
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Correct answer
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 40),
                        child: RichText(
                          textDirection: TextDirection.rtl,
                          text: TextSpan(
                            children: [
                              const TextSpan(
                                text: 'الإجابة الصحيحة: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                              TextSpan(
                                text: correctText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF16A34A),
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    ),
  );
}

  // ════════════════════════════════════════════════════════════
  //  QUIZ SCREEN
  // ════════════════════════════════════════════════════════════
  Widget _quizScaffold() {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Column(
        children: [
          // Header
          _header(
            title: 'تمارين الاختيار من متعدد',
            subtitle: 'اختر الإجابة الصحيحة',
            onBack: () => Navigator.pop(context),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: _purple.withOpacity(0.1), width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'تمرين ${_currentIndex + 1} من ${_mcqQuestions.length}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            textDirection: TextDirection.rtl,
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
                    const Divider(height: 1, thickness: 1),

                    // Question body
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Question container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _coral.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _coral.withOpacity(0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                              children: [
                                // Question number + text
                                Row(
                                  textDirection: TextDirection.rtl,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    // Number circle
                                    Container(
                                      width: 30,
                                      height: 30,
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
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    // Question text
                                    Expanded(
                                      child: Text(
                                        _question.question,
                                        textAlign: TextAlign.right,
                                        textDirection: TextDirection.rtl,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF333333),
                                          height: 1.5,
                                          fontFamily: 'Tajawal',
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
                                        color:
                                            _purple.withOpacity(0.1)),
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

                                // Listen button — aligned right
                                Align(
                                  alignment: Alignment.centerRight,
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
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: _coral),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Answer options
                          ..._question.options.asMap().entries.map(
                                (e) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 10),
                                  child: _AnswerOption(
                                    text: e.value,
                                    index: e.key,
                                    selectedAnswer: _selectedAnswer,
                                    correctAnswer:
                                        _question.correctAnswer,
                                    showFeedback: _showFeedback,
                                    onTap: () => _handleAnswer(e.key),
                                  ),
                                ),
                              ),

                          // Feedback banner
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

                    // Score + Next button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          // Score text — RIGHT side
                          Text(
                            'النتيجة: $_score/${_currentIndex + (_showFeedback ? 1 : 0)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF888888),
                              fontFamily: 'Tajawal',
                            ),
                          ),

                          // Next button — LEFT side
                          ElevatedButton(
                            onPressed:
                                _showFeedback ? _handleNext : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _coral,
                              disabledBackgroundColor:
                                  const Color(0xFFCCCCCC),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              elevation: 3,
                            ),
                            child: Text(
                              _currentIndex < _mcqQuestions.length - 1
                                  ? 'السؤال التالي'
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
    );
  }

  // ── Shared Header ───────────────────────────────────────────────────────────
  Widget _header({
    required String title,
    required String subtitle,
    required VoidCallback onBack,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_purple2, _purple],
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
        textDirection: TextDirection.rtl,
        children: [
          // Back button — RIGHT side in RTL
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.arrow_back_ios_rounded,
                    color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title + subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Tajawal',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'Tajawal'),
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
    final isSelected  = selectedAnswer == index;
    final isCorrect   = index == correctAnswer;
    final showCorrect = showFeedback && isCorrect;
    final showWrong   = showFeedback && isSelected && !isCorrect;

    Color borderColor;
    Color bgColor;
    Color textColor = const Color(0xFF333333);

    if (showCorrect) {
      borderColor = Colors.green;
      bgColor     = Colors.green.withOpacity(0.07);
      textColor   = Colors.green.shade700;
    } else if (showWrong) {
      borderColor = Colors.red;
      bgColor     = Colors.red.withOpacity(0.07);
      textColor   = Colors.red.shade700;
    } else if (isSelected) {
      borderColor = _coral;
      bgColor     = _coral.withOpacity(0.08);
    } else {
      borderColor = _purple.withOpacity(0.1);
      bgColor     = Colors.white;
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
          textDirection: TextDirection.rtl,
          children: [
            // Text — RIGHT side
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),

            // Icon — LEFT side
            if (showCorrect) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle),
                child: const Icon(Icons.check,
                    color: Colors.white, size: 14),
              ),
            ] else if (showWrong) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 14),
              ),
            ],
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
      width: double.infinity,
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
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontSize: 13,
          color: isCorrect
              ? Colors.green.shade700
              : Colors.orange.shade700,
          fontWeight: FontWeight.w500,
          fontFamily: 'Tajawal',
        ),
      ),
    );
  }
}