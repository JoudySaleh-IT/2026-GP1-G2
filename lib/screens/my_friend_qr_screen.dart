import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'style_constants.dart';

class MyFriendQrScreen extends StatelessWidget {
  final String childId;

  const MyFriendQrScreen({super.key, required this.childId});

  static const Color _purple = Color(0xFF511281);
  static const Color _coral = Color(0xFFFF6969);
  static const Color _background = Color(0xFFFCF9EA);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _background,
        body: Column(
          children: [
            // ─────────────────────────────────────
            // Unified Header
            // بدون تغيير
            // ─────────────────────────────────────
            FaseehStyle.buildLargeHeader(
              context: context,
              title: 'رمزي الخاص',
              subtitle: 'شارك رمزك مع صديقك ليضيفك',
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─────────────────────────────────────
            // Page Content
            // ─────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: IgnorePointer(child: _MyQrBackground()),
                  ),
                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    future: FirebaseFirestore.instance
                        .collection('child_public_profiles')
                        .doc(childId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: _purple),
                        );
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          !snapshot.data!.exists) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: _QrStateMessageCard(
                              title: 'تعذّر تحميل رمزك',
                              subtitle: 'حاول مرة أخرى بعد قليل',
                              icon: Icons.error_outline_rounded,
                              isError: true,
                            ),
                          ),
                        );
                      }

                      final data = snapshot.data!.data();

                      final String fasehId = data?['fasehId']?.toString() ?? '';

                      final String name =
                          data?['name']?.toString() ?? 'بطل فصيح';

                      final String avatar = data?['avatar']?.toString() ?? '🌟';

                      if (fasehId.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: _QrStateMessageCard(
                              title: 'لم يتم العثور على معرّفك',
                              subtitle: 'تأكد من بياناتك ثم حاول مرة أخرى',
                              icon: Icons.info_outline_rounded,
                            ),
                          ),
                        );
                      }

                      final String qrPayload = 'faseh://friend/$fasehId';

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                        child: Column(
                          children: [
                            const _MyQrHeroCard(),

                            const SizedBox(height: 14),

                            // =================================================
                            // Main merged QR card
                            // =================================================
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                18,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.96),
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: _purple.withOpacity(0.09),
                                  width: 1.4,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x12000000),
                                    blurRadius: 14,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // -----------------------------------------
                                  // child info + text
                                  // -----------------------------------------
                                  Row(
                                    children: [
                                      Container(
                                        width: 58,
                                        height: 58,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF6EFFB),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          avatar,
                                          style: const TextStyle(fontSize: 30),
                                        ),
                                      ),
                                      const SizedBox(width: 11),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: _purple,
                                                fontFamily: 'Tajawal',
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'هذا هو رمزك في فصيح، اعرضه لصديقك ليقوم بمسحه',
                                              style: TextStyle(
                                                fontSize: 11.5,
                                                height: 1.45,
                                                color: Color(0xFF7A7A7A),
                                                fontFamily: 'Tajawal',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // -----------------------------------------
                                  // small label
                                  // -----------------------------------------
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4EEFA),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.qr_code_scanner_rounded,
                                          color: Color(0xFF7B4AAD),
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'دع صديقك يمسح الرمز',
                                          style: TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF7B4AAD),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // -----------------------------------------
                                  // QR box
                                  // -----------------------------------------
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: const Color(0xFFE7DCEF),
                                      ),
                                    ),
                                    child: QrImageView(
                                      data: qrPayload,
                                      version: QrVersions.auto,
                                      size: 225,
                                      backgroundColor: Colors.white,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.square,
                                        color: _purple,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape:
                                            QrDataModuleShape.square,
                                        color: _purple,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // -----------------------------------------
                                  // faseh id
                                  // -----------------------------------------
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
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
                                        const SizedBox(height: 6),
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
                                ],
                              ),
                            ),

                            const SizedBox(height: 6),

                            Transform.translate(
                              offset: const Offset(0, -50),
                              child: const _BunnyFriendsFooter(),
                            ),
                          ],
                        ),
                      );
                    },
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
// HERO CARD
// =============================================================================

