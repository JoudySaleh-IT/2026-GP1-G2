import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
class CertificateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isJourneyCompleted(String childId) async {
    final doc = await _firestore
        .collection('children')
        .doc(childId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return false;
    }

    final data = doc.data()!;

    final Map<String, dynamic> letterScores =
        Map<String, dynamic>.from(data['letterScores'] ?? {});

    final Map<String, dynamic> exerciseProgress =
        Map<String, dynamic>.from(data['exerciseProgress'] ?? {});

    // الحروف التي احتاج الطفل التدريب عليها من الـAssessment
    final List<String> requiredLetters = letterScores.entries
        .where((entry) => (entry.value as num) < 80)
        .map((entry) => entry.key)
        .toList();

    // لا توجد رحلة تمارين أصلًا
    if (requiredLetters.isEmpty) {
      return false;
    }

    // كل حرف مطلوب يجب أن يكون قد أنهى Advanced Listening + Speaking
    for (final letter in requiredLetters) {
      final dynamic rawLetterProgress = exerciseProgress[letter];

      if (rawLetterProgress is! Map) {
        return false;
      }

      final letterProgress =
          Map<String, dynamic>.from(rawLetterProgress);

      final dynamic rawAdvanced = letterProgress['advanced'];

      if (rawAdvanced is! Map) {
        return false;
      }

      final advanced =
          Map<String, dynamic>.from(rawAdvanced);

      final bool listeningPassed =
          advanced['listeningPassed'] == true;

      final bool pronunciationPassed =
          advanced['pronunciationPassed'] == true;

      if (!listeningPassed || !pronunciationPassed) {
        return false;
      }
    }

    return true;
  }
Future<bool> issueCertificate(String childId) async {
  // 1. نتأكد أولًا أن رحلة الطفل انتهت فعلًا
  final bool completed = await isJourneyCompleted(childId);

  if (!completed) {
    throw Exception('رحلة الطفل لم تكتمل بعد');
  }

  // 2. نقرأ بيانات الطفل
  final childRef = _firestore.collection('children').doc(childId);
  final childDoc = await childRef.get();

  if (!childDoc.exists || childDoc.data() == null) {
    throw Exception('لم يتم العثور على بيانات الطفل');
  }

  final data = childDoc.data()!;

  // 3. الاسم بالشكل المطلوب: First Name + Last Name
  final String firstName = data['firstName']?.toString().trim() ?? '';
  final String lastName = data['lastName']?.toString().trim() ?? '';

  final String fullName = '$firstName $lastName'.trim();

  // 4. الحروف التي كانت مطلوبة للتدريب
  final Map<String, dynamic> letterScores =
      Map<String, dynamic>.from(data['letterScores'] ?? {});

  final List<String> completedLetters = letterScores.entries
      .where((entry) => (entry.value as num) < 80)
      .map((entry) => entry.key)
      .toList();

  // 5. نحسب العمر من تاريخ الميلاد
  final Timestamp? dobTimestamp = data['dob'] as Timestamp?;

  if (dobTimestamp == null) {
    throw Exception('تاريخ ميلاد الطفل غير موجود');
  }

  final DateTime dob = dobTimestamp.toDate();
  final DateTime now = DateTime.now();

  int age = now.year - dob.year;

  if (now.month < dob.month ||
      (now.month == dob.month && now.day < dob.day)) {
    age--;
  }

  // 6. نحدد تصميم الشهادة
  final String templateType = age <= 8 ? 'young' : 'older';

  // 7. مكان تخزين الشهادة
  final certificateRef = childRef
      .collection('certificates')
      .doc('completion');

  // 8. ما نصدرها مرتين
  final existingCertificate = await certificateRef.get();

if (existingCertificate.exists) {
  debugPrint('Certificate already exists for child: $childId');
  return false;
}

  // 9. إنشاء سجل الشهادة
  await certificateRef.set({
    'fullNameAtIssue': fullName,
    'completedLetters': completedLetters,
    'ageAtIssue': age,
    'templateType': templateType,
    'completionDate': FieldValue.serverTimestamp(),
    'issuedAt': FieldValue.serverTimestamp(),
  });

  debugPrint('✅ Certificate issued for $fullName');
  return true;
}
}