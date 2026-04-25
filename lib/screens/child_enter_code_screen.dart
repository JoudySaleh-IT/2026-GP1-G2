import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ChildSession.dart'; // Ensure this matches your project structure
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ChildSession.dart';

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
    // ... your existing logic remains exactly the same ...
    setState(() => _isLoading = true);
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final query = await FirebaseFirestore.instance
          .collection('pairing_codes')
          .where('code', isEqualTo: enteredCode)
          .where('expiresAt', isGreaterThan: Timestamp.now())
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showError("الكود غير صحيح أو انتهت صلاحيته");
        setState(() => _isLoading = false);
        return;
      }
      final doc = query.docs.first;
      final data = doc.data();
      final childId = data['childId'] as String;
      final parentId = data['parentId'] as String;
      final childName = data['childName'] as String? ?? 'بطلنا';
      ChildSession.currentChildId = childId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_childId', childId);
      await prefs.setString('saved_parentId', parentId);
      await prefs.setBool('isChildLoggedIn', true);
      await doc.reference.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('مرحباً بك يا $childName!')));
      Navigator.pushReplacementNamed(
        context,
        '/child/home',
        arguments: childId,
      );
    } catch (e) {
      _showError('حدث خطأ أثناء التحقق من الكود. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

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
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF511281),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                const Text(
                  '🚀 أدخل كود الدخول',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF511281),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'اطلب الكود المكون من ٦ أرقام من ولي أمرك',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // ─── NEW SEPARATE DIGIT BOXES UI ───
                // ─── UPDATED SEPARATE DIGIT BOXES UI ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  // Wrap ONLY the input area with LTR so digits flow left-to-right
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Hidden TextField to handle keyboard input
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
                        // Visual digit boxes
                        GestureDetector(
                          onTap: () => _focusNode.requestFocus(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(6, (index) {
                              String char = "";
                              // Logic stays the same, but the Row now renders LTR
                              if (_codeController.text.length > index) {
                                char = _codeController.text[index];
                              }
                              bool isFocused =
                                  _codeController.text.length == index;

                              return Container(
                                width: 45,
                                height: 55,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isFocused
                                        ? const Color(0xFF511281)
                                        : const Color(0xFFB39DDB),
                                    width: isFocused ? 2.5 : 1.5,
                                  ),
                                  boxShadow: [
                                    if (isFocused)
                                      BoxShadow(
                                        color: const Color(
                                          0xFF511281,
                                        ).withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                  ],
                                ),
                                child: Text(
                                  char,
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

                // ─── END OF NEW UI ───
                const SizedBox(height: 40),
                if (_isLoading)
                  const CircularProgressIndicator(color: Color(0xFF511281))
                else
                  Text(
                    _codeController.text.length == 6
                        ? "جاري التحقق..."
                        : "بانتظار الأرقام الستة...",
                    style: const TextStyle(color: Colors.grey),
                  ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