class _MyQrHeroCard extends StatelessWidget {
  const _MyQrHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 135),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F0FF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFF511281).withOpacity(0.08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x09000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -45,
              top: -60,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCC9F5).withOpacity(0.30),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 35,
              bottom: -55,
              child: Container(
                width: 135,
                height: 105,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD9E2).withOpacity(0.40),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              child: Row(
                children: [
                  SizedBox(width: 106, height: 110, child: _QrGuideBunny()),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اعرض الرمز لصديقك',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF511281),
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'صديقك يمسح رمزك من صفحة المسح ثم يرسل لك طلب صداقة',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 11.4,
                            height: 1.5,
                            color: Color(0xFF777777),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              size: 15,
                              color: Color(0xFFFF7890),
                            ),
                            SizedBox(width: 5),
                            Text(
                              'شارك رمزك مع أصدقائك',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 9.7,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF8B55B3),
                              ),
                            ),
                          ],
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
// EMPTY / ERROR MESSAGE CARD
// =============================================================================

class _QrStateMessageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isError;

  const _QrStateMessageCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color cardColor = isError
        ? const Color(0xFFFFF4F1)
        : const Color(0xFFF7F0FF);
    final Color mainColor = isError
        ? const Color(0xFFD86F62)
        : const Color(0xFF511281);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: mainColor.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: mainColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: mainColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF838383),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// BACKGROUND
// =============================================================================

