import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class RecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  // التحقق من الإذن
  Future<bool> checkPermission() async {
    return await _audioRecorder.hasPermission();
  }

  // بدء التسجيل
  Future<void> start(String fileName) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$fileName.wav'; // نستخدم wav لأنه الأفضل لتحليل الصوت

    // احذفي كلمة const من هنا
final config = RecordConfig( 
  encoder: AudioEncoder.wav, 
  sampleRate: 16000,
  bitRate: 128000,
);
    await _audioRecorder.start(config, path: path);
  }

  // إيقاف التسجيل وإرجاع المسار
  Future<String?> stop() async {
    return await _audioRecorder.stop();
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}