import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// الحزم الجديدة المطلوبة للاتصال بالسيرفر
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  // التحقق من الإذن
  Future<bool> checkPermission() async {
    return await _audioRecorder.hasPermission();
  }

  // بدء التسجيل
  Future<void> start(String fileName) async {
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/$fileName.wav'; // نستخدم wav لأنه الأفضل لتحليل الصوت

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

  // --------------------------------------------------------
  // الوظيفة الجديدة: إرسال الصوت للسيرفر واستقبال النتيجة
  // --------------------------------------------------------
  Future<Map<String, dynamic>?> sendAudioToServer(
    String audioFilePath,
    String targetWord,
  ) async {
    // ⚠️ استبدلي 192.168.X.X برقم الـ IP الخاص بالماك ⚠️
    var apiUrl = Uri.parse('http://192.168.1.91:8000/process-audio/');

    try {
      var request = http.MultipartRequest('POST', apiUrl);

      // 1. إرفاق ملف الصوت
      request.files.add(
        await http.MultipartFile.fromPath('file', audioFilePath),
      );

      // 2. إرفاق الكلمة المستهدفة لتقييم الذكاء الاصطناعي
      request.fields['target_word'] = targetWord;

      print('جاري إرسال الصوت للسيرفر...');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // إذا نجح الاتصال بالسيرفر
      if (response.statusCode == 200) {
        // تحويل النتيجة من صيغة النص إلى قاموس (Map)
        var responseData = json.decode(response.body);

        // إرجاع البيانات لواجهة المستخدم (النسبة، الرابط، الكلمة المسموعة)
        return responseData;
      } else {
        print('فشل الاتصال بالسيرفر. رمز الخطأ: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('حدث خطأ أثناء الإرسال: $e');
      return null;
    }
  }
}
