import 'package:flutter/material.dart';
 
// ─── Data Model ──────────────────────────────────────────────────────────────
class _PlacementWord {
  final int id;
  final String word;
  final String transliteration;
  final String targetLetter;
  final String imageUrl;
  final String imageAlt;
  final String fallbackEmoji;
 
  const _PlacementWord({
    required this.id,
    required this.word,
    required this.transliteration,
    required this.targetLetter,
    required this.imageUrl,
    required this.imageAlt,
    required this.fallbackEmoji,
  });
}
 
const List<_PlacementWord> _placementWords = [
  _PlacementWord(
    id: 1,
    word: 'قمر',
    transliteration: 'Qamar',
    targetLetter: 'ق',
    imageUrl: 'https://img.icons8.com/plasticine/100/crescent-moon.png',
    imageAlt: 'صورة قمر - هلال',
    fallbackEmoji: '🌙',
  ),
  _PlacementWord(
    id: 2,
    word: 'قلم',
    transliteration: 'Qalam',
    targetLetter: 'ق',
    imageUrl: 'https://img.icons8.com/fluency/96/pen.png',
    imageAlt: 'صورة قلم',
    fallbackEmoji: '✏️',
  ),
  _PlacementWord(
    id: 3,
    word: 'طبق',
    transliteration: 'Tabaq',
    targetLetter: 'ق',
    imageUrl: 'https://img.icons8.com/color/96/plate.png',
    imageAlt: 'صورة طبق',
    fallbackEmoji: '🍽️',
  ),
];
 
// ─── Screen ──────────────────────────────────────────────────────────────────
class PlacementTestScreen extends StatefulWidget {
  const PlacementTestScreen({super.key});
 
  @override
  State<PlacementTestScreen> createState() => _PlacementTestScreenState();
}
 
class _PlacementTestScreenState extends State<PlacementTestScreen>
    with SingleTickerProviderStateMixin {
  static const _purple = Color(0xFF511281);
  static const _coral = Color(0xFFFF6969);
  static const _bgColor = Color(0xFFFCF9EA);
 
  int _currentIndex = 0;
  List<bool> _recorded = [false, false, false];
  bool _isRecording = false;
  bool _showNext = false;
 
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
  }
 
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
 
  _PlacementWord get _currentWord => _placementWords[_currentIndex];
 
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
      });
    } else {
      Navigator.pushNamed(
        context,
        '/child/placement-result',
        arguments: {'testedLetter': 'ق'},
      );
    }
  }
 
  void _playExample() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تشغيل: ${_currentWord.word}'),
        backgroundColor: _purple,
        duration: const Duration(seconds: 1),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    // ✅ RTL wrapper
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: Column(
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
          begin: Alignment.topRight, // ✅ RTL: start from right
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
              // ✅ RTL: back arrow points forward (→) which is "back" in RTL
              IconButton(
                onPressed: () => Navigator.pushNamed(context, '/child/home'),
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
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
                  crossAxisAlignment: CrossAxisAlignment.start, // ✅ RTL: start = right
                  children: [
                    const Text(
                      'اختبار حرف ق',
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
            // ✅ RTL: percentage on right, label on left
            Text(
              'التقدم',
              style: const TextStyle(
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
          begin: Alignment.topRight, // ✅ RTL
          end: Alignment.bottomLeft,
          colors: [
            _purple.withOpacity(0.05),
            _coral.withOpacity(0.05),
          ],
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
                colors: [
                  _purple.withOpacity(0.1),
                  _coral.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _currentWord.word,
              style: const TextStyle(
                fontSize: 52,
                color: _purple,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              _currentWord.transliteration,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                letterSpacing: 0.5,
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
          errorBuilder: (context, error, stackTrace) => Text(
            _currentWord.fallbackEmoji,
            style: const TextStyle(fontSize: 72),
          ),
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
    return OutlinedButton.icon(
      onPressed: _playExample,
      icon: const Icon(Icons.volume_up_rounded, size: 22),
      label: const Text(
        '🔊 استمع إلى المثال',
        style: TextStyle(fontSize: 16, fontFamily: 'Tajawal'),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: _purple,
        side: const BorderSide(color: _purple, width: 2),
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
        if (_showNext) ...[
          const SizedBox(height: 14),
          _buildNextButton(),
        ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
          Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 26),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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