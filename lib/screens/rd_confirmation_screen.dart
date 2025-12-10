// File: lib/screens/rd_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Assuming these models and theme constants are available via imports
import '../api/rd_api_service.dart';
import '../api/mock_otp_service.dart'; // Existing Mock Service
import '../api/mock_fd_api_service.dart'; // 🌟 NEW IMPORT: Needed to pass to DepositReceiptScreen
import '../models/rd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart' hide kSpacingMedium;
import 'otp_verification_dialog.dart'; // Existing Dialog
import 'deposit_receipt_screen.dart'; // 🌟 NEW IMPORT
// REMOVED: import 'success_screen.dart';


// Mock service initialization (In a real app, use Dependency Injection)
final OtpService _otpService = MockOtpService();
const String mockRegisteredMobile = '98765 43210'; // Mock mobile number for OTP dialog


// Helper function for currency formatting
String _formatCurrency(double amount) => '₹${NumberFormat('#,##0.00').format(amount)}';

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

  // --- Core Logic for Finalizing Deposit (UPDATED NAVIGATION) ---
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

    // 2. Check OTP result (Assuming 'SUCCESS' is returned on success)
    if (otpResult == 'SUCCESS') {
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
        );

        // 4. SUCCESS: Navigate to the new DepositReceiptScreen and clear the navigation stack
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => DepositReceiptScreen(
              transactionId: transactionId, // Pass the transaction ID
              rdApiService: apiService,
              // Pass a MockFdApiService here, as the ReceiptScreen takes both.
              fdApiService: MockFdApiService(),
              depositType: 'RD',
            ),
          ),
              (Route<dynamic> route) => route.isFirst,
        );
      } catch (e) {
        // API failed
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else if (otpResult == 'CANCELLED') {
      // OTP dialog cancelled
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction cancelled by user.'),
          backgroundColor: kWarningYellow,
        ),
      );
    } else {
      // OTP failed or dialog dismissed due to failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(otpResult ?? 'OTP verification failed. Please try again.'),
          backgroundColor: Theme.of(context).colorScheme.error,
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