import 'package:flutter/material.dart';
import 'dart:async';

// Assuming these files exist in your project structure
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
      duration: const Duration(milliseconds: 1000), // Slightly longer cycle for smoothness
    )..repeat(reverse: true); // Repeat: Fades back and forth

    // Animate opacity between 0.6 (slightly transparent) and 1.0 (fully visible)
    _animation = Tween(begin: 0.6, end: 1.0).animate(_controller);

    _startNavigationTimer();
  }

  // Function to handle the delay and navigation
  void _startNavigationTimer() {
    // Wait for the total splash duration (3 seconds) before navigating
    Timer(const Duration(seconds: SplashScreen.splashDuration), () {

      // Using pushReplacement to prevent navigating back to the splash screen
      // ignore: use_build_context_synchronously
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
      // Use the background color from the theme
      backgroundColor: colorScheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The animated custom logo
            _AnimatedLogo(
              animation: _animation,
            ),
            // Use dimension constants for spacing
            const SizedBox(height: kPaddingMedium),

            // Bank Name Text
            Text(
              'Neralakatte CA Bank',
              // Use a large, bold font for prominence
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900, // Extra bold
                letterSpacing: 1.5,
                color: colorScheme.primary, // Brand color
              ),
            ),

            // Use dimension constants for spacing
            const SizedBox(height: kPaddingXXL),

            // Progress indicator uses colorScheme.primary
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              strokeWidth: 4, // Slightly thicker stroke
            ),
          ],
        ),
      ),
    );
  }
}


class _AnimatedLogo extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedLogo({required this.animation});

  // Define the size for the logo image
  static const double _logoSize = 120.0;

  // Define the correct, fully-qualified asset path
  static const String _logoAssetPath = 'assets/images/logo.jpeg';

  @override
  Widget build(BuildContext context) {
    // We use FadeTransition on the custom Image.asset
    return FadeTransition(
      opacity: animation,
      child: Container(
        width: _logoSize,
        height: _logoSize,
        // Use Image.asset to load the logo from the specified path
        child: Image.asset(
          // CORRECTED PATH: assets/images/logo.jpeg
          _logoAssetPath,
          fit: BoxFit.cover, // Ensure the image covers the container
          errorBuilder: (context, error, stackTrace) {
            // Fallback in case the image asset is not found at runtime
            final colorScheme = Theme.of(context).colorScheme;
            // The image asset is referenced here. If it fails to load due to
            // the build error, the Icon fallback will show.
            return Icon(
              Icons.account_balance,
              size: _logoSize * 0.8,
              color: colorScheme.primary, // Use primary color for fallback icon
            );
          },
        ),
      ),
    );
  }
}