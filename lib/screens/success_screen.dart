// File: lib/screens/success_screen.dart

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class SuccessScreen extends StatelessWidget {
  final String title;
  final String message;

  const SuccessScreen({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use a prominent check icon for success
              const Icon(Icons.check_circle_outline, color: kSuccessGreen, size: kIconSizeXXL * 1.5),
              const SizedBox(height: kPaddingExtraLarge),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: kBrandNavy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kPaddingMedium),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kPaddingXXL),
              ElevatedButton(
                onPressed: () {
                  // This command correctly clears the entire transaction flow (RD Input, Confirmation, OTP, Success)
                  // and navigates back to the Dashboard/Home screen (the first route in the stack).
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('GO TO HOME'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}