import 'package:flutter/material.dart';

// Import Theme constants
import 'package:cabankapplication/theme/app_dimensions.dart';
import 'package:cabankapplication/theme/app_colors.dart';

/// Screen to display the result (success or failure) of a fund transfer.
class TransferResultScreen extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const TransferResultScreen({
    super.key,
    required this.message,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Determine semantic colors and icons based on success state
    // Use kSuccessGreen and kErrorRed constants from app_colors.dart
    final Color statusColor = isSuccess ? kSuccessGreen : kErrorRed;
    final IconData icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;
    final String title = isSuccess ? 'Transfer Successful' : 'Transfer Failed';

    // Dynamic button label based on success/failure
    final String buttonLabel = isSuccess ? 'DONE / NEW TRANSFER' : 'RETRY TRANSFER';

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: Text(
          title,
          // Use onPrimary/onSurface color for text on the status-colored AppBar
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary, // Assuming onPrimary works well on both primary and semantic colors
          ),
        ),
        // AppBar color is set to the status color
        backgroundColor: statusColor,
        automaticallyImplyLeading: false, // Prevents back button on result
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          // Padding from constants
          padding: const EdgeInsets.all(kPaddingExtraLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                // Icon size from constants
                size: kIconSizeXXL,
                color: statusColor,
              ),
              // Spacing from constants
              const SizedBox(height: kPaddingExtraLarge),
              Text(
                title,
                // Using theme's headlineMedium style for prominence
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onBackground, // Primary text color
                ),
                textAlign: TextAlign.center,
              ),
              // Spacing from constants
              const SizedBox(height: kPaddingMedium),
              Container(
                // Padding from constants
                padding: const EdgeInsets.all(kPaddingLarge),
                decoration: BoxDecoration(
                  // Background color uses status color with low opacity
                    color: statusColor.withOpacity(0.08),
                    // Border radius from constants
                    borderRadius: BorderRadius.circular(kRadiusLarge),
                    // Border color uses status color with moderate opacity
                    border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5)
                ),
                child: Text(
                  message,
                  // Using theme's bodyLarge for message
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onBackground, // Use primary text color
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Spacing from constants
              const SizedBox(height: kPaddingXXL),
              SizedBox(
                width: double.infinity,
                // Button height from constants
                height: kButtonHeight,
                child: ElevatedButton(
                  onPressed: () {
                    // This pops the current Result screen and returns to the previous screen (TransferAmountEntryScreen)
                    // This works for both success (to start new) and failure (to retry).
                    Navigator.of(context).pop();
                  },
                  // Styles inherited from the main theme (AppTheme's ElevatedButtonTheme)
                  // Overriding properties to use the correct status color for failure/retry visibility
                  style: ElevatedButton.styleFrom(
                    // Use primary color for success, or statusColor for failure/retry
                    backgroundColor: isSuccess ? colorScheme.primary : statusColor,
                    // Rely on theme for padding and shape, but explicitly set here for safety if theme isn't perfect
                    padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                  ),
                  child: Text(
                    buttonLabel,
                    // Use onPrimary for button text color
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18, // Explicitly set size if labelLarge is too small
                    ),
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