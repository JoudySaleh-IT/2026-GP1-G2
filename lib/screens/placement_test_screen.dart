import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────
class PlacementWord {
  final String wordId;
  final String text;
  final String targetLetter;
  final String imageUrl;
  final String audioUrl;

  const PlacementWord({
    required this.wordId,
    required this.text,
    required this.targetLetter,
    required this.imageUrl,
    required this.audioUrl,
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
  int _playCount = 0; // Tracks how many times they played the audio

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

    // Fetch words when screen loads
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

        // 1. Get raw gs:// URLs from Firestore
        String rawImageUrl = data['image_url'] ?? '';
        String rawAudioUrl = data['audio_url'] ?? '';

        // 2. Convert gs:// to playable/viewable https:// URLs using Firebase Storage
        String downloadImageUrl = '';
        String downloadAudioUrl = '';

        if (rawImageUrl.startsWith('gs://')) {
          downloadImageUrl = await FirebaseStorage.instance
              .refFromURL(rawImageUrl)
              .getDownloadURL();
        }

        if (rawAudioUrl.startsWith('gs://')) {
          downloadAudioUrl = await FirebaseStorage.instance
              .refFromURL(rawAudioUrl)
              .getDownloadURL();
        }

        fetchedWords.add(
          PlacementWord(
            wordId: data['word_id'] ?? doc.id,
            text: data['text'] ?? '',
            targetLetter: data['target_letter'] ?? '',
            imageUrl: downloadImageUrl,
            audioUrl: downloadAudioUrl,
          ),
        );
      }

      // 3. Shuffle the 18 words to make it random!
      fetchedWords.shuffle();

      setState(() {
        _placementWords = fetchedWords;
        _recorded = List<bool>.filled(_placementWords.length, false);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching words: $e");
      // TODO: Handle error UI (e.g., show a retry button)
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  PlacementWord get _currentWord => _placementWords[_currentIndex];

  double get _progress =>
      (_currentIndex + (_recorded[_currentIndex] ? 1 : 0)) /
      _placementWords.length;

  void _handleRecordToggle() {
    if (_isRecording) {
      final newRecorded = List<bool>.from(_recorded);
      newRecorded[_currentIndex] = true;
      setState(() {
        _recorded = newRecorded;
        _isRecording = false;
        _showNext = true;
      });
      _pulseController.stop();
      _pulseController.reset();
    } else {
      setState(() => _isRecording = true);
      _pulseController.repeat(reverse: true);
    }
  }

  void _handleNext() {
    if (_currentIndex < _placementWords.length - 1) {
      setState(() {
        _currentIndex++;
        _showNext = false;
        _isRecording = false;
        _playCount = 0; // Reset play count for the new word
      });
    } else {
      Navigator.pushNamed(
        context,
        '/child/placement-result',
        arguments: {
          'childId': widget.childId,
          // You might want to pass the whole recording list here later!
        },
      );
    }
  }

  void _playExample() {
    if (_playCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لقد استمعت للكلمة 3 مرات، حان دورك الآن!'),
          backgroundColor: _coral,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _playCount++;
    });

    // TODO: Implement actual audio playing using an audio package and _currentWord.audioUrl
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تشغيل: ${_currentWord.text} (المرة $_playCount من 3)'),
        backgroundColor: _purple,
        duration: const Duration(seconds: 1),
      ),
    );
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
          const SizedBox(height: 20),
          _buildListenButton(),
          const SizedBox(height: 16),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _purple.withOpacity(0.15),
          ),
        ),
        Image.network(
          _currentWord.imageUrl,
          width: 110,
          height: 110,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported, size: 50, color: _purple),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: 110,
              height: 110,
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
        ),
      ],
    );
  }

  Widget _buildListenButton() {
    // Determine if button should be greyed out
    bool isMaxPlaysReached = _playCount >= 3;

    return OutlinedButton.icon(
      onPressed: isMaxPlaysReached ? null : _playExample,
      icon: Icon(
        Icons.volume_up_rounded,
        size: 22,
        color: isMaxPlaysReached ? Colors.grey : _purple,
      ),
      label: Text(
        isMaxPlaysReached
            ? 'استمعت 3 مرات'
            : '🔊 استمع إلى المثال (${3 - _playCount})',
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Tajawal',
          color: isMaxPlaysReached ? Colors.grey : _purple,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _purple,
        side: BorderSide(
          color: isMaxPlaysReached ? Colors.grey : _purple,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
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
          isRecording ? '⏹ إيقاف التسجيل' : '🎙 ابدأ التسجيل',
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
          Text(
            'تم التسجيل بنجاح! 🎉',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
              fontFamily: 'Tajawal',
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
          isLast ? '📊 عرض النتائج' : '➡️ الكلمة التالية',
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
