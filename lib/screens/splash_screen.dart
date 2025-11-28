import 'package:flutter/material.dart';
import 'dart:async';

import 'app_router.dart';
import '../theme/app_dimensions.dart'; // Import dimensions

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

      // Using pushReplacement to prevent navigating back to the splash screen
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // Use colorScheme.background for the main screen color
      backgroundColor: colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The animated logo relies on the state for its animation
            _AnimatedLogo(
              animation: _animation,
            ),
            // Use dimension constants for spacing
            const SizedBox(height: kPaddingMedium),
            Text(
              'CABANK Mobile',
              // Use theme text style (e.g., headlineMedium or large title)
              // and colorScheme.primary for the branded color
              style: textTheme.headlineMedium?.copyWith(
                // The original design used a large bold font. headlineMedium is appropriate.
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            // Use dimension constants for spacing
            const SizedBox(height: kPaddingXXL),

            // Progress indicator uses colorScheme.primary
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              strokeWidth: 3, // Maintain original stroke width
            ),
          ],
        ),
      ),
    );
  }
}


class _AnimatedLogo extends StatelessWidget {
  // Accept the animation as a parameter instead of relying on findAncestorStateOfType
  // which is generally discouraged in production code.
  final Animation<double> animation;

  const _AnimatedLogo({required this.animation});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: animation,
      child: Icon(
        Icons.account_balance,
        // Use dimension constant for size
        size: kIconSizeXXL, // Reusing XXL size for prominent icon
        // Use colorScheme.primary for the branded color
        color: colorScheme.primary,
      ),
    );
  }
}