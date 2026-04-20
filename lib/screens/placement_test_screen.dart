import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/recording_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  static const _coral = Color(0xFFFF6969);
  static const _bgColor = Color(0xFFFCF9EA);

  // --- State Variables ---
  List<PlacementWord> _placementWords = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  List<bool> _recorded = [];
  bool _isRecording = false;
  bool _showNext = false;
  // متغير جديد لتتبع مجموع النسب المئوية لكل الكلمات
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
            // We don't use 'await' here so it happens seamlessly in the background
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
      print("Error fetching words: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose(); // تنظيف الأنيميشن
    _recordingService.dispose(); // تنظيف المايكروفون
    _audioPlayer.dispose(); // تنظيف المشغل (إذا أضفتيه)
    super.dispose();
  }

  PlacementWord get _currentWord => _placementWords[_currentIndex];

  double get _progress => _placementWords.isEmpty
      ? 0
      : (_currentIndex + (_recorded[_currentIndex] ? 1 : 0)) /
            _placementWords.length;

  void _handleRecordToggle() async {
    if (_isRecording) {
      // إيقاف التسجيل
      final path = await _recordingService.stop();

      setState(() {
        _lastRecordedPath = path;
        _isRecording = false;
        _recorded[_currentIndex] = true;
        // ⚠️ أزلنا _showNext = true من هنا لكي لا يضغط الطفل "التالي" قبل وصول النتيجة
      });

      _pulseController.stop();
      _pulseController.reset();

      // ✅ ننتظر السيرفر حتى ينتهي من التقييم
      await _startPreprocessing(path);

      // ✅ بعد أن ينتهي السيرفر ويحفظ النتيجة، نظهر زر "التالي"
      if (mounted) {
        setState(() {
          _showNext = true;
        });
      }
    } else {
      // بدء التسجيل بعد التأكد من الإذن
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
          const SnackBar(content: Text('الرجاء السماح بالوصول للمايكروفون')),
        );
      }
    }
  }

  /// الدالة المحدثة للربط بالسحاب (Google Cloud Run) والتقييم
  Future<void> _startPreprocessing(String? path) async {
    if (path == null) return;

    const String baseUrl =
        "https://faseeh-api-816737402071.me-central1.run.app";
    final url = Uri.parse('$baseUrl/process-audio/');

    print("🚀 جاري إرسال الملف إلى سحابة جوجل: $path");
    print("🎯 الكلمة المستهدفة للتقييم: ${_currentWord.text}");

    try {
      var request = http.MultipartRequest('POST', url);

      request.files.add(await http.MultipartFile.fromPath('file', path));
      request.fields['target_word'] = _currentWord.text;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);

        // 🚨 DIAGNOSTIC PRINT: This will tell us EXACTLY what the server is returning!
        print("📥 رد السيرفر: $data");

        if (data['status'] == 'success' && data.containsKey('score')) {
          double wordScore = (data['score'] as num).toDouble();

          setState(() {
            _totalAccumulatedScore += wordScore;
            _individualScores.add({
              'letter': _currentWord.targetLetter,
              'score': wordScore.round(),
            });
          });

          print("⭐ نتيجة الكلمة: $wordScore%");
        } else if (data['status'] == 'error') {
          // 🚨 IF THE AI FAILS, THIS WILL PRINT THE EXACT REASON
          print("⚠️ السيرفر واجه مشكلة داخلية: ${data['message']}");
        } else {
          print(
            "⚠️ السيرفر رد بنجاح ولكن لم يرسل تقييم (score). هل السيرفر محدث؟",
          );
        }
      } else {
        print("❌ فشل سيرفر جوجل: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("⚠️ خطأ في الاتصال بسيرفر جوجل كلاود: $e");
    }
  }

  void _handleNext() {
    if (_currentIndex < _placementWords.length - 1) {
      // الانتقال للكلمة التالية
      setState(() {
        _currentIndex++;
        _showNext = false;
        _isRecording = false;
      });
    } else {
      // انتهى الاختبار! نحسب النسبة النهائية
      double finalPlacementPercentage =
          _totalAccumulatedScore / _placementWords.length;

      // الانتقال لشاشة النتائج وتمرير البيانات الكاملة
      Navigator.pushNamed(
        context,
        '/child/placement-result',
        arguments: {
          'childId': widget.childId,
          'score': finalPlacementPercentage.round(),
          'letterScores': _individualScores, // تمرير تفاصيل الحروف
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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _purple))
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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildCard(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF6A3A9E), _purple],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/child/home',
                  (route) => false,
                  arguments: widget.childId,
                ),
                icon: const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: 28,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'اختبار تحديد المستوى',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    Text(
                      'الكلمة ${_currentIndex + 1} من ${_placementWords.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _purple.withOpacity(0.1), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 6, color: _purple),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              children: [
                const Text(
                  'اقرأ الكلمة بصوت عالٍ',
                  style: TextStyle(
                    color: _purple,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildProgressBar(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildWordSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final percent = (_progress * 100).round();
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'التقدم',
              style: TextStyle(
                color: _purple,
                fontSize: 13,
                fontFamily: 'Tajawal',
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: _purple,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 12,
            backgroundColor: _purple.withOpacity(0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(_purple),
          ),
        ),
      ],
    );
  }

  Widget _buildWordSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_purple.withOpacity(0.05), _coral.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWordDisplay(),
          const SizedBox(height: 24),
          _buildRecordingSection(),
        ],
      ),
    );
  }

  Widget _buildWordDisplay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _purple.withOpacity(0.1), width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildWordImage(),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_purple.withOpacity(0.1), _coral.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _currentWord.text,
              style: const TextStyle(
                fontSize: 52,
                color: _purple,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWordImage() {
    // UPDATED: Purple circle background removed here
    return Image.network(
      _currentWord.imageUrl,
      width: 130, // Increased size slightly to fill space naturally
      height: 130,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.image_not_supported, size: 50, color: _purple),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
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

  Widget _buildRecordingSection() {
    return Column(
      children: [
        if (!_recorded[_currentIndex])
          _buildRecordButton()
        else
          _buildSuccessIndicator(),
        if (_showNext) ...[const SizedBox(height: 14), _buildNextButton()],
      ],
    );
  }

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
      height: 62,
      child: ElevatedButton.icon(
        onPressed: _handleRecordToggle,
        icon: const Icon(Icons.mic_rounded, size: 26),
        label: Text(
          isRecording ? ' إيقاف التسجيل' : ' ابدأ التسجيل',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isRecording ? _coral : _purple,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.shade200, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green.shade600,
            size: 26,
          ),
          const SizedBox(width: 10),
          // ✅ Wrap the Text in a Flexible widget so it doesn't overflow!
          Flexible(
            child: Text(
              'تم التسجيل بنجاح! ',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
                fontFamily: 'Tajawal',
              ),
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentIndex == _placementWords.length - 1;
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: _coral,
          foregroundColor: Colors.white,
          elevation: 5,
          shadowColor: _coral.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          isLast ? ' عرض النتائج' : '➡️ الكلمة التالية',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }
}
