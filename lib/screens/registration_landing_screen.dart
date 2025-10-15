import 'package:flutter/material.dart';
import 'registration_step1_identity.dart';
import 'login_screen.dart';

class RegistrationLandingScreen extends StatelessWidget {
  const RegistrationLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to CABank Mobile'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header and Status
                Text(
                  'Your Device is Not Registered',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'To continue, please select whether you are a new user or an existing user of this app.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 50),


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
                const SizedBox(height: 30),

                // Divider or Separator
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('OR', style: theme.textTheme.bodyLarge),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 30),

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
                SizedBox(height: size.height * 0.1), // Responsive spacing
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
    return Card(
      elevation: isPrimary ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPrimary ? BorderSide(color: theme.primaryColor, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: theme.primaryColor),
            const SizedBox(height: 10),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: isPrimary
                  ? ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(buttonText, style: const TextStyle(fontSize: 16)),
              )
                  : OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: BorderSide(color: theme.primaryColor),
                ),
                child: Text(buttonText, style: TextStyle(fontSize: 16, color: theme.primaryColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
