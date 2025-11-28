import 'package:flutter/material.dart';
import 'registration_step1_identity.dart';
import 'login_screen.dart';
// Import the necessary dimension constants
import '../theme/app_dimensions.dart';

class RegistrationLandingScreen extends StatelessWidget {
  const RegistrationLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        // titleTextStyle is handled by the AppBarTheme in app_theme.dart
        title: const Text('Welcome to CABank Mobile'),
        elevation: kCardElevation, // Use theme elevation constant
      ),
      body: SingleChildScrollView(
        // Replace hardcoded 24.0 with kPaddingLarge
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Center(
          child: ConstrainedBox(
            // Use a reasonable max width for large screens
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header and Status
                Text(
                  'Your Device is Not Registered',
                  textAlign: TextAlign.center,
                  // Use appropriate textTheme and colorScheme
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary, // Use primary color for emphasis
                  ),
                ),
                // Replace hardcoded 10 with kPaddingTen
                const SizedBox(height: kPaddingTen),
                Text(
                  'To continue, please select whether you are a new user or an existing user of this app.',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
                // Replace hardcoded 50 with kSpacingLarge + padding
                const SizedBox(height: 50.0), // Kept 50 for prominent spacing


                // 1. New User Registration Card
                _ActionCard(
                  icon: Icons.app_registration,
                  title: 'New User Registration',
                  description: 'Start a 4-step process to link this device to your bank account.',
                  buttonText: 'Start Registration',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const RegistrationStep1Identity(),
                      ),
                    );
                  },
                  isPrimary: true,
                ),
                // Replace hardcoded 30 with kSpacingLarge
                const SizedBox(height: kSpacingLarge),

                // Divider or Separator
                Row(
                  children: [
                    // Use a divider with the theme's default color
                    const Expanded(child: Divider()),
                    Padding(
                      // Replace hardcoded 16.0 with kPaddingMedium
                      padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium),
                      child: Text('OR', style: textTheme.bodyLarge),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                // Replace hardcoded 30 with kSpacingLarge
                const SizedBox(height: kSpacingLarge),

                // 2. Existing User Login Card (M-PIN Login)
                _ActionCard(
                  icon: Icons.login,
                  title: 'Existing User Login',
                  description: 'If you have registered this app on another device, you can log in directly.',
                  buttonText: 'Go to M-PIN Login',
                  onPressed: () {
                    // Navigate to the Login Screen (M-PIN)
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  },
                  isPrimary: false,
                ),
                // Keep responsive spacing, or replace with a theme constant if defined
                const SizedBox(height: kPaddingXXL * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Reusable Action Cards
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final VoidCallback onPressed;
  final bool isPrimary;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.onPressed,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      // Use kCardElevation and a slightly higher value for primary
      elevation: isPrimary ? kCardElevation + 4 : kCardElevation,
      shape: RoundedRectangleBorder(
        // Replace hardcoded 16 with kRadiusLarge
        borderRadius: BorderRadius.circular(kRadiusLarge),
        side: isPrimary
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        // Replace hardcoded 24.0 with kPaddingLarge
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              // Replace hardcoded 40 with kIconSizeXXL or kIconSizeExtraLarge (45.0)
              size: kIconSizeExtraLarge,
              color: colorScheme.primary,
            ),
            // Replace hardcoded 10 with kPaddingTen
            const SizedBox(height: kPaddingTen),
            Text(
              title,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            // Replace hardcoded 8 with kPaddingSmall
            const SizedBox(height: kPaddingSmall),
            Text(description, style: textTheme.bodyMedium),
            // Replace hardcoded 20 with kPaddingLarge - 4
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: isPrimary
                  ? ElevatedButton(
                onPressed: onPressed,
                // ElevatedButton style is largely handled by the theme
                style: ElevatedButton.styleFrom(
                  // Replace hardcoded 14 with kPaddingMedium - 2
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  // Replace hardcoded 10 with kPaddingTen
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kPaddingTen)),
                ),
                // Text style is handled by the theme (ElevatedButtonThemeData)
                child: Text(
                  buttonText,
                  // The theme's labelLarge (14) is used, so use 16 here to override
                  style: textTheme.labelLarge?.copyWith(fontSize: 16),
                ),
              )
                  : OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  // Replace hardcoded 14 with kPaddingMedium - 2
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  // Replace hardcoded 10 with kPaddingTen
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kPaddingTen)),
                  // Use colorScheme.primary for the border
                  side: BorderSide(color: colorScheme.primary),
                ),
                child: Text(
                  buttonText,
                  // Use colorScheme.primary for text color
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 16,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}