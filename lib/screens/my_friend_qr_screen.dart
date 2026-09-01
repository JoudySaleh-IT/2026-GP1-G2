import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class MyFriendQrScreen extends StatelessWidget {
  final String childId;

  const MyFriendQrScreen({
    super.key,
    required this.childId,
  });

  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,

        appBar: AppBar(
          backgroundColor: _purple,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'رمزي الخاص',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
            ),
          ),
        ),

        body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('child_public_profiles')
              .doc(childId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _purple,
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'تعذّر تحميل رمزك. حاول مرة أخرى.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            final data = snapshot.data!.data();

            final String fasehId =
                data?['fasehId']?.toString() ?? '';

            final String name =
                data?['name']?.toString() ?? 'بطل فصيح';

            final String avatar =
                data?['avatar']?.toString() ?? '🌟';

            if (fasehId.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'لم يتم العثور على معرّفك في فصيح.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                ),
              );
            }

            final String qrPayload =
                'faseh://friend/$fasehId';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  Text(
                    avatar,
                    style: const TextStyle(
                      fontSize: 55,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: _purple,
                      fontFamily: 'Tajawal',
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'اطلب من صديقك مسح الرمز لإرسال طلب صداقة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'Tajawal',
                    ),
                  ),

                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: _purple.withOpacity(0.10),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12000000),
                          blurRadius: 14,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 230,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: _purple,
                      ),
                      dataModuleStyle:
                          const QrDataModuleStyle(
                        dataModuleShape:
                            QrDataModuleShape.square,
                        color: _purple,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: _coral.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'معرّفك في فصيح',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontFamily: 'Tajawal',
                          ),
                        ),

                        const SizedBox(height: 5),

                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            fasehId,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: _purple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'شارك رمزك مع أصدقائك فقط',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}