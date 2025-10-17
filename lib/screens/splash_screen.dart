import 'package:flutter/material.dart';
import 'dart:async';


import 'app_router.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});


  static const splashDuration = 3;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();


    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Cycle duration
    )..repeat(reverse: true); // Repeat: Fades back and forth

    _animation = Tween(begin: 0.5, end: 1.0).animate(_controller);

    _startNavigationTimer();
  }

  // Function to handle the delay and navigation
  void _startNavigationTimer() {
    // Wait for the total splash duration (3 seconds) before navigating
    Timer(const Duration(seconds: SplashScreen.splashDuration), () {

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AppRouter(), // <--- NEW DESTINATION
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            _AnimatedLogo(),
            SizedBox(height: 20),
            Text(
              'CABANK Mobile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004D40), // Branded color
              ),
            ),
            SizedBox(height: 50),

            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF004D40)),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}


class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo();

  @override
  Widget build(BuildContext context) {
    final _SplashScreenState? state = context.findAncestorStateOfType<_SplashScreenState>();
    if (state == null) return const SizedBox.shrink();

    return FadeTransition(
      opacity: state._animation,
      child: const Icon(
        Icons.account_balance,
        size: 100,
        color: Color(0xFF004D40),
      ),
    );
  }
}