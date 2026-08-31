import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ChildSession.dart'; // Ensure this matches your project structure
import 'package:firebase_auth/firebase_auth.dart';
import '../services/notification_service.dart';
import '../utils/arabic_numbers.dart';

class ChildEnterCodeScreen extends StatefulWidget {
  const ChildEnterCodeScreen({super.key});

  @override
  State<ChildEnterCodeScreen> createState() => _ChildEnterCodeScreenState();
}

class _ChildEnterCodeScreenState extends State<ChildEnterCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _focusNode = FocusNode(); // Added to keep focus
  bool _isLoading = false;

  // ─── No changes to _verifyCode or _showError functions ───
  Future<void> _verifyCode(String enteredCode) async {
  setState(() => _isLoading = true);

  try {
    // ─── 1. Make sure this is an anonymous child account ───
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      final credential =
          await FirebaseAuth.instance.signInAnonymously();

      user = credential.user;
    }

    if (user == null || !user.isAnonymous) {
      _showError('تعذر تسجيل دخول جهاز الطفل.');
      return;
    }

    final FirebaseFirestore db =
        FirebaseFirestore.instance;

    final codeRef =
        db.collection('pairing_codes').doc(enteredCode);

    final deviceLinkRef =
        db.collection('child_device_links').doc(user.uid);

    // ─── 2. Validate code + securely bind device to child ───
    final result =
        await db.runTransaction<Map<String, String>>(
      (transaction) async {
        // ALL READS FIRST
        final codeSnapshot =
            await transaction.get(codeRef);

        final deviceLinkSnapshot =
            await transaction.get(deviceLinkRef);

        if (!codeSnapshot.exists) {
          throw Exception('INVALID_PAIRING_CODE');
        }

        final data = codeSnapshot.data()!;

        final Timestamp? expiresAt =
            data['expiresAt'] as Timestamp?;

        if (expiresAt == null ||
            expiresAt.toDate().isBefore(DateTime.now())) {
          throw Exception('INVALID_PAIRING_CODE');
        }

        if (deviceLinkSnapshot.exists) {
          throw Exception('DEVICE_ALREADY_LINKED');
        }

        final String childId =
            data['childId'] as String;

        final String parentId =
            data['parentId'] as String;

        final String childName =
            data['childName'] as String? ?? 'بطلنا';

        // ALL WRITES AFTER READS

        // Securely link this anonymous Firebase account
        // to the child selected by the parent.
        transaction.set(deviceLinkRef, {
          'childId': childId,
          'parentId': parentId,
          'pairingCode': enteredCode,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Pairing code is one-time use.
        transaction.delete(codeRef);

        return {
          'childId': childId,
          'parentId': parentId,
          'childName': childName,
        };
      },
    );

    final String childId = result['childId']!;
    final String parentId = result['parentId']!;
    final String childName = result['childName']!;
  

    // ─── 3. Save local child session ───
    ChildSession.currentChildId = childId;
    ChildSession.currentParentId = parentId;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'saved_childId',
      childId,
    );

    await prefs.setString(
      'saved_parentId',
      parentId,
    );

    await prefs.setBool(
      'isChildLoggedIn',
      true,
    );

    if (!mounted) return;

    NotificationService.showSuccessSnackBar(
      'اهلًا $childName! جاهز تكون فصيح؟',
    );

    Navigator.pushReplacementNamed(
      context,
      '/child/home',
      arguments: childId,
    );
  } catch (e) {
    print('Pairing error: $e');

    if (!mounted) return;

    if (e.toString().contains('INVALID_PAIRING_CODE')) {
      _showError(
        'الكود غير صحيح أو انتهت صلاحيته',
      );
    } else if (e.toString().contains('DEVICE_ALREADY_LINKED')) {
      _showError(
        'هذا الجهاز مرتبط بطفل بالفعل',
      );
    } else {
      _showError(
        'حدث خطأ أثناء التحقق من الكود. حاول مرة أخرى.',
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.7, -0.7),
              end: Alignment(0.7, 0.7),
              colors: [Color(0xFFFFFDF5), Color(0xFFFCF9EA), Color(0xFFF6F0D5)],
            ),
          ),
          child: Stack(
            children: [
              // ─────────────────────────────────────────────
              // BACKGROUND DECORATIONS
              // ─────────────────────────────────────────────
              Positioned(
                top: -45,
                left: -35,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB39DDB).withOpacity(0.14),
                  ),
                ),
              ),

              Positioned(
                top: 110,
                left: 30,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    Icons.pets_rounded,
                    size: 34,
                    color: const Color(0xFF511281).withOpacity(0.09),
                  ),
                ),
              ),

              Positioned(
                top: 145,
                right: 28,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 30,
                  color: const Color(0xFF511281).withOpacity(0.10),
                ),
              ),

              Positioned(
                top: 215,
                right: 55,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFB39DDB).withOpacity(0.22),
                  ),
                ),
              ),

              Positioned(
                top: 250,
                left: 22,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF511281).withOpacity(0.06),
                  ),
                ),
              ),

              Positioned(
                bottom: 160,
                left: 28,
                child: Transform.rotate(
                  angle: 0.25,
                  child: Icon(
                    Icons.star_rounded,
                    size: 34,
                    color: const Color(0xFF511281).withOpacity(0.08),
                  ),
                ),
              ),

              Positioned(
                bottom: 120,
                right: 40,
                child: Transform.rotate(
                  angle: -0.25,
                  child: Icon(
                    Icons.pets_rounded,
                    size: 40,
                    color: const Color(0xFF511281).withOpacity(0.08),
                  ),
                ),
              ),

              Positioned(
                bottom: 55,
                left: 55,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 24,
                  color: const Color(0xFFB39DDB).withOpacity(0.28),
                ),
              ),

              Positioned(
                bottom: -70,
                right: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF511281).withOpacity(0.06),
                  ),
                ),
              ),

              // ─────────────────────────────────────────────
              // MAIN CONTENT
              // ─────────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.75),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF511281),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Top decorative bubble instead of mascot
                    const SizedBox(height: 15),

                    const Text(
                      '🚀 أدخل رمز الدخول',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF511281),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 35),
                      child: Text(
                        'اطلب من ولي أمرك رمز الدخول المكوّن من ٦ أرقام',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Code Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 22, 14, 24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.93),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFB39DDB).withOpacity(0.30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF511281).withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Small decorative chips
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF511281),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 34,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFB39DDB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF511281),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 22),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Opacity(
                                      opacity: 0,
                                      child: TextField(
                                        controller: _codeController,
                                        focusNode: _focusNode,
                                        keyboardType: TextInputType.number,
                                        maxLength: 6,
                                        onChanged: (value) {
                                          setState(() {});
                                          if (value.length == 6) {
                                            _verifyCode(value);
                                          }
                                        },
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => _focusNode.requestFocus(),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(6, (index) {
                                          String char = "";
                                          if (_codeController.text.length >
                                              index) {
                                            char = _codeController.text[index];
                                          }

                                          bool isFocused =
                                              _codeController.text.length ==
                                              index;
                                          bool hasValue =
                                              _codeController.text.length >
                                              index;

                                          return AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            width: 45,
                                            height: 58,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: hasValue
                                                  ? const Color(0xFFF8F4FC)
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isFocused
                                                    ? const Color(0xFF511281)
                                                    : hasValue
                                                    ? const Color(0xFFB39DDB)
                                                    : const Color(0xFFE3DDEC),
                                                width: isFocused ? 2.5 : 1.5,
                                              ),
                                              boxShadow: [
                                                if (isFocused)
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF511281,
                                                    ).withOpacity(0.16),
                                                    blurRadius: 10,
                                                    spreadRadius: 1,
                                                  ),
                                              ],
                                            ),
                                            child: Text(
                                              toArabicDigits(char),
                                              style: const TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF511281),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            if (_isLoading)
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Color(0xFF511281),
                                ),
                              )
                            else
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.pets_rounded,
                                    size: 18,
                                    color: const Color(
                                      0xFF511281,
                                    ).withOpacity(0.55),
                                  ),
                                  const SizedBox(width: 7),
                                  Text(
                                    _codeController.text.length == 6
                                        ? "جاري التحقق..."
                                        : "أدخل رمزك المكوّن من ٦ أرقام",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
