import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_dimensions.dart';
import 'app_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const splashDuration = 3;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Scaling effect for the logo
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    // Fade effect for text
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeIn)),
    );

    _controller.forward();
    _startNavigationTimer();
  }

  void _startNavigationTimer() {
    Timer(const Duration(seconds: SplashScreen.splashDuration), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AppRouter()),
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // Gradient inspired by the logo's background
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF006400), // Deep Green from logo border
              const Color(0xFF003366), // Deep Blue from logo center
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- ANIMATED LOGO ---
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFD700), width: 4), // Gold/Yellow border
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/imagelogo.jpg', // FIXED EXTENSION
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.account_balance,
                      size: 100,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // --- TITLE SECTION ---
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Text(
                      'ನೆರಳಕಟ್ಟೆ ಪ್ರಾಥಮಿಕ ಕೃಷಿ ಪತ್ತಿನ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      'ಸಹಕಾರ ಸಂಘ (ನಿ.) ಸಂ.೨೬೯೪',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFFFD700), // Yellow text for registration number
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),

            // --- LOADING INDICATOR ---
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
          ],
        ),
      ),
    );
  }
}