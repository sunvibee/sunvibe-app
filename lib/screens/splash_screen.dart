import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Timer(const Duration(seconds: 3), () async {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (await auth.checkSession()) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          /// Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/splash_bg.png",
              fit: BoxFit.cover,
            ),
          ),

          /// Top white overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(.78),
                    Colors.white.withOpacity(.45),
                    Colors.transparent,
                    Colors.black.withOpacity(.85),
                  ],
                  stops: const [0, .35, .60, 1],
                ),
              ),
            ),
          ),

          /// Sunrise Glow
          Positioned(
            top: h * .18,
            right: -40,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xffffb300),
                    blurRadius: 120,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Stack(
                children: [
                  /// Logo
                  Positioned(
                    top: h * .05,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Image.asset("assets/images/logo.png", height: 140),

                        const SizedBox(height: 18),

                        const Text(
                          "SUNVIBEE",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Color(0xff1C1C1C),
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 12),

                        RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.black54,
                            ),
                            children: [
                              TextSpan(text: "Clean Panels. "),

                              TextSpan(
                                text: "More Energy.",
                                style: TextStyle(
                                  color: Color(0xffff8c00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Bottom Loading Section
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        const Text(
                          "CONNECTING TO ROBOT...",
                          style: TextStyle(
                            color: Colors.white,
                            letterSpacing: 3,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 25),

                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation(
                              Color(0xffff8c00),
                            ),
                            backgroundColor: Colors.white24,
                          ),
                        ),

                        const SizedBox(height: 35),

                        Container(
                          width: w * .65,
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xffff8c00),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
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
