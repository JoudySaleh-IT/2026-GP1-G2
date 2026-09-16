import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

import 'style_constants.dart';

// ---------------------------------------------------------------------------
// Retry state
// ---------------------------------------------------------------------------

enum RetryRecordingState {
  waitingForAudio,
  readyToRecord,
  recording,
  analyzing,
  technicalError,
  finished,
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ExerciseRecordingRetryScreen extends StatefulWidget {
  final String childId;
  final String letter;
  final String level;

  final String questionText;
  final String targetWord;
  final String imagePath;
  final String audioPath;

  const ExerciseRecordingRetryScreen({
    super.key,
    required this.childId,
    required this.letter,
    required this.level,
    required this.questionText,
    required this.targetWord,
    required this.imagePath,
    required this.audioPath,
  });

  @override
  State<ExerciseRecordingRetryScreen> createState() =>
      _ExerciseRecordingRetryScreenState();
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class _ExerciseRecordingRetryScreenState
    extends State<ExerciseRecordingRetryScreen>
    with SingleTickerProviderStateMixin {
  // -------------------------------------------------------------------------
  // Colors
  // -------------------------------------------------------------------------

  static const Color _deepPurple = Color(0xFF511281);
  static const Color _red = Color(0xFFFF6969);
  static const Color _bgYellow = Color(0xFFFCF9EA);

  // -------------------------------------------------------------------------
  // Audio / Recording
  // -------------------------------------------------------------------------

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();

  String? _recordedFilePath;

  // -------------------------------------------------------------------------
  // Retry state
  // -------------------------------------------------------------------------

  RetryRecordingState _state = RetryRecordingState.waitingForAudio;

  // Reference audio can only be played once.
  bool _audioPlayed = false;

  // The child can only record one real retry attempt.
  bool _recordingUsed = false;

  // Becomes true once the reference audio begins.
  bool _retryStarted = false;

  // Used only when returning programmatically.
  bool _allowProgrammaticPop = false;

  // -------------------------------------------------------------------------
  // Recording timer
  // -------------------------------------------------------------------------

  int _recordingTime = 0;
  Timer? _recordingTimer;

  // -------------------------------------------------------------------------
  // Final retry result
  // -------------------------------------------------------------------------

  int _finalScore = 0;
  bool _finalIsInvalid = false;
  String? _finalInvalidReason;

  // -------------------------------------------------------------------------
  // Technical error
  // -------------------------------------------------------------------------

  String? _technicalErrorMessage;

  // -------------------------------------------------------------------------
  // Animation
  // -------------------------------------------------------------------------

  late final AnimationController _spinController;

  // -------------------------------------------------------------------------
  // Init
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  // -------------------------------------------------------------------------
  // Dispose
  // -------------------------------------------------------------------------

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _spinController.dispose();
    _audioPlayer.dispose();
    _recorder.dispose();

    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Reference audio
  // -------------------------------------------------------------------------

  Future<void> _playReferenceAudio() async {
    if (_audioPlayed || _retryStarted) {
      return;
    }

    try {
      await _audioPlayer.stop();

      if (!mounted) return;

      setState(() {
        _retryStarted = true;
        _audioPlayed = true;
        _state = RetryRecordingState.waitingForAudio;
      });

      final audioCompleted = _audioPlayer.onPlayerComplete.first;

      await _audioPlayer.play(AssetSource(widget.audioPath));

      debugPrint('Retry reference audio started: ${widget.audioPath}');

      await audioCompleted;

      if (!mounted) return;

      setState(() {
        _state = RetryRecordingState.readyToRecord;
      });

      debugPrint('Retry reference audio completed.');
    } catch (e) {
      debugPrint('Retry audio error: $e');

      if (!mounted) return;

      setState(() {
        _retryStarted = false;
        _audioPlayed = false;
        _state = RetryRecordingState.waitingForAudio;
      });

      _showAppSnackBar('تعذر تشغيل صوت الكلمة', isError: true);
    }
  }

  // -------------------------------------------------------------------------
  // Start recording
  // -------------------------------------------------------------------------

  Future<void> _startRecording() async {
    if (!_audioPlayed ||
        _recordingUsed ||
        _state != RetryRecordingState.readyToRecord) {
      return;
    }

    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      if (!mounted) return;

      _showAppSnackBar('نحتاج إذن الميكروفون لتسجيل صوتك', isError: true);

      return;
    }

    try {
      final directory = await getTemporaryDirectory();

      final path =
          '${directory.path}/retry_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );

      if (!mounted) return;

      setState(() {
        _recordingUsed = true;
        _recordedFilePath = null;
        _recordingTime = 0;
        _technicalErrorMessage = null;

        _state = RetryRecordingState.recording;
      });

      _recordingTimer?.cancel();

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;

        setState(() {
          _recordingTime++;
        });
      });
    } catch (e) {
      debugPrint('Retry recording start error: $e');

      if (!mounted) return;

      setState(() {
        _recordingUsed = false;
        _state = RetryRecordingState.readyToRecord;
      });

      _showAppSnackBar('تعذر بدء التسجيل، حاول مرة أخرى', isError: true);
    }
  }

  // -------------------------------------------------------------------------
  // Stop recording
  // -------------------------------------------------------------------------

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();

      _recordingTimer?.cancel();

      if (path == null) {
        if (!mounted) return;

        setState(() {
          _recordedFilePath = null;

          _technicalErrorMessage =
              'تعذر حفظ التسجيل. يمكنك تسجيل الكلمة مرة أخرى دون إعادة الاستماع.';

          _state = RetryRecordingState.technicalError;
        });

        return;
      }

      if (!mounted) return;

      setState(() {
        _recordedFilePath = path;

        _state = RetryRecordingState.analyzing;
      });

      debugPrint('Retry recording saved at: $_recordedFilePath');

      await _analyzeRecording();
    } catch (e) {
      debugPrint('Retry recording stop error: $e');

      _recordingTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _recordedFilePath = null;

        _technicalErrorMessage =
            'حدثت مشكلة أثناء حفظ التسجيل. يمكنك تسجيل الكلمة مرة أخرى.';

        _state = RetryRecordingState.technicalError;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Backend analysis
  // -------------------------------------------------------------------------

  Future<void> _analyzeRecording() async {
    if (_recordedFilePath == null) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _technicalErrorMessage = null;
      _state = RetryRecordingState.analyzing;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://faseeh-api-best-model-816737402071.me-central1.run.app/process-audio/',
        ),
      );

      request.fields['target_word'] = widget.targetWord;

      request.fields['target_letter'] = widget.letter;

      request.files.add(
        await http.MultipartFile.fromPath('file', _recordedFilePath!),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      // ---------------------------------------------------------------
      // Valid analyzed pronunciation
      // ---------------------------------------------------------------

      if (data['status'] == 'success') {
        final score = (data['score'] as num?)?.round() ?? 0;

        if (!mounted) return;

        setState(() {
          _finalScore = score;
          _finalIsInvalid = false;
          _finalInvalidReason = null;
          _technicalErrorMessage = null;

          _state = RetryRecordingState.finished;
        });

        debugPrint('Retry transcription: ${data['transcription_heard']}');

        debugPrint('Retry score: $score');

        return;
      }

      // ---------------------------------------------------------------
      // Invalid retry
      // ---------------------------------------------------------------

      if (data['status'] == 'invalid_audio') {
        if (!mounted) return;

        setState(() {
          _finalScore = 0;
          _finalIsInvalid = true;

          _finalInvalidReason = data['reason']?.toString();

          _technicalErrorMessage = null;

          _state = RetryRecordingState.finished;
        });

        debugPrint('Retry invalid: ${data['reason']}');

        return;
      }

      throw Exception(data['message']?.toString() ?? 'Unknown backend error');
    } catch (e) {
      debugPrint('Retry analysis / connection error: $e');

      if (!mounted) return;

      setState(() {
        _technicalErrorMessage =
            'تعذر تحليل التسجيل بسبب مشكلة في الاتصال. تسجيلك محفوظ ويمكنك إرساله مرة أخرى.';

        _state = RetryRecordingState.technicalError;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Resend same recording
  // -------------------------------------------------------------------------

  Future<void> _resendRecording() async {
    if (_recordedFilePath == null) {
      return;
    }

    await _analyzeRecording();
  }

  // -------------------------------------------------------------------------
  // Retry after local recording failure
  // -------------------------------------------------------------------------

  void _retryRecordingAfterLocalError() {
    setState(() {
      _recordingUsed = false;
      _recordedFilePath = null;
      _recordingTime = 0;
      _technicalErrorMessage = null;

      _state = RetryRecordingState.readyToRecord;
    });
  }

  // -------------------------------------------------------------------------
  // Return final result
  // -------------------------------------------------------------------------

  void _returnToResults() {
    final result = <String, dynamic>{
      'score': _finalScore,
      'isInvalid': _finalIsInvalid,
      'invalidReason': _finalInvalidReason,
      'retryUsed': true,
    };

    setState(() {
      _allowProgrammaticPop = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.pop(context, result);
    });
  }

  // -------------------------------------------------------------------------
  // Back handling
  // -------------------------------------------------------------------------

  void _handleHeaderBack() {
    if (!_retryStarted) {
      Navigator.pop(context);
      return;
    }

    _showAppSnackBar('أكمل محاولتك الأخيرة أولًا', isError: false);
  }

  // -------------------------------------------------------------------------
  // Snackbar
  // -------------------------------------------------------------------------

  void _showAppSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.fixed,

        backgroundColor: isError ? _red : _deepPurple,

        content: Directionality(
          textDirection: TextDirection.rtl,

          child: Align(
            alignment: Alignment.centerRight,

            child: Text(
              message,

              textAlign: TextAlign.right,

              style: const TextStyle(
                fontFamily: 'Tajawal',
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: PopScope(
        canPop: !_retryStarted || _allowProgrammaticPop,

        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _retryStarted && !_allowProgrammaticPop) {
            _showAppSnackBar('أكمل محاولتك الأخيرة أولًا', isError: false);
          }
        },

        child: Scaffold(
          backgroundColor: _bgYellow,

          body: Column(
            children: [
              _buildHeader(),

              Expanded(
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: IgnorePointer(child: _RetryBackground()),
                    ),

                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 50),

                      child: _buildRetryPanel(),
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

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      decoration: FaseehStyle.headerDecoration,

      padding: FaseehStyle.getStandardPadding(context),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          IconButton(
            onPressed: _handleHeaderBack,

            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 25),
          ),

          const SizedBox(width: 8),

          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  'إعادة المحاولة',

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tajawal',
                  ),
                ),

                Text(
                  'استمع إلى الكلمة ثم جرّب مرة أخرى',

                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Main retry panel
  // -------------------------------------------------------------------------

  Widget _buildRetryPanel() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: const Color(0xFFF8F2FF),

        borderRadius: BorderRadius.circular(26),

        border: Border.all(color: _deepPurple.withOpacity(0.08)),

        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        children: [
          _buildInstructionRow(),

          const SizedBox(height: 13),

          _buildWordDisplay(),

          const SizedBox(height: 13),

          _buildRecordingBox(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Child-friendly instruction area
  // -------------------------------------------------------------------------

  Widget _buildInstructionRow() {
    return SizedBox(
      width: double.infinity,

      child: Row(
        children: [
          const SizedBox(
            width: 76,
            height: 90,

            child: _CutePronunciationCharacter(),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Container(
                      width: 29,
                      height: 29,

                      alignment: Alignment.center,

                      decoration: const BoxDecoration(
                        color: _red,
                        shape: BoxShape.circle,
                      ),

                      child: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ),

                    const SizedBox(width: 7),

                    const Expanded(
                      child: Text(
                        'جرّب مرة ثانية!',

                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          color: _deepPurple,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                const Text(
                  'استمع إلى الكلمة ثم انطقها',

                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFF444444),
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),

                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEF),

                    borderRadius: BorderRadius.circular(14),
                  ),

                  child: const Text(
                    'محاولتك الأخيرة',

                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: _red,
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

  // -------------------------------------------------------------------------
  // Word display
  // -------------------------------------------------------------------------

  Widget _buildWordDisplay() {
    final bool disableAudioButton =
        _audioPlayed ||
        _retryStarted ||
        _state == RetryRecordingState.recording ||
        _state == RetryRecordingState.analyzing ||
        _state == RetryRecordingState.technicalError ||
        _state == RetryRecordingState.finished;

    String audioLabel;

    if (!_audioPlayed) {
      audioLabel = 'استمع إلى الكلمة';
    } else if (_state == RetryRecordingState.waitingForAudio) {
      audioLabel = 'جاري الاستماع...';
    } else {
      audioLabel = 'تم الاستماع';
    }

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(vertical: 21, horizontal: 14),

      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),

        borderRadius: BorderRadius.circular(21),

        border: Border.all(color: _deepPurple.withOpacity(0.07)),
      ),

      child: Column(
        children: [
          Image.asset(
            widget.imagePath,

            height: 130,
            width: 130,

            fit: BoxFit.contain,

            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 130,
                height: 130,

                alignment: Alignment.center,

                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3F9),

                  borderRadius: BorderRadius.circular(18),
                ),

                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Color(0xFFB5A7BB),
                  size: 40,
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          Text(
            widget.questionText,

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontSize: 43,
              color: _deepPurple,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
              height: 1.25,
            ),
          ),

          const SizedBox(height: 13),

          OutlinedButton.icon(
            onPressed: disableAudioButton ? null : _playReferenceAudio,

            icon: Icon(
              _audioPlayed ? Icons.check_rounded : Icons.volume_up_rounded,

              color: _audioPlayed ? const Color(0xFF999999) : _red,

              size: 17,
            ),

            label: Text(
              audioLabel,

              style: const TextStyle(
                fontSize: 11.5,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),

            style: OutlinedButton.styleFrom(
              foregroundColor: _audioPlayed ? const Color(0xFF999999) : _red,

              side: BorderSide(
                color: _audioPlayed
                    ? const Color(0xFFD6D0D8)
                    : _red.withOpacity(0.45),
              ),

              backgroundColor: const Color(0xFFFFF6F7),

              shape: const StadiumBorder(),

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),

          const SizedBox(height: 7),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EBFA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'محاولات الاستماع: ${_audioPlayed ? 1 : 0} من 1',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: _deepPurple,
              ),
            ),
          ),

          if (!_audioPlayed) ...[
            const SizedBox(height: 7),

            const Text(
              'استمع أولًا، وبعدها يفتح لك التسجيل',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Recording box
  // -------------------------------------------------------------------------

  Widget _buildRecordingBox() {
    return Container(
      width: double.infinity,

      constraints: const BoxConstraints(minHeight: 175),

      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),

      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFB),

        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: _red.withOpacity(0.10)),
      ),

      child: switch (_state) {
        RetryRecordingState.waitingForAudio => _buildWaitingState(),

        RetryRecordingState.readyToRecord => _buildReadyState(),

        RetryRecordingState.recording => _buildRecordingState(),

        RetryRecordingState.analyzing => _buildAnalyzingState(),

        RetryRecordingState.technicalError => _buildTechnicalErrorState(),

        RetryRecordingState.finished => _buildFinishedState(),
      },
    );
  }

  // -------------------------------------------------------------------------
  // Waiting
  // -------------------------------------------------------------------------

  Widget _buildWaitingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Stack(
          alignment: Alignment.center,

          children: [
            Container(
              width: 86,
              height: 86,

              decoration: BoxDecoration(
                color: const Color(0xFFF3EBFA),

                shape: BoxShape.circle,
              ),
            ),

            const Icon(Icons.hearing_rounded, color: _deepPurple, size: 42),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          _audioPlayed ? 'استمع جيدًا...' : 'استمع إلى الكلمة أولًا',

          textAlign: TextAlign.center,

          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: _deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          _audioPlayed
              ? 'بعد انتهاء الصوت سيظهر لك زر التسجيل'
              : 'اضغط زر الاستماع الموجود فوق',

          textAlign: TextAlign.center,

          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10.5,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Ready to record
  // -------------------------------------------------------------------------

  Widget _buildReadyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        GestureDetector(
          onTap: _startRecording,

          child: Stack(
            alignment: Alignment.center,

            children: [
              Container(
                width: 102,
                height: 102,

                decoration: BoxDecoration(
                  color: _red.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),

              Container(
                width: 82,
                height: 82,

                decoration: BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,

                  boxShadow: [
                    BoxShadow(
                      color: _red.withOpacity(0.22),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),

                child: const Icon(
                  Icons.mic_rounded,
                  color: Colors.white,
                  size: 39,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'اضغط وابدأ النطق',

          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: _deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        const Text(
          'هذه محاولتك الأخيرة لهذه الكلمة',

          textAlign: TextAlign.center,

          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10.5,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Recording
  // -------------------------------------------------------------------------

  Widget _buildRecordingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        GestureDetector(
          onTap: _stopRecording,

          child: Stack(
            alignment: Alignment.center,

            children: [
              Container(
                width: 102,
                height: 102,

                decoration: BoxDecoration(
                  color: _red.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
              ),

              Container(
                width: 82,
                height: 82,

                decoration: const BoxDecoration(
                  color: _red,
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'جاري تسجيل صوتك...',

          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 13,
            color: _deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),

        const Text(
          'اضغط زر الإيقاف عند الانتهاء',

          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 9.5,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Analyzing
  // -------------------------------------------------------------------------

  Widget _buildAnalyzingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        AnimatedBuilder(
          animation: _spinController,

          builder: (_, __) {
            return Transform.rotate(
              angle: _spinController.value * 2 * pi,

              child: Container(
                width: 68,
                height: 68,

                decoration: BoxDecoration(
                  color: const Color(0xFFF8F0FF),

                  shape: BoxShape.circle,

                  border: Border.all(
                    color: _red,
                    width: 4,

                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),

                child: ClipOval(child: CustomPaint(painter: _ArcPainter())),
              ),
            );
          },
        ),

        const SizedBox(height: 13),

        const Text(
          'جاري تحليل نطقك...',

          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            color: _deepPurple,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        const Text(
          'لحظات قليلة',

          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10.5,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Technical error
  // -------------------------------------------------------------------------

  Widget _buildTechnicalErrorState() {
    final bool hasSavedRecording = _recordedFilePath != null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,

      children: [
        Container(
          width: 68,
          height: 68,

          decoration: const BoxDecoration(
            color: Color(0xFFFFECEF),
            shape: BoxShape.circle,
          ),

          child: const Icon(Icons.wifi_off_rounded, color: _red, size: 34),
        ),

        const SizedBox(height: 11),

        const Text(
          'حدثت مشكلة بسيطة',

          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _deepPurple,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          _technicalErrorMessage ?? 'تعذر إكمال العملية، حاول مرة أخرى.',

          textAlign: TextAlign.center,

          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10.5,
            height: 1.5,
            color: Color(0xFF777777),
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,

          child: ElevatedButton.icon(
            onPressed: hasSavedRecording
                ? _resendRecording
                : _retryRecordingAfterLocalError,

            icon: Icon(
              hasSavedRecording
                  ? Icons.cloud_upload_rounded
                  : Icons.mic_rounded,

              size: 18,
            ),

            label: Text(
              hasSavedRecording ? 'إعادة الإرسال' : 'تسجيل مرة أخرى',

              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor: _deepPurple,

              foregroundColor: Colors.white,

              elevation: 0,

              shape: const StadiumBorder(),

              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),

        if (hasSavedRecording) ...[
          const SizedBox(height: 7),

          const Text(
            'تسجيلك محفوظ، لن تحتاج إلى تسجيل الكلمة مرة أخرى',

            textAlign: TextAlign.center,

            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 9.5,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Finished
  // -------------------------------------------------------------------------

  Widget _buildFinishedState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFEAF7EF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF67AF82),
            size: 38,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'تم التسجيل بنجاح',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _deepPurple,
          ),
        ),

        const SizedBox(height: 4),

        const Text(
          'تم حفظ محاولتك الجديدة',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 10.5,
            color: Color(0xFF999999),
          ),
        ),

        const SizedBox(height: 14),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _returnToResults,

            icon: const Icon(Icons.arrow_back_rounded, size: 18),

            label: const Text(
              'العودة للنتائج',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Background
// ---------------------------------------------------------------------------

class _RetryBackground extends StatelessWidget {
  const _RetryBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 40,
          right: -55,

          child: _circle(145, const Color(0xFFDCC9F5).withOpacity(0.18)),
        ),

        Positioned(
          top: 240,
          left: -55,

          child: _circle(145, const Color(0xFFDDF2E3).withOpacity(0.26)),
        ),

        Positioned(
          top: 500,
          right: -45,

          child: _circle(115, const Color(0xFFFFDCE3).withOpacity(0.24)),
        ),

        Positioned(
          top: 710,
          left: 25,

          child: _circle(21, const Color(0xFFD4BDEA).withOpacity(0.35)),
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

// ---------------------------------------------------------------------------
// Cute pronunciation character
// ---------------------------------------------------------------------------

class _CutePronunciationCharacter extends StatelessWidget {
  const _CutePronunciationCharacter();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);

    const Color purple = Color(0xFF8B55B3);

    const Color pink = Color(0xFFFF96AC);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,

      children: [
        // Right ear
        Positioned(
          top: 0,
          right: 11,

          child: Container(
            width: 18,
            height: 35,

            decoration: BoxDecoration(
              color: faceColor,

              borderRadius: BorderRadius.circular(18),
            ),

            child: Center(
              child: Container(
                width: 7,
                height: 22,

                decoration: BoxDecoration(
                  color: pink.withOpacity(0.48),

                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),

        // Left ear
        Positioned(
          top: 0,
          left: 11,

          child: Container(
            width: 18,
            height: 35,

            decoration: BoxDecoration(
              color: faceColor,

              borderRadius: BorderRadius.circular(18),
            ),

            child: Center(
              child: Container(
                width: 7,
                height: 22,

                decoration: BoxDecoration(
                  color: pink.withOpacity(0.48),

                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),

        // Body
        Positioned(
          bottom: 0,

          child: Container(
            width: 44,
            height: 27,

            decoration: const BoxDecoration(
              color: purple,

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(9),
                bottomRight: Radius.circular(9),
              ),
            ),
          ),
        ),

        // Head
        Positioned(
          top: 25,

          child: Container(
            width: 56,
            height: 52,

            decoration: BoxDecoration(
              color: faceColor,

              borderRadius: BorderRadius.circular(26),

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
                  top: 18,
                  right: 13,

                  child: Container(
                    width: 6,
                    height: 7,

                    decoration: const BoxDecoration(
                      color: Color(0xFF4D3855),

                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: 18,
                  left: 13,

                  child: Container(
                    width: 6,
                    height: 7,

                    decoration: const BoxDecoration(
                      color: Color(0xFF4D3855),

                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                // Cheeks
                Positioned(
                  top: 30,
                  right: 6,

                  child: Container(
                    width: 9,
                    height: 5,

                    decoration: BoxDecoration(
                      color: pink.withOpacity(0.45),

                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                Positioned(
                  top: 30,
                  left: 6,

                  child: Container(
                    width: 9,
                    height: 5,

                    decoration: BoxDecoration(
                      color: pink.withOpacity(0.45),

                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Nose
                Positioned(
                  top: 26,
                  left: 24,

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
                  top: 32,
                  left: 20,

                  child: Container(
                    width: 16,
                    height: 7,

                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Color(0xFF4D3855),
                          width: 1.4,
                        ),
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

        // Tiny microphone
        Positioned(
          right: 0,
          bottom: 7,

          child: Transform.rotate(
            angle: -0.25,

            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 17,

                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6969),

                    borderRadius: BorderRadius.circular(7),
                  ),
                ),

                Container(width: 3, height: 7, color: const Color(0xFF745183)),

                Container(
                  width: 10,
                  height: 2,

                  decoration: BoxDecoration(
                    color: const Color(0xFF745183),

                    borderRadius: BorderRadius.circular(3),
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

// ---------------------------------------------------------------------------
// Spinner
// ---------------------------------------------------------------------------

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF6969)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -pi / 2,
      3 * pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