class _MyQrBackground extends StatelessWidget {
  const _MyQrBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 40,
          right: -55,
          child: _circle(150, const Color(0xFFDCC9F5).withOpacity(0.18)),
        ),
        Positioned(
          top: 260,
          left: -60,
          child: _circle(150, const Color(0xFFDDF2E3).withOpacity(0.24)),
        ),
        Positioned(
          top: 560,
          right: -45,
          child: _circle(120, const Color(0xFFFFDCE3).withOpacity(0.23)),
        ),
        Positioned(
          top: 745,
          left: 28,
          child: _circle(20, const Color(0xFFD4BDEA).withOpacity(0.34)),
        ),
        Positioned(
          top: 470,
          left: 24,
          child: _circle(14, const Color(0xFFFFC7D3).withOpacity(0.45)),
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
// BUNNY GUIDE
// أرنب + صديق + جهاز سكان
// =============================================================================

class _QrGuideBunny extends StatelessWidget {
  const _QrGuideBunny();

  @override
  Widget build(BuildContext context) {
    const Color faceColor = Color(0xFFFFDCE7);
    const Color bodyColor = Color(0xFF8B55B3);
    const Color innerEarColor = Color(0xFFFFA1B7);
    const Color detailsColor = Color(0xFF4D3855);

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          bottom: 10,
          child: Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: const Color(0xFFDDF2E3),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x0A000000), blurRadius: 4),
              ],
            ),
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 4,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: detailsColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 4,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: detailsColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 11,
                      height: 6,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: detailsColor, width: 1.2),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        Positioned(
          right: 0,
          bottom: 12,
          child: Transform.rotate(
            angle: 0.10,
            child: Container(
              width: 32,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE4D6EE)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 4),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 16,
                    color: Color(0xFF8B55B3),
                  ),
                  SizedBox(height: 2),
                  Icon(
                    Icons.arrow_downward_rounded,
                    size: 12,
                    color: Color(0xFFFF7890),
                  ),
                ],
              ),
            ),
          ),
        ),

        Positioned(
          top: 10,
          left: 6,
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFF7890),
              size: 13,
            ),
          ),
        ),

        Positioned(
          top: 0,
          right: 25,
          child: Container(
            width: 19,
            height: 39,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          top: 0,
          left: 25,
          child: Container(
            width: 19,
            height: 39,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Container(
                width: 7,
                height: 24,
                decoration: BoxDecoration(
                  color: innerEarColor.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),

        Positioned(
          bottom: 2,
          child: Container(
            width: 46,
            height: 29,
            decoration: const BoxDecoration(
              color: bodyColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(11),
                bottomRight: Radius.circular(11),
              ),
            ),
          ),
        ),

        Positioned(
          top: 28,
          child: Container(
            width: 59,
            height: 55,
            decoration: BoxDecoration(
              color: faceColor,
              borderRadius: BorderRadius.circular(28),
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
                Positioned(
                  top: 20,
                  right: 14,
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
                  top: 20,
                  left: 14,
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
                  top: 32,
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
                  top: 32,
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
                Positioned(
                  top: 28,
                  left: 26,
                  child: Container(
                    width: 7,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7890),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  top: 34,
                  left: 22,
                  child: Container(
                    width: 15,
                    height: 7,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: detailsColor, width: 1.4),
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

        Positioned(
          left: 27,
          bottom: 14,
          child: Transform.rotate(
            angle: 0.35,
            child: Container(
              width: 10,
              height: 20,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        Positioned(
          right: 26,
          bottom: 14,
          child: Transform.rotate(
            angle: -0.45,
            child: Container(
              width: 10,
              height: 20,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// BUNNY FOOTER GROUP
// =============================================================================

class _BunnyFriendsFooter extends StatelessWidget {
  const _BunnyFriendsFooter();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 155,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // =========================================================
          // خلفية الحديقة الكبيرة
          // =========================================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 82,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F3E5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(42),
                  topRight: Radius.circular(42),
                  bottomLeft: Radius.circular(26),
                  bottomRight: Radius.circular(26),
                ),
              ),
            ),
          ),

          // =========================================================
          // طبقة العشب الثانية
          // =========================================================
          Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            child: Container(
              height: 57,
              decoration: const BoxDecoration(
                color: Color(0xFFC8E8D1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
            ),
          ),

          // =========================================================
          // العشب
          // =========================================================
          const Positioned(
            bottom: 48,
            left: 18,
            child: _GrassTuft(color: Color(0xFF72B98A), size: 24),
          ),

          const Positioned(
            bottom: 51,
            left: 70,
            child: _GrassTuft(color: Color(0xFF83C699), size: 18),
          ),

          const Positioned(
            bottom: 48,
            right: 20,
            child: _GrassTuft(color: Color(0xFF72B98A), size: 24),
          ),

          const Positioned(
            bottom: 52,
            right: 72,
            child: _GrassTuft(color: Color(0xFF83C699), size: 18),
          ),

          const Positioned(
            bottom: 45,
            left: 150,
            child: _GrassTuft(color: Color(0xFF69AE82), size: 19),
          ),

          // =========================================================
          // الزهور
          // =========================================================
          Positioned(
            bottom: 27,
            left: 38,
            child: _flower(const Color(0xFFFFB5C5), const Color(0xFFFFD96B)),
          ),

          Positioned(
            bottom: 22,
            right: 42,
            child: _flower(const Color(0xFFD8B9ED), const Color(0xFFFFD96B)),
          ),

          Positioned(
            bottom: 23,
            right: 120,
            child: _flower(const Color(0xFFFFC4D1), const Color(0xFFFFE69A)),
          ),

          // =========================================================
          // الأرانب + القلوب بينهم
          // =========================================================
          Positioned(
            left: 0,
            right: 0,
            bottom: 35,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,

              // مهم: بدون const هنا
              children: [
                // الأرنب الأول
                const _SideGardenBunny(
                  size: 0.88,
                  facingRight: true,
                  bodyColor: Color(0xFF74B58A),
                  faceColor: Color(0xFFEAF8EE),
                ),

                // القلب بين الأول والثاني
                Transform.translate(
                  offset: const Offset(0, -37),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFFF8FA6),
                      size: 15,
                    ),
                  ),
                ),

                // الأرنب الأوسط
                const _SideGardenBunny(
                  size: 1.0,
                  facingRight: true,
                  bodyColor: Color(0xFF8B55B3),
                  faceColor: Color(0xFFFFDCE7),
                ),

                // القلب بين الثاني والثالث
                Transform.translate(
                  offset: const Offset(0, -36),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFC59BDB),
                      size: 14,
                    ),
                  ),
                ),

                // الأرنب الثالث
                const _SideGardenBunny(
                  size: 0.84,
                  facingRight: false,
                  bodyColor: Color(0xFFB694CE),
                  faceColor: Color(0xFFFFE3EC),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // Flower
  // ===============================================================
  Widget _flower(Color petalColor, Color centerColor) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: petalColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            bottom: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: petalColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            left: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: petalColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
            right: 1,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: petalColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: centerColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBuddyBunny extends StatelessWidget {
  final Color bodyColor;
  final Color faceColor;
  final double size;

  const _MiniBuddyBunny({
    required this.bodyColor,
    required this.faceColor,
    this.size = 1,
  });

  @override
  Widget build(BuildContext context) {
    const Color detailsColor = Color(0xFF4D3855);
    const Color innerEarColor = Color(0xFFFFA1B7);

    return SizedBox(
      width: 72 * size,
      height: 92 * size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 2 * size,
            right: 18 * size,
            child: Container(
              width: 14 * size,
              height: 28 * size,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Container(
                  width: 5 * size,
                  height: 18 * size,
                  decoration: BoxDecoration(
                    color: innerEarColor.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 2 * size,
            left: 18 * size,
            child: Container(
              width: 14 * size,
              height: 28 * size,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Container(
                  width: 5 * size,
                  height: 18 * size,
                  decoration: BoxDecoration(
                    color: innerEarColor.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: 36 * size,
              height: 24 * size,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            top: 24 * size,
            child: Container(
              width: 46 * size,
              height: 42 * size,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 14 * size,
                    right: 12 * size,
                    child: Container(
                      width: 5 * size,
                      height: 6 * size,
                      decoration: const BoxDecoration(
                        color: detailsColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14 * size,
                    left: 12 * size,
                    child: Container(
                      width: 5 * size,
                      height: 6 * size,
                      decoration: const BoxDecoration(
                        color: detailsColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 23 * size,
                    left: 20 * size,
                    child: Container(
                      width: 6 * size,
                      height: 4 * size,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7890),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 28 * size,
                    left: 16 * size,
                    child: Container(
                      width: 12 * size,
                      height: 5 * size,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: detailsColor, width: 1.2),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideGardenBunny extends StatelessWidget {
  final Color bodyColor;
  final Color faceColor;
  final bool facingRight;
  final double size;

  const _SideGardenBunny({
    required this.bodyColor,
    required this.faceColor,
    required this.facingRight,
    this.size = 1,
  });

  @override
  Widget build(BuildContext context) {
    const Color innerEarColor = Color(0xFFFFA1B7);
    const Color detailColor = Color(0xFF4D3855);
    const Color noseColor = Color(0xFFFF7890);

    Widget bunny = SizedBox(
      width: 82 * size,
      height: 78 * size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // =========================================================
          // الذيل
          // =========================================================
          Positioned(
            left: 3 * size,
            bottom: 25 * size,
            child: Container(
              width: 15 * size,
              height: 15 * size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.025),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // =========================================================
          // الجسم
          // =========================================================
          Positioned(
            left: 15 * size,
            bottom: 18 * size,
            child: Container(
              width: 46 * size,
              height: 31 * size,
              decoration: BoxDecoration(
                color: bodyColor,
                borderRadius: BorderRadius.circular(22 * size),
              ),
            ),
          ),

          // =========================================================
          // الرجل الخلفية
          // =========================================================
          Positioned(
            left: 20 * size,
            bottom: 8 * size,
            child: Container(
              width: 18 * size,
              height: 14 * size,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(12 * size),
              ),
            ),
          ),

          // =========================================================
          // الرجل الأمامية
          // =========================================================
          Positioned(
            right: 13 * size,
            bottom: 8 * size,
            child: Container(
              width: 15 * size,
              height: 14 * size,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(11 * size),
              ),
            ),
          ),

          // =========================================================
          // الأذن الخلفية
          // =========================================================
          Positioned(
            right: 22 * size,
            top: 1 * size,
            child: Transform.rotate(
              angle: -0.12,
              child: Container(
                width: 11 * size,
                height: 31 * size,
                decoration: BoxDecoration(
                  color: faceColor,
                  borderRadius: BorderRadius.circular(12 * size),
                ),
                child: Center(
                  child: Container(
                    width: 4 * size,
                    height: 20 * size,
                    decoration: BoxDecoration(
                      color: innerEarColor.withOpacity(0.52),
                      borderRadius: BorderRadius.circular(8 * size),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // =========================================================
          // الأذن الأمامية
          // =========================================================
          Positioned(
            right: 9 * size,
            top: 0,
            child: Transform.rotate(
              angle: 0.10,
              child: Container(
                width: 11 * size,
                height: 33 * size,
                decoration: BoxDecoration(
                  color: faceColor,
                  borderRadius: BorderRadius.circular(12 * size),
                ),
                child: Center(
                  child: Container(
                    width: 4 * size,
                    height: 21 * size,
                    decoration: BoxDecoration(
                      color: innerEarColor.withOpacity(0.52),
                      borderRadius: BorderRadius.circular(8 * size),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // =========================================================
          // الرأس
          // كل ملامح الوجه أصبحت داخله
          // =========================================================
          Positioned(
            right: 3 * size,
            top: 25 * size,
            child: Container(
              width: 35 * size,
              height: 31 * size,
              decoration: BoxDecoration(
                color: faceColor,
                borderRadius: BorderRadius.circular(18 * size),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.025),
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // العين
                  Positioned(
                    top: 10 * size,
                    right: 12 * size,
                    child: Container(
                      width: 4.5 * size,
                      height: 5 * size,
                      decoration: const BoxDecoration(
                        color: detailColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // لمعة العين
                  Positioned(
                    top: 10.7 * size,
                    right: 12.8 * size,
                    child: Container(
                      width: 1.4 * size,
                      height: 1.4 * size,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // الأنف
                  Positioned(
                    top: 15 * size,
                    right: 2.5 * size,
                    child: Container(
                      width: 5 * size,
                      height: 4 * size,
                      decoration: const BoxDecoration(
                        color: noseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),

                  // الابتسامة - الآن في مكانها الصحيح تحت الأنف
                  Positioned(
                    top: 19 * size,
                    right: 4 * size,
                    child: Container(
                      width: 8 * size,
                      height: 5 * size,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: detailColor, width: 1.1),
                        ),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(7),
                          bottomRight: Radius.circular(7),
                        ),
                      ),
                    ),
                  ),

                  // خد صغير
                  Positioned(
                    top: 18 * size,
                    right: 15 * size,
                    child: Container(
                      width: 6 * size,
                      height: 3 * size,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9BB0).withOpacity(0.45),
                        borderRadius: BorderRadius.circular(8 * size),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // قلب الأرنب كاملًا إذا كان يناظر الجهة الثانية
    if (!facingRight) {
      bunny = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0),
        child: bunny,
      );
    }

    return bunny;
  }
}

class _GrassTuft extends StatelessWidget {
  final Color color;
  final double size;

  const _GrassTuft({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: size * 0.15,
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: size * 0.18,
                height: size * 0.75,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 0.18,
              height: size * 0.88,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: size * 0.15,
            child: Transform.rotate(
              angle: 0.35,
              child: Container(
                width: size * 0.18,
                height: size * 0.75,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
