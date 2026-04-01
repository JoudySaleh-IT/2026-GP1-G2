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
  bool _isLoading = false;

  // ─── Function to Verify the Code ────────────────
  Future<void> _verifyCode(String enteredCode) async {
    setState(() => _isLoading = true);

    try {
      // 1. Sign in anonymously if needed
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        print('Anonymous sign-in successful');
      }

      // 2. Query Firestore (requires index on (code, expiresAt))
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

      // Save session data
      ChildSession.currentChildId = childId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_childId', childId);
      await prefs.setString('saved_parentId', parentId);
      await prefs.setBool('isChildLoggedIn', true);

      // Delete used code
      await doc.reference.delete();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('مرحباً بك يا $childName!')));

      // ✅ Pass childId as argument to avoid relying on static variable
      Navigator.pushReplacementNamed(
        context,
        '/child/home',
        arguments: childId,
      );
    } catch (e) {
      print('🔥 Verification error: $e');
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
        // Matching your Splash Screen Background
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
                // Back Button
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

                // Kid-friendly Header
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

                // Large PIN Entry
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 15,
                      color: Color(0xFF511281),
                    ),
                    decoration: InputDecoration(
                      counterText: "", // Hide the 0/6 counter
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFFB39DDB),
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFF511281),
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.length == 6) {
                        _verifyCode(
                          value,
                        ); // Auto-verify when 6 digits are typed
                      }
                    },
                  ),
                ),

                const SizedBox(height: 30),

                if (_isLoading)
                  const CircularProgressIndicator(color: Color(0xFF511281))
                else
                  const Text(
                    "بانتظار الأرقام الستة...",
                    style: TextStyle(color: Colors.grey),
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
