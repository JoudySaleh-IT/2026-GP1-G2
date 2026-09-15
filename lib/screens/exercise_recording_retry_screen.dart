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
  // From this moment, the child cannot leave the retry flow.
  bool _retryStarted = false;

  // Used only when returning programmatically to the results page.
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
    // Reference audio is allowed only once.
    if (_audioPlayed || _retryStarted) {
      return;
    }

    try {
      await _audioPlayer.stop();

      if (!mounted) return;

      // ---------------------------------------------------------------
      // Retry starts here.
      //
      // Once the child begins listening to the reference audio,
      // leaving this page is no longer allowed.
      // ---------------------------------------------------------------

      setState(() {
        _retryStarted = true;
        _audioPlayed = true;
        _state = RetryRecordingState.waitingForAudio;
      });

      // Subscribe to completion BEFORE starting playback.
      final audioCompleted = _audioPlayer.onPlayerComplete.first;

      await _audioPlayer.play(
        AssetSource(widget.audioPath),
      );

      debugPrint(
        'Retry reference audio started: ${widget.audioPath}',
      );

      // ---------------------------------------------------------------
      // Wait until the reference audio finishes completely.
      //
      // Recording is NOT enabled while the example is still playing.
      // ---------------------------------------------------------------

      await audioCompleted;

      if (!mounted) return;

      setState(() {
        _state = RetryRecordingState.readyToRecord;
      });

      debugPrint(
        'Retry reference audio completed.',
      );
    } catch (e) {
      debugPrint(
        'Retry audio error: $e',
      );

      if (!mounted) return;

      // The audio did not play correctly.
      // Therefore, the retry has not actually been consumed.
      setState(() {
        _retryStarted = false;
        _audioPlayed = false;
        _state = RetryRecordingState.waitingForAudio;
      });

      _showAppSnackBar(
        'تعذر تشغيل صوت الكلمة',
        isError: true,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Start recording
  // -------------------------------------------------------------------------

  Future<void> _startRecording() async {
    // Recording is allowed only after hearing the reference audio
    // and only once.
    if (!_audioPlayed ||
        _recordingUsed ||
        _state != RetryRecordingState.readyToRecord) {
      return;
    }

    final hasPermission = await _recorder.hasPermission();

    if (!hasPermission) {
      if (!mounted) return;

      _showAppSnackBar(
        'نحتاج إذن الميكروفون لتسجيل صوتك',
        isError: true,
      );

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

      _recordingTimer = Timer.periodic(
        const Duration(seconds: 1),
        (timer) {
          if (!mounted) return;

          setState(() {
            _recordingTime++;
          });
        },
      );
    } catch (e) {
      debugPrint(
        'Retry recording start error: $e',
      );

      if (!mounted) return;

      // Recording never actually started successfully.
      // Do not consume the recording attempt.
      setState(() {
        _recordingUsed = false;
        _state = RetryRecordingState.readyToRecord;
      });

      _showAppSnackBar(
        'تعذر بدء التسجيل، حاول مرة أخرى',
        isError: true,
      );
    }
  }

  // -------------------------------------------------------------------------
  // Stop recording
  // -------------------------------------------------------------------------

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();

      _recordingTimer?.cancel();

      // ---------------------------------------------------------------
      // Local recording failure
      //
      // No usable recording file was created.
      // This is a technical issue, not the child's pronunciation result.
      // ---------------------------------------------------------------

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

      debugPrint(
        'Retry recording saved at: $_recordedFilePath',
      );

      await _analyzeRecording();
    } catch (e) {
      debugPrint(
        'Retry recording stop error: $e',
      );

      _recordingTimer?.cancel();

      if (!mounted) return;

      // This is a technical recording failure.
      // It is NOT counted as the child's final retry result.
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
        await http.MultipartFile.fromPath(
          'file',
          _recordedFilePath!,
        ),
      );

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      // ---------------------------------------------------------------
      // Server / HTTP problem
      //
      // Keep the exact same recording and allow resending.
      // Do NOT count this as the child's retry result.
      // ---------------------------------------------------------------

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Server returned ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body);

      // ---------------------------------------------------------------
      // Valid analyzed pronunciation
      // ---------------------------------------------------------------

      if (data['status'] == 'success') {
        final score =
            (data['score'] as num?)?.round() ?? 0;

        if (!mounted) return;

        setState(() {
          _finalScore = score;

          _finalIsInvalid = false;

          _finalInvalidReason = null;

          _technicalErrorMessage = null;

          _state = RetryRecordingState.finished;
        });

        debugPrint(
          'Retry transcription: ${data['transcription_heard']}',
        );

        debugPrint(
          'Retry score: $score',
        );

        return;
      }

      // ---------------------------------------------------------------
      // Backend successfully analyzed the recording,
      // but determined that the child's retry itself is invalid.
      //
      // This IS the child's second and final attempt.
      // No third attempt is provided.
      // ---------------------------------------------------------------

      if (data['status'] == 'invalid_audio') {
        if (!mounted) return;

        setState(() {
          _finalScore = 0;

          _finalIsInvalid = true;

          _finalInvalidReason =
              data['reason']?.toString();

          _technicalErrorMessage = null;

          _state = RetryRecordingState.finished;
        });

        debugPrint(
          'Retry invalid: ${data['reason']}',
        );

        return;
      }

      // ---------------------------------------------------------------
      // Backend returned an internal/system error.
      //
      // This is technical, so the child's recording is preserved
      // and can be sent again.
      // ---------------------------------------------------------------

      throw Exception(
        data['message']?.toString() ??
            'Unknown backend error',
      );
    } catch (e) {
      debugPrint(
        'Retry analysis / connection error: $e',
      );

      if (!mounted) return;

      // IMPORTANT:
      // Do not change _finalScore or _finalIsInvalid here.
      //
      // This was not a failed pronunciation attempt.
      // It was a technical problem.
      setState(() {
        _technicalErrorMessage =
            'تعذر تحليل التسجيل بسبب مشكلة في الاتصال. تسجيلك محفوظ ويمكنك إرساله مرة أخرى.';

        _state = RetryRecordingState.technicalError;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Resend SAME recording after network/server error
  // -------------------------------------------------------------------------

  Future<void> _resendRecording() async {
    if (_recordedFilePath == null) {
      return;
    }

    await _analyzeRecording();
  }

  // -------------------------------------------------------------------------
  // Retry recording only after LOCAL recording failure
  // -------------------------------------------------------------------------

  void _retryRecordingAfterLocalError() {
    // There is no saved recording file.
    // Therefore, the child may record again.
    //
    // The reference audio is NOT played again.
    setState(() {
      _recordingUsed = false;

      _recordedFilePath = null;

      _recordingTime = 0;

      _technicalErrorMessage = null;

      _state = RetryRecordingState.readyToRecord;
    });
  }

  // -------------------------------------------------------------------------
  // Return final result to results page
  // -------------------------------------------------------------------------

  void _returnToResults() {
    final result = <String, dynamic>{
      'score': _finalScore,
      'isInvalid': _finalIsInvalid,
      'invalidReason': _finalInvalidReason,
      'retryUsed': true,
    };

    // Temporarily allow this one programmatic pop.
    setState(() {
      _allowProgrammaticPop = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.pop(
        context,
        result,
      );
    });
  }

  // -------------------------------------------------------------------------
  // Back handling
  // -------------------------------------------------------------------------

  void _handleHeaderBack() {
    // Before the child starts the retry,
    // normal back navigation is allowed.
    if (!_retryStarted) {
      Navigator.pop(context);
      return;
    }

    // Once reference audio begins, the retry flow must be completed.
    _showAppSnackBar(
      'أكمل محاولتك الأخيرة أولًا',
      isError: false,
    );
  }

  // -------------------------------------------------------------------------
  // Snackbar
  // -------------------------------------------------------------------------

  void _showAppSnackBar(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.fixed,

        backgroundColor: isError
            ? _red
            : _deepPurple,

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
        // ---------------------------------------------------------------
        // Before retry starts:
        // Back is allowed.
        //
        // After reference audio starts:
        // Back is blocked until final result.
        //
        // _allowProgrammaticPop is enabled only when we deliberately
        // return the completed result to the previous page.
        // ---------------------------------------------------------------

        canPop: !_retryStarted || _allowProgrammaticPop,

        onPopInvokedWithResult: (didPop, result) {
          if (!didPop &&
              _retryStarted &&
              !_allowProgrammaticPop) {
            _showAppSnackBar(
              'أكمل محاولتك الأخيرة أولًا',
              isError: false,
            );
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
                      child: IgnorePointer(
                        child: _RetryBackground(),
                      ),
                    ),

                    SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        18,
                        16,
                        40,
                      ),

                      child: Column(
                        children: [
                          _buildInfoCard(),

                          const SizedBox(height: 16),

                          _buildWordCard(),

                          const SizedBox(height: 16),

                          _buildActionCard(),
                        ],
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

  // -------------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return FaseehStyle.buildLargeHeader(
      context: context,

      title: 'إعادة المحاولة',

      subtitle: 'استمع جيدًا ثم انطق الكلمة مرة أخرى',

      leading: SizedBox(
        width: 48,
        height: 48,

        child: IconButton(
          onPressed: _handleHeaderBack,

          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Info
  // -------------------------------------------------------------------------

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),

      decoration: BoxDecoration(
        color: const Color(0xFFF3EBFA),

        borderRadius: BorderRadius.circular(20),
      ),

      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: _deepPurple,
            size: 21,
          ),

          SizedBox(width: 9),

          Expanded(
            child: Text(
              'هذه محاولتك الأخيرة لهذه الكلمة',

              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Word card
  // -------------------------------------------------------------------------

  Widget _buildWordCard() {
    final bool disableAudioButton =
        _audioPlayed ||
        _retryStarted ||
        _state == RetryRecordingState.recording ||
        _state == RetryRecordingState.analyzing ||
        _state == RetryRecordingState.technicalError ||
        _state == RetryRecordingState.finished;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        vertical: 22,
        horizontal: 16,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(26),

        border: Border.all(
          color: _deepPurple.withOpacity(0.08),
        ),

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
          Image.asset(
            widget.imagePath,

            width: 145,
            height: 145,

            fit: BoxFit.contain,

            errorBuilder: (
              context,
              error,
              stackTrace,
            ) {
              return Container(
                width: 145,
                height: 145,

                alignment: Alignment.center,

                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: Color(0xFFB5A7BB),
                  size: 42,
                ),
              );
            },
          ),

          const SizedBox(height: 14),

          Text(
            widget.questionText,

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 42,
              fontWeight: FontWeight.w600,
              color: _deepPurple,
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: disableAudioButton
                ? null
                : _playReferenceAudio,

            icon: const Icon(
              Icons.volume_up_rounded,
              size: 18,
            ),

            label: Text(
              _audioPlayed
                  ? 'تم الاستماع'
                  : 'استمع إلى الكلمة',

              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w600,
              ),
            ),

            style: OutlinedButton.styleFrom(
              foregroundColor: _red,

              side: BorderSide(
                color: _audioPlayed
                    ? const Color(0xFFD6D0D8)
                    : _red.withOpacity(0.45),
              ),

              shape: const StadiumBorder(),

              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
            ),
          ),

          if (!_audioPlayed)
            const Padding(
              padding: EdgeInsets.only(top: 7),

              child: Text(
                'استمع إلى الكلمة أولًا',

                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 10,
                  color: Color(0xFF999999),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Action card
  // -------------------------------------------------------------------------

  Widget _buildActionCard() {
    switch (_state) {
      case RetryRecordingState.waitingForAudio:
        return _buildWaitingState();

      case RetryRecordingState.readyToRecord:
        return _buildReadyState();

      case RetryRecordingState.recording:
        return _buildRecordingState();

      case RetryRecordingState.analyzing:
        return _buildAnalyzingState();

      case RetryRecordingState.technicalError:
        return _buildTechnicalErrorState();

      case RetryRecordingState.finished:
        return _buildFinishedState();
    }
  }

  // -------------------------------------------------------------------------
  // Shared action container
  // -------------------------------------------------------------------------

  Widget _actionContainer({
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      constraints: const BoxConstraints(
        minHeight: 190,
      ),

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFB),

        borderRadius: BorderRadius.circular(24),

        border: Border.all(
          color: _red.withOpacity(0.10),
        ),
      ),

      child: child,
    );
  }

  // -------------------------------------------------------------------------
  // Waiting for audio
  // -------------------------------------------------------------------------

  Widget _buildWaitingState() {
    return _actionContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          const Icon(
            Icons.hearing_rounded,
            color: _deepPurple,
            size: 43,
          ),

          const SizedBox(height: 10),

          Text(
            _audioPlayed
                ? 'استمع جيدًا إلى الكلمة...'
                : 'استمع إلى الكلمة أولًا',

            textAlign: TextAlign.center,

            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _deepPurple,
            ),
          ),

          if (_audioPlayed) ...[
            const SizedBox(height: 5),

            const Text(
              'سيظهر التسجيل بعد انتهاء الصوت',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 10.5,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Ready to record
  // -------------------------------------------------------------------------

  Widget _buildReadyState() {
    return _actionContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          GestureDetector(
            onTap: _startRecording,

            child: Container(
              width: 88,
              height: 88,

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
                size: 41,
              ),
            ),
          ),

          const SizedBox(height: 11),

          const Text(
            'اضغط وسجّل نطقك',

            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _deepPurple,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'لديك محاولة تسجيل واحدة',

            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10.5,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Recording
  // -------------------------------------------------------------------------

  Widget _buildRecordingState() {
    return _actionContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          GestureDetector(
            onTap: _stopRecording,

            child: Container(
              width: 88,
              height: 88,

              decoration: const BoxDecoration(
                color: _red,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.stop_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'جاري تسجيل صوتك...',

            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _deepPurple,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${_recordingTime}ث',

            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _red,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'اضغط زر الإيقاف عند الانتهاء',

            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Analyzing
  // -------------------------------------------------------------------------

  Widget _buildAnalyzingState() {
    return _actionContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          AnimatedBuilder(
            animation: _spinController,

            builder: (_, __) {
              return Transform.rotate(
                angle:
                    _spinController.value *
                    2 *
                    pi,

                child: const Icon(
                  Icons.sync_rounded,
                  size: 58,
                  color: _red,
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
              fontWeight: FontWeight.w600,
              color: _deepPurple,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'لحظات قليلة',

            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 10.5,
              color: Color(0xFF999999),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Technical error
  // -------------------------------------------------------------------------

  Widget _buildTechnicalErrorState() {
    final bool hasSavedRecording =
        _recordedFilePath != null;

    return _actionContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Container(
            width: 68,
            height: 68,

            decoration: const BoxDecoration(
              color: Color(0xFFFFF0F2),
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.wifi_off_rounded,
              color: _red,
              size: 34,
            ),
          ),

          const SizedBox(height: 11),

          const Text(
            'حدثت مشكلة تقنية',

            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _deepPurple,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            _technicalErrorMessage ??
                'تعذر إكمال العملية، حاول مرة أخرى.',

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
                hasSavedRecording
                    ? 'إعادة الإرسال'
                    : 'تسجيل مرة أخرى',

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

                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
              ),
            ),
          ),

          if (hasSavedRecording) ...[
            const SizedBox(height: 7),

            const Text(
              'لن تحتاج إلى تسجيل الكلمة مرة أخرى',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 9.5,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Finished
  // -------------------------------------------------------------------------

  Widget _buildFinishedState() {
    // Keep the same threshold currently used in the result screen.
    final bool correct =
    !_finalIsInvalid &&
    _finalScore >= 80;

    final bool validButIncorrect =
        !_finalIsInvalid &&
        !correct;

    return _actionContainer(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color: correct
                  ? const Color(0xFFEAF7EF)
                  : const Color(0xFFFFECEF),

              shape: BoxShape.circle,
            ),

            child: Icon(
              correct
                  ? Icons.check_rounded
                  : Icons.close_rounded,

              color: correct
                  ? const Color(0xFF67AF82)
                  : _red,

              size: 37,
            ),
          ),

          const SizedBox(height: 10),

          if (_finalIsInvalid)
            const Text(
              'لم نتمكن من تقييم المحاولة',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _red,
              ),
            )
          else ...[
            Text(
              '$_finalScore%',

              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _deepPurple,
              ),
            ),

            const SizedBox(height: 3),

            Text(
              correct
                  ? 'أحسنت! نطق جميل'
                  : 'استمر في التدريب',

              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: correct
                    ? const Color(0xFF67AF82)
                    : _red,
              ),
            ),
          ],

          if (validButIncorrect) ...[
            const SizedBox(height: 4),

            const Text(
              'هذه محاولتك الأخيرة لهذه الكلمة',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 9.5,
                color: Color(0xFF999999),
              ),
            ),
          ],

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: _returnToResults,

              style: ElevatedButton.styleFrom(
                backgroundColor: _red,

                foregroundColor: Colors.white,

                elevation: 0,

                shape: const StadiumBorder(),

                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
              ),

              child: const Text(
                'العودة للنتائج',

                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
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
          top: 60,
          right: -55,

          child: _circle(
            145,
            const Color(0xFFDCC9F5).withOpacity(0.18),
          ),
        ),

        Positioned(
          top: 350,
          left: -55,

          child: _circle(
            145,
            const Color(0xFFDDF2E3).withOpacity(0.25),
          ),
        ),

        Positioned(
          top: 650,
          right: -45,

          child: _circle(
            115,
            const Color(0xFFFFDCE3).withOpacity(0.23),
          ),
        ),
      ],
    );
  }

  Widget _circle(
    double size,
    Color color,
  ) {
    return Container(
      width: size,
      height: size,

      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}