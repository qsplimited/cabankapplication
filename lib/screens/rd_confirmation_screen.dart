// lib/screens/rd_confirmation_screen.dart

import 'package:cabankapplication/screens/success_screen.dart'; // SHARED SUCCESS IMPORT
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/rd_api_service.dart';
import '../api/mock_otp_service.dart';
import '../models/rd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart' hide kSpacingMedium;
import 'otp_verification_dialog.dart';

// Service initialization
final OtpService _otpService = MockOtpService();
const String mockRegisteredMobile = '9876543210';

// Constants
const double kSpacingMedium = 12.0;
const double kLabelColumnWidth = 120.0;

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

  // Helper function for currency formatting
  String _formatCurrency(double amount) => '₹${NumberFormat('#,##0.00').format(amount)}';

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
            width: kLabelColumnWidth,
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

  // --- Core Logic for Finalizing Deposit ---
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
    if (otpResult != null && otpResult.length == 6) {
      // 3. OTP successful, show finalizing snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP verified. Finalizing Recurring Deposit...'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      try {
        // CALL API
        await apiService.submitRdDeposit(
          inputData: inputData,
          maturityDetails: maturityDetails,
        );

        if (!context.mounted) return;

        // 4. SUCCESS: Navigate to the shared SuccessScreen and clear stack back to Dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const SuccessScreen(
              title: 'Recurring Deposit Confirmed!',
              message: 'Your Recurring Deposit has been successfully created and the first installment has been debited.',
            ),
            settings: const RouteSettings(name: '/success'),
          ),
              (Route<dynamic> route) => route.settings.name == '/dashboard',
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transaction failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } else {
      if (!context.mounted) return;
      if (otpResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction cancelled by user.'), backgroundColor: kWarningYellow),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                      _formatCurrency(inputData.installmentAmount),
                      style: textTheme.headlineMedium?.copyWith(
                        color: kFixedDepositCardColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: kSpacingMedium),
                    _buildDetailRow(context, 'Scheme:', inputData.selectedScheme.name),
                    _buildDetailRow(context, 'Rate:', '${inputData.selectedScheme.interestRate}% p.a.'),
                    _buildDetailRow(context, 'Tenure:', '${inputData.tenureYears} Years, ${inputData.tenureMonths} Months'),
                    _buildDetailRow(context, 'Source A/c:', inputData.sourceAccount.accountNumber),
                    _buildDetailRow(context, 'Nominee:', inputData.selectedNominee),
                    _buildDetailRow(context, 'Frequency:', inputData.frequencyMode),
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
                    _buildDetailRow(context, 'Total Principal:', _formatCurrency(maturityDetails.totalPrincipalAmount)),
                    _buildDetailRow(context, 'Interest Earned:', _formatCurrency(maturityDetails.interestEarned), valueColor: kSuccessGreen),
                    const Divider(height: kSpacingMedium),
                    _buildDetailRow(context, 'Maturity Date:', maturityDetails.maturityDate),
                    _buildDetailRow(
                        context,
                        'Maturity Amount:',
                        _formatCurrency(maturityDetails.maturityAmount),
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
                'By confirming, you authorize the debit of ${_formatCurrency(inputData.installmentAmount)} from your account for the first installment and recurring debits for subsequent installments. OTP verification is required.',
                style: textTheme.bodySmall?.copyWith(color: kErrorRed),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: kPaddingXXL),

            // 4. Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, kButtonHeight),
                      side: const BorderSide(color: kBrandLightBlue, width: 2),
                      foregroundColor: kBrandLightBlue,
                    ),
                    child: const Text('GO BACK'),
                  ),
                ),
                const SizedBox(width: kPaddingMedium),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDeposit(context),
                    icon: const Icon(Icons.lock_open, size: kIconSizeSmall, color: kLightSurface),
                    label: const Text('CONFIRM'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSuccessGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, kButtonHeight),
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