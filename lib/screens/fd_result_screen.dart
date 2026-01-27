import 'package:flutter/material.dart';
import '../models/fd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class FdResultScreen extends StatelessWidget {
  final FdConfirmationResponse response;

  const FdResultScreen({super.key, required this.response});

  // FINAL BACK BUTTON LOGIC:
  // This jumps straight to the Dashboard and deletes the rest of the history.
  void _backToDashboard(BuildContext context) {
    // This removes everything (the OTP dialog, the input screen, etc.)
    // and takes you straight to the Dashboard defined in main.dart
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = response.success;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Status', style: TextStyle(color: Colors.white)),
        backgroundColor: isSuccess ? kSuccessGreen : kErrorRed,
        automaticallyImplyLeading: false, // Prevents manual back navigation
      ),
      // SafeArea + SingleChildScrollView is the double-shield against overflows
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                size: 100,
                color: isSuccess ? kSuccessGreen : kErrorRed,
              ),
              const SizedBox(height: kPaddingLarge),
              Text(
                isSuccess ? 'Success!' : 'Failed!',
                style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: kPaddingMedium),

              // Ensure the message never overflows horizontally
              SizedBox(
                width: double.infinity,
                child: Text(
                  response.message,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge,
                ),
              ),

              const SizedBox(height: kPaddingXXL),

              if (isSuccess && response.transactionId != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(kPaddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(kRadiusMedium),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Text('Transaction ID', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 4),
                      // Flexible/SelectableText prevents long ID strings from overflowing
                      SelectableText(
                        response.transactionId!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 60),

              // ACTION BUTTON
              SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrandNavy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                  ),
                  onPressed: () => _backToDashboard(context),
                  child: const Text('BACK TO DASHBOARD',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}