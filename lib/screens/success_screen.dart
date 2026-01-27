import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class SuccessScreen extends StatelessWidget {
  final String title;
  final String message;
  final String? subMessage;

  const SuccessScreen({
    super.key,
    required this.title,
    required this.message,
    this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Success Icon
              const Icon(Icons.check_circle, color: kSuccessGreen, size: 100),
              const SizedBox(height: kPaddingExtraLarge),

              // 2. Title (e.g., "Fixed Deposit Confirmed!")
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: kBrandNavy, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: kPaddingMedium),

              // 3. Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600]),
              ),
              const SizedBox(height: kPaddingXXL),

              // 4. THE NAVIGATION FIX BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange, // Matches your input screens
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // This clears the transaction flow and goes back to Dashboard
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/dashboard',
                          (route) => false,
                    );
                  },
                  child: const Text(
                    'GO TO DASHBOARD',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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