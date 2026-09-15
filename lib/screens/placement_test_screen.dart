import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/recording_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/arabic_numbers.dart';
import 'style_constants.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────
class PlacementWord {
  final String wordId;
  final String text;
  final String targetLetter;
  final String imageUrl;

  const PlacementWord({
    required this.wordId,
    required this.text,
    required this.targetLetter,
    required this.imageUrl,
  });
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class PlacementTestScreen extends StatefulWidget {
  final String childId;
  const PlacementTestScreen({super.key, required this.childId});

  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}

class _PlacementTestScreenState extends State<PlacementTestScreen>
    with SingleTickerProviderStateMixin {
  static const _purple = Color(0xFF511281);
  static const _purple2 = Color(0xFF6A3A9E);
  static const _coral = Color(0xFFFF6969);
  static const _bgColor = Color(0xFFFCF9EA);

  // --- State Variables ---
  List<PlacementWord> _placementWords = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  List<bool> _recorded = [];
  bool _isRecording = false;
  bool _showNext = false;
  // Background evaluation queue
final List<Map<String, String>> _evaluationQueue = [];
bool _isProcessingQueue = false;
int _pendingEvaluations = 0;
bool _isCalculatingFinalScore = false;

  double _totalAccumulatedScore = 0.0;
  List<Map<String, dynamic>> _individualScores = [];

  final RecordingService _recordingService = RecordingService();
  String? _lastRecordedPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.75).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchWordsFromFirestore();
  }

  Future<void> _fetchWordsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('placement_test_words')
          .get();

      List<PlacementWord> fetchedWords = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String rawImageUrl = data['image_url'] ?? '';
        String downloadImageUrl = rawImageUrl;

        if (rawImageUrl.startsWith('gs://')) {
          downloadImageUrl = await FirebaseStorage.instance
              .refFromURL(rawImageUrl)
              .getDownloadURL();
        }

        fetchedWords.add(
          PlacementWord(
            wordId: data['word_id'] ?? doc.id,
            text: data['text'] ?? '',
            targetLetter: data['target_letter'] ?? '',
            imageUrl: downloadImageUrl,
          ),
        );
      }

      fetchedWords.shuffle();

      if (mounted) {
        for (var word in fetchedWords) {
          if (word.imageUrl.isNotEmpty) {
            precacheImage(NetworkImage(word.imageUrl), context);
          }
        }
      }

      setState(() {
        _placementWords = fetchedWords;
        _recorded = List<bool>.filled(_placementWords.length, false);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching words: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingService.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  PlacementWord get _currentWord => _placementWords[_currentIndex];

  double get _progress => _placementWords.isEmpty
      ? 0
      : (_currentIndex + (_recorded[_currentIndex] ? 1 : 0)) /
            _placementWords.length;

  void _handleRecordToggle() async {
  if (_isRecording) {
    final path = await _recordingService.stop();

    final currentWordText = _currentWord.text;
    final currentWordLetter = _currentWord.targetLetter;

    _pulseController.stop();
    _pulseController.reset();

    if (path == null) {
  setState(() {
    _isRecording = false;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'تعذر حفظ التسجيل، حاول مرة أخرى',
        style: TextStyle(fontFamily: 'Tajawal'),
      ),
    ),
  );

  return;
}

setState(() {
  _lastRecordedPath = path;
  _isRecording = false;
  _recorded[_currentIndex] = true;
  _showNext = true;
  _pendingEvaluations++;
});

_evaluationQueue.add({
  'path': path,
  'word': currentWordText,
  'letter': currentWordLetter,
});

_processQueue();
  } else {
    final hasPermission = await _recordingService.checkPermission();

    if (hasPermission) {
      await _recordingService.start(
        'child_${widget.childId}_word_${_currentWord.wordId}',
      );

      setState(() {
        _isRecording = true;
      });

      _pulseController.repeat(reverse: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء السماح بالوصول للمايكروفون'),
        ),
      );
    }
  }
}

  

  Future<void> _processQueue() async {
  if (_isProcessingQueue) return;

  _isProcessingQueue = true;

  while (_evaluationQueue.isNotEmpty) {
    final item = _evaluationQueue.first;

    await _startPreprocessing(
      item['path']!,
      item['word']!,
      item['letter']!,
    );

    _evaluationQueue.removeAt(0);
  }

  _isProcessingQueue = false;
}

