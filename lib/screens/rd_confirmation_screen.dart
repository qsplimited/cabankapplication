// File: lib/screens/rd_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Assuming these models and theme constants are available via imports
import '../api/rd_api_service.dart';
import '../api/mock_otp_service.dart'; // Existing Mock Service
import '../api/mock_fd_api_service.dart'; // Needed to pass to DepositReceiptScreen
import '../models/rd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart' hide kSpacingMedium;
import 'otp_verification_dialog.dart'; // Existing Dialog



// Mock service initialization (In a real app, use Dependency Injection)
final OtpService _otpService = MockOtpService();
// NOTE: mockRegisteredMobile from mock_otp_service.dart is '9876543210'.
// Changed the mock string here to match for consistency.
const String mockRegisteredMobile = '9876543210';


// Helper function for currency formatting
String _formatCurrency(double amount) => '₹${NumberFormat('#,##0.00').format(amount)}';

// Constants
const double kSpacingMedium = 12.0;
const double kLabelColumnWidth = 120.0; // Assuming this constant is needed for alignment

class RdConfirmationScreen extends StatelessWidget {
  final RdApiService apiService;
  final RdInputData inputData;
  final RdMaturityDetails maturityDetails;

  const RdConfirmationScreen({
    super.key,
    required this.apiService,
    required this.inputData,
    required this.maturityDetails,
  });

  // --- Helper Widget to display a row of details ---
  Widget _buildDetailRow(
      BuildContext context,
      String label,
      String value,
      {Color valueColor = kLightTextPrimary, TextStyle? valueStyle}
      ) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPaddingExtraSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: kLabelColumnWidth, // Use fixed width for label
            child: Text(label, style: textTheme.bodyMedium?.copyWith(color: kLightTextSecondary)),
          ),
          const SizedBox(width: kPaddingMedium),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ?? textTheme.bodyLarge?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Core Logic for Finalizing Deposit (FIXED OTP CHECK) ---
  void _confirmDeposit(BuildContext context) async {
    // 1. Launch OTP Verification Dialog
    final String? otpResult = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpVerificationDialog(
        otpService: _otpService,
        mobileNumber: mockRegisteredMobile,
      ),
    );

    // 2. Check OTP result
    // The dialog returns the verified OTP string (6 digits) on success, or null on cancel.
    if (otpResult != null && otpResult.length == 6) {

      // 3. OTP successful, finalize deposit
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP verified. Finalizing Recurring Deposit...'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      try {
        // CALL API METHOD: submitRdDeposit returns transactionId
        final transactionId = await apiService.submitRdDeposit(
          inputData: inputData,
          maturityDetails: maturityDetails,
          // NOTE: The mock RD API doesn't currently take the OTP,
          // but if it did, we would pass it here: otp: otpResult,
        );

        // 4. SUCCESS: Navigate to the new DepositReceiptScreen and clear the navigation stack
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const SuccessScreen(
              title: 'Recuring Deposit Confirmed!',
              message: 'Your Fixed Deposit has been successfully created and the amount has been debited from your account.',
              // NOTE: You could optionally pass a 'View Receipt' action/button here
            ),
          ),
              (Route<dynamic> route) => route.isFirst, // Clear all routes and go to Home
        );
      } catch (e) {
        // API failed
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide 'Finalizing' message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else {
      // OTP failed or dialog cancelled (otpResult will be null or incorrect length)
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpResult == null
              ? 'Transaction cancelled by user.'
              : 'OTP verification failed. Please try again.'),
          backgroundColor: otpResult == null ? kWarningYellow : Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final data = inputData;
    final details = maturityDetails;

    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Recurring Deposit', style: textTheme.titleLarge?.copyWith(color: kLightSurface)),
        backgroundColor: colorScheme.primary,
        iconTheme: const IconThemeData(color: kLightSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Transaction Summary Card
            Card(
              elevation: kCardElevation,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
              child: Padding(
                padding: const EdgeInsets.all(kPaddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monthly Installment',
                      style: textTheme.bodyLarge?.copyWith(color: kLightTextSecondary),
                    ),
                    const SizedBox(height: kPaddingExtraSmall),
                    Text(
                      _formatCurrency(data.installmentAmount),
                      style: textTheme.headlineMedium?.copyWith(
                        color: kFixedDepositCardColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: kSpacingMedium),
                    _buildDetailRow(context, 'Scheme:', data.selectedScheme.name),
                    _buildDetailRow(context, 'Rate:', '${data.selectedScheme.interestRate}% p.a.'),
                    _buildDetailRow(context, 'Tenure:', '${data.tenureYears} Years, ${data.tenureMonths} Months, ${data.tenureDays} Days'),
                    _buildDetailRow(context, 'Source A/c:', data.sourceAccount.accountNumber),
                    _buildDetailRow(context, 'Nominee:', data.selectedNominee),
                    _buildDetailRow(context, 'Frequency:', data.frequencyMode),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kPaddingMedium),

            // 2. Maturity Details Card
            Card(
              elevation: kCardElevation,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
              child: Padding(
                padding: const EdgeInsets.all(kPaddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Maturity',
                      style: textTheme.titleMedium?.copyWith(color: kBrandNavy),
                    ),
                    const Divider(height: kSpacingMedium),
                    _buildDetailRow(context, 'Total Principal:', _formatCurrency(details.totalPrincipalAmount)),
                    _buildDetailRow(context, 'Interest Earned:', _formatCurrency(details.interestEarned), valueColor: kSuccessGreen),
                    const Divider(height: kSpacingMedium),
                    _buildDetailRow(context, 'Maturity Date:', details.maturityDate),
                    _buildDetailRow(
                        context,
                        'Maturity Amount:',
                        _formatCurrency(details.maturityAmount),
                        valueColor: kBrandNavy,
                        valueStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kPaddingMedium),

            // 3. Confirmation/Warning Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: kPaddingSmall),
              child: Text(
                'By confirming, you authorize the debit of ${_formatCurrency(data.installmentAmount)} from your account for the first installment and recurring debits for subsequent installments. OTP verification is required.',
                style: textTheme.bodySmall?.copyWith(color: kErrorRed),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: kPaddingXXL),

            // 4. Action Buttons
            Row(
              children: [
                // 1. Cancel/Go Back Button
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('GO BACK'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, kButtonHeight),
                      side: const BorderSide(color: kBrandLightBlue, width: 2),
                      foregroundColor: kBrandLightBlue,
                      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: kPaddingMedium),

                // 2. Confirm Deposit Button (Elevated/Primary Action)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDeposit(context),
                    icon: const Icon(Icons.lock_open, size: kIconSizeSmall, color: kLightSurface),
                    label: const Text('CONFIRM'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSuccessGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, kButtonHeight),
                      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      elevation: kCardElevation,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kPaddingMedium),
          ],
        ),
      ),
    );
  }
}


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