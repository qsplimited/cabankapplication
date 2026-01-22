import 'package:flutter/material.dart';
import '../models/fd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class FdResultScreen extends StatelessWidget {
  final FdConfirmationResponse response;

  const FdResultScreen({super.key, required this.response});

  // Helper method for navigation logic: navigates back to the DepositOpeningScreen.
  void _navigateToDepositOpeningScreen(BuildContext context) {
    // We assume the flow was:
    // 1. DepositOpeningScreen
    // 2. FdTdInputScreen
    // 3. FdConfirmationScreen (The screen that pushed this ResultScreen)
    // To get back to the DepositOpeningScreen, we need to pop three times.
    int count = 0;
    Navigator.of(context).popUntil((route) {
      // route.isFirst is too far back. We use a counter.
      return count++ == 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool isSuccess = response.success;
    final Color iconColor = isSuccess ? kSuccessGreen : kErrorRed;
    final String title = isSuccess ? 'Deposit Successful!' : 'Deposit Failed!';
    final IconData icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;

    return Scaffold(
      appBar: AppBar(
        title: Text('FD Confirmation Result', style: textTheme.titleLarge?.copyWith(color: kLightSurface)),
        backgroundColor: colorScheme.primary,

        automaticallyImplyLeading: true,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kLightSurface),
          onPressed: () => _navigateToDepositOpeningScreen(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Status Icon
              Icon(
                icon,
                size: kIconSizeXXL,
                color: iconColor,
              ),
              const SizedBox(height: kPaddingLarge),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: iconColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: kPaddingMedium),

              // Message
              Text(
                response.message,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: kPaddingLarge),


              if (isSuccess && response.transactionId != null)
                Card(
                  elevation: kCardElevation,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                  child: Padding(
                    padding: const EdgeInsets.all(kPaddingMedium),
                    child: Column(
                      children: [
                        Text(
                          'Transaction ID:', // Changed label for consistency
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                        const SizedBox(height: kPaddingSmall),
                        Text(
                          response.transactionId!, // FIXED: Use transactionId
                          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: kPaddingXXL),

              // Action Button (Back to Deposit Opening Screen)
              SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: ElevatedButton(
                  onPressed: () => _navigateToDepositOpeningScreen(context),
                  child: const Text('BACK TO HOME'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}