Future<void> _startPreprocessing(
  String path,
  String targetWord,
  String targetLetter,
) async {
  const String baseUrl =
      "https://faseeh-api-best-model-816737402071.me-central1.run.app";

  final url = Uri.parse('$baseUrl/process-audio/');

  debugPrint("🚀 جاري تقييم: $targetWord");

  try {
    var request = http.MultipartRequest('POST', url);

    request.files.add(
      await http.MultipartFile.fromPath('file', path),
    );

    request.fields['target_word'] = targetWord;
    request.fields['target_letter'] = targetLetter;

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    debugPrint("Response code: ${response.statusCode}");
    debugPrint("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'invalid_audio') {
  if (mounted) {
    setState(() {
      _individualScores.add({
        'letter': targetLetter,
        'score': 0,
      });
    });
  }

  debugPrint("⚠️ تسجيل غير صالح لـ $targetWord → 0%");
  return;
}

      if (data['status'] == 'success' &&
          data.containsKey('score')) {
        final double wordScore =
            (data['score'] as num).toDouble();

        if (mounted) {
          setState(() {
            _totalAccumulatedScore += wordScore;

            _individualScores.add({
              'letter': targetLetter,
              'score': wordScore.round(),
            });
          });
        }

        debugPrint("⭐ نتيجة $targetWord: $wordScore%");
      }
    }
  } catch (e) {
    debugPrint("⚠️ خطأ في الاتصال: $e");
  } finally {
    if (mounted) {
      setState(() {
        _pendingEvaluations--;
      });

      if (_isCalculatingFinalScore &&
          _pendingEvaluations == 0) {
        _navigateToResults();
      }
    }
  }
}

  void _handleNext() {
  if (_currentIndex < _placementWords.length - 1) {
    setState(() {
      _currentIndex++;
      _showNext = false;
      _isRecording = false;
    });
  } else {
    if (_pendingEvaluations > 0) {
      setState(() {
        _isCalculatingFinalScore = true;
      });
    } else {
      _navigateToResults();
    }
  }
}
Widget _buildFinalCalculatingScreen() {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          color: _purple,
          strokeWidth: 4,
        ),
        SizedBox(height: 24),
        Text(
          'جاري إعداد نتيجتك يا بطل... 🚀',
          style: TextStyle(
            color: _purple,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    ),
  );
}
  void _navigateToResults() {
    double finalPlacementPercentage = _placementWords.isEmpty
        ? 0
        : _totalAccumulatedScore / _placementWords.length;

    Map<String, List<int>> groupedScores = {};
    for (var item in _individualScores) {
      String letter = item['letter'];
      int score = item['score'] as int;

      if (!groupedScores.containsKey(letter)) {
        groupedScores[letter] = [];
      }
      groupedScores[letter]!.add(score);
    }

    List<Map<String, dynamic>> finalLetterScores = [];
    groupedScores.forEach((letter, scores) {
      double average = scores.reduce((a, b) => a + b) / scores.length;
      finalLetterScores.add({'letter': letter, 'score': average.round()});
    });

    Navigator.pushReplacementNamed(
      context,
      '/child/placement-result',
      arguments: {
        'childId': widget.childId,
        'score': finalPlacementPercentage.round(),
        'letterScores': finalLetterScores,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: _isLoading
    ? const Center(
        child: CircularProgressIndicator(
          color: _purple,
        ),
      )
    : _isCalculatingFinalScore
        ? _buildFinalCalculatingScreen()
        : _placementWords.isEmpty
            ? const Center(
                child: Text(
                  'لا توجد كلمات في قاعدة البيانات',
                  style: TextStyle(fontFamily: 'Tajawal', fontSize: 18),
                ),
              )
            : Column(
                children: [
                  _buildHeader(),

                  Expanded(
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: IgnorePointer(child: _PlacementBackground()),
                        ),

                        SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                          child: _buildCard(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return FaseehStyle.buildLargeHeader(
      context: context,

      title: 'اختبار تحديد المستوى',

      subtitle:
          'الكلمة ${toArabicDigits(_currentIndex + 1)} من ${toArabicDigits(_placementWords.length)}',

      leading: SizedBox(
        width: 88,
        height: 48,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر الرجوع
            SizedBox(
              width: 44,
              height: 48,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/child/home',
                    (route) => false,
                    arguments: widget.childId,
                  );
                },
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 25,
                ),
              ),
            ),

            // أيقونة الـ Placement Test
            const SizedBox(
              width: 38,
              height: 48,
              child: Center(
                child: Icon(
                  Icons.record_voice_over_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),

      trailingActions: const [SizedBox(width: 48, height: 48)],
    );
  }

  // ===========================================================================
  // MAIN CONTENT
  // ===========================================================================
  Widget _buildCard() {
    return Column(
      children: [
        // ===============================================================
        // Bunny instruction card
        // ===============================================================
        const _PlacementGuideCard(),

        const SizedBox(height: 14),

        // ===============================================================
        // Progress
        // ===============================================================
        _buildProgressBar(),

        const SizedBox(height: 14),

        // ===============================================================
        // Word + recording section
        // ===============================================================
        _buildWordSection(),
      ],
    );
  }

  // ===========================================================================
  // PROGRESS
  // ===========================================================================
  Widget _buildProgressBar() {
    final percent = (_progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF7FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _purple.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE0FA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: Color(0xFF8B55B3),
                  size: 20,
                ),
              ),

              const SizedBox(width: 9),

              const Expanded(
                child: Text(
                  'تقدّمك في الاختبار',
                  style: TextStyle(
                    color: _purple,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7EC),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${toArabicDigits(percent)}٪',
                  style: const TextStyle(
                    color: _coral,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE9DDF3),
              valueColor: const AlwaysStoppedAnimation<Color>(_coral),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WORD SECTION
  // ===========================================================================
  Widget _buildWordSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _purple.withOpacity(0.07)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ===============================================================
          // Question instruction
          // ===============================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE4EA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, color: _coral, size: 19),
              ),

              const SizedBox(width: 8),

              const Text(
                'قل الكلمة بصوت واضح',
                style: TextStyle(
                  color: _purple,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildWordDisplay(),

          const SizedBox(height: 16),

          _buildRecordingSection(),
        ],
      ),
    );
  }

  // ===========================================================================
  // WORD DISPLAY
  // ===========================================================================
  Widget _buildWordDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _purple.withOpacity(0.07)),
      ),
      child: Stack(
        children: [
          // ===============================================================
          // Pastel decorations
          // ===============================================================
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFFDCC9F5).withOpacity(0.24),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: -35,
            bottom: -55,
            child: Container(
              width: 120,
              height: 95,
              decoration: BoxDecoration(
                color: const Color(0xFFDDF2E3).withOpacity(0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // ===============================================================
          // Centered content
          // ===============================================================
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // =========================================================
                // Image
                // =========================================================
                Center(
                  child: Container(
                    width: 160,
                    height: 150,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.86),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(child: _buildWordImage()),
                  ),
                ),

                const SizedBox(height: 15),

                // =========================================================
                // Word
                // =========================================================
                Center(
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 170),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.82),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFDCC9EB).withOpacity(0.70),
                      ),
                    ),
                    child: Text(
                      _currentWord.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 46,
                        color: _purple,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Tajawal',
                        height: 1.25,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WORD IMAGE
  // نفس الوظيفة الأصلية
  // ===========================================================================
  Widget _buildWordImage() {
    return Image.network(
      _currentWord.imageUrl,
      width: 130,
      height: 130,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Icon(
        Icons.image_not_supported_rounded,
        size: 50,
        color: _purple,
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return SizedBox(
          width: 130,
          height: 130,
          child: Center(
            child: CircularProgressIndicator(
              color: _purple,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // RECORDING SECTION
  // نفس المنطق
  // ===========================================================================
  Widget _buildRecordingSection() {
  return Column(
    children: [
      if (!_recorded[_currentIndex])
        _buildRecordButton()
      else
        _buildSuccessIndicator(),

      if (_showNext) ...[
        const SizedBox(height: 12),
        _buildNextButton(),
      ],
    ],
  );
}



  // ===========================================================================
  // RECORD BUTTON
  // نفس functionality
  // ===========================================================================
  Widget _buildRecordButton() {
    if (_isRecording) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _pulseAnimation.value, child: child),
        child: _recordButtonWidget(isRecording: true),
      );
    }

    return _recordButtonWidget(isRecording: false);
  }

  Widget _recordButtonWidget({required bool isRecording}) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _handleRecordToggle,
        style: ElevatedButton.styleFrom(
          backgroundColor: isRecording ? _coral : _purple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(width: 9),

            Text(
              isRecording ? 'إيقاف التسجيل' : 'ابدأ التسجيل',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SUCCESS
  // ===========================================================================
  Widget _buildSuccessIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF8F0),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF8BC8A0).withOpacity(0.30)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF69AD7D), size: 23),

          SizedBox(width: 8),

          Text(
            'تم التسجيل بنجاح!',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF578F68),
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NEXT BUTTON
  // نفس functionality
  // ===========================================================================
  Widget _buildNextButton() {
    final isLast = _currentIndex == _placementWords.length - 1;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: _coral,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLast ? 'عرض النتائج' : 'الكلمة التالية',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Tajawal',
              ),
            ),

            const SizedBox(width: 8),

            Icon(
              isLast
                  ? Icons.check_circle_outline_rounded
                  : Icons.arrow_back_rounded,
              size: 21,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PLACEMENT PAGE BACKGROUND
// =============================================================================

class _PlacementBackground extends StatelessWidget {
  const _PlacementBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 45,
          right: -55,
          child: _circle(150, const Color(0xFFDCC9F5).withOpacity(0.18)),
        ),

        Positioned(
          top: 330,
          left: -65,
          child: _circle(155, const Color(0xFFDDF2E3).withOpacity(0.25)),
        ),

        Positioned(
          bottom: 90,
          right: -45,
          child: _circle(120, const Color(0xFFFFDCE3).withOpacity(0.22)),
        ),

        Positioned(
          bottom: 35,
          left: 38,
          child: _circle(19, const Color(0xFFD5BFE9).withOpacity(0.33)),
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

// =============================================================================
// INSTRUCTION CARD
// =============================================================================

class _PlacementGuideCard extends StatelessWidget {
  const _PlacementGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 162),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF511281).withOpacity(0.07)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Purple circle
            Positioned(
              right: -55,
              top: -60,
              child: Container(
                width: 155,
                height: 155,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5).withOpacity(0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Green hill
            Positioned(
              left: -30,
              bottom: -45,
              child: Container(
                width: 180,
                height: 95,
                decoration: BoxDecoration(
                  color: const Color(0xFFCAEBCF).withOpacity(0.65),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(100),
                    topRight: Radius.circular(100),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(13, 12, 15, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // =========================================================
                  // Signature bunny
                  // =========================================================
                  const SizedBox(
                    width: 105,
                    height: 132,
                    child: _PlacementBunny(),
                  ),

                  const SizedBox(width: 10),

                  // =========================================================
                  // Instructions
                  // =========================================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'هيا، أرني نطقك!',
                          style: TextStyle(
                            color: Color(0xFF511281),
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Text(
                          'اتبع هذه الخطوات البسيطة',
                          style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 10.5,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 10),

                        const _GuideStep(
                          icon: Icons.image_outlined,
                          text: 'شاهد الصورة',
                          background: Color(0xFFFFE7EC),
                          iconColor: Color(0xFFFF7890),
                        ),

                        const SizedBox(height: 6),

                        const _GuideStep(
                          icon: Icons.mic_rounded,
                          text: 'اضغط على الميكروفون',
                          background: Color(0xFFE5F4EA),
                          iconColor: Color(0xFF64A97A),
                        ),

                        const SizedBox(height: 6),

                        const _GuideStep(
                          icon: Icons.record_voice_over_rounded,
                          text: 'قل الكلمة بصوت واضح',
                          background: Color(0xFFFFF1C9),
                          iconColor: Color(0xFFD79A21),
                        ),
                      ],
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
}

// =============================================================================
// GUIDE STEP
// =============================================================================

class _GuideStep extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color iconColor;

  const _GuideStep({
    required this.icon,
    required this.text,
    required this.background,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 27,
          height: 27,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 15),
        ),

        const SizedBox(width: 7),

        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF625A66),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// SIGNATURE PLACEMENT BUNNY
// =============================================================================

class _PlacementBunny extends StatelessWidget {
  const _PlacementBunny();

  @override
  Widget build(BuildContext context) {
    const faceColor = Color(0xFFFFDCE7);
    const bodyColor = Color(0xFF8B55B3);
    const innerEarColor = Color(0xFFFFA1B7);
    const detailsColor = Color(0xFF4D3855);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // =========================================================
        // Speech bubble
        // =========================================================
        Positioned(
          top: 4,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'هيا!',
              style: TextStyle(
                color: Color(0xFF8B55B3),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
        ),

        // =========================================================
        // Small happy lines
        // =========================================================
        Positioned(
          top: 36,
          right: 5,
          child: Transform.rotate(
            angle: -0.35,
            child: Container(
              width: 4,
              height: 13,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD36A),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),

        Positioned(
          top: 45,
          right: 0,
          child: Transform.rotate(
            angle: 0.65,
            child: Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD36A),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),

        // =========================================================
        // Right ear
        // =========================================================
        Positioned(
          top: 16,
          right: 27,
          child: Transform.rotate(
            angle: 0.10,
            child: Container(
              width: 20,
              height: 44,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 27,
                  decoration: BoxDecoration(
                    color: innerEarColor.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // =========================================================
        // Left ear - slightly tilted
        // =========================================================
        Positioned(
          top: 22,
          left: 20,
          child: Transform.rotate(
            angle: -0.42,
            child: Container(
              width: 20,
              height: 44,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Container(
                  width: 7,
                  height: 27,
                  decoration: BoxDecoration(
                    color: innerEarColor.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),

        // =========================================================
        // Body
        // =========================================================
        Positioned(
          bottom: 0,
          child: Container(
            width: 50,
            height: 34,
            decoration: const BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(27),
                topRight: Radius.circular(27),
                bottomLeft: Radius.circular(13),
                bottomRight: Radius.circular(13),
              ),
            ),
          ),
        ),

        // =========================================================
        // Head
        // =========================================================
        Positioned(
          top: 50,
          child: Container(
            width: 65,
            height: 61,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(31),
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
                  top: 22,
                  right: 15,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 22,
                  left: 15,
                  child: Container(
                    width: 6,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: detailsColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 35,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Positioned(
                  top: 35,
                  left: 7,
                  child: Container(
                    width: 9,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF96AC).withOpacity(0.50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 30,
                  left: 29,
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
                  top: 37,
                  left: 23,
                  child: Container(
                    width: 19,
                    height: 8,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: detailsColor, width: 1.5),
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
