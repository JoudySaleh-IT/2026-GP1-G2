import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1), // slight upward slide (translate-y-10 ≈ 10%)
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Trigger animation on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // RTL for Arabic
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          // Main beige gradient background
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.7, -0.7), // 145deg approximation
              end: Alignment(0.7, 0.7),
              colors: [
                Color(0xFFFFFDF5),
                Color(0xFFFCF9EA),
                Color(0xFFF6F0D5),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Radial gradient overlay (soft white center glow)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.85,
                      colors: [
                        Colors.white.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo + tagline section
                          Column(
                            children: [
                              // Logo image
                              Image.network(
                                'https://i.ibb.co/LX3NsCkz/3-removebg-preview.png',
                                width: 288,
                                height: 288,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                    width: 288,
                                    height: 288,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF511281),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              // Arabic tagline
                              const Text(
                                'فَـصِـيـح لنطق صحيح',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF511281),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 48),

                          // Buttons section
                          Column(
                            children: [
                              // Filled purple button — Register as Parent
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, '/parent/register');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF511281),
                                    foregroundColor: Colors.white,
                                    elevation: 4,
                                    shadowColor:
                                    const Color(0xFF511281).withOpacity(0.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'ابدأ كـ ولي أمر',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Outlined purple button — Login as Parent
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                        context, '/parent/login');
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF511281),
                                    side: const BorderSide(
                                      color: Color(0xFF511281),
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'تسجيل الدخول كـ ولي أمر',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
