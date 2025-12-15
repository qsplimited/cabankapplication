
import 'package:cabankapplication/screens/success_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/fd_api_service.dart';
import '../api/mock_rd_api_service.dart';
import '../models/fd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart' hide kSpacingMedium;

import '../api/mock_otp_service.dart';

import 'otp_verification_dialog.dart';


// Mock service initialization constants
final OtpService _otpService = MockOtpService();
const String mockRegisteredMobile = '9876543210';

// Constants
const double kSpacingMedium = 12.0;


extension StringExtension on String {
  String titleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

String _formatCurrency(double amount) => '₹${NumberFormat('#,##0.00').format(amount)}';



class FdConfirmationScreen extends StatefulWidget {
  final FdApiService apiService;
  final FdInputData inputData;
  final MaturityDetails maturityDetails;

  const FdConfirmationScreen({
    super.key,
    required this.apiService,
    required this.inputData,
    required this.maturityDetails,
  });

  @override
  State<FdConfirmationScreen> createState() => _FdConfirmationScreenState();
}

class _FdConfirmationScreenState extends State<FdConfirmationScreen> {
  bool _isConfirming = false;

  // Helper widget to display a single detail row
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
          Text(label, style: textTheme.bodyMedium?.copyWith(color: kLightTextSecondary)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: valueStyle ?? textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Core Confirmation Logic (Now uses the verified OTP) ---
  Future<void> _confirmDeposit(BuildContext context) async {
    if (_isConfirming) return;

    // 1. Show the GENERIC OTP Dialog
    final String? otpResult = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpVerificationDialog(
        otpService: _otpService,
        mobileNumber: mockRegisteredMobile,
      ),
    );

    // 2. Check OTP result
    if (otpResult == null || otpResult.length != 6) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fixed Deposit transaction cancelled.')),
      );
      return;
    }

    // 3. OTP successful, proceed with final API call
    setState(() => _isConfirming = true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('OTP verified. Finalizing Fixed Deposit...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );

    try {
      final String confirmedOtp = otpResult;

      final response = await widget.apiService.confirmDeposit(
        otp: confirmedOtp,
        amount: widget.inputData.amount,
        accountId: widget.inputData.sourceAccount.accountNumber,
      );

      if (!context.mounted) return;

      if (response.success && response.transactionId != null) {
        // 4. SUCCESS: Navigate to the generic SuccessScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const SuccessScreen(
              title: 'Fixed Deposit Confirmed!',
              message: 'Your Fixed Deposit has been successfully created and the amount has been debited from your account.',
            ),
          ),
              (Route<dynamic> route) => route.isFirst, // Clear all routes and go to Home
        );
      } else {
        // 4. FAILURE: Show error result
        _showErrorDialog(context, response.message);
      }
    } catch (e) {
      if (!context.mounted) return;
      // Handle general error (e.g., network failure)
      _showErrorDialog(context, 'Transaction failed due to an unexpected error: $e');
    } finally {
      if(context.mounted) setState(() => _isConfirming = false);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    // Hide any previous snackbars (like the "Finalizing" message)
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final data = widget.inputData;
    final details = widget.maturityDetails;

    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Fixed Deposit', style: textTheme.titleLarge?.copyWith(color: kLightSurface)),
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
                    // FIX: Changed to Row layout for single straight line display of amount
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center, // Vertically center the text
                      children: [
                        // FD Amount Label (Left aligned)
                        Text(
                          'FD Amount',
                          style: textTheme.bodyLarge?.copyWith(color: kLightTextSecondary),
                        ),
                        // The Actual Amount (Right aligned and prominent)
                        Text(
                          _formatCurrency(data.amount),
                          style: textTheme.headlineMedium?.copyWith(
                            color: kFixedDepositCardColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: kSpacingMedium),
                    _buildDetailRow(context, 'Scheme:', data.selectedScheme.name.titleCase()),
                    _buildDetailRow(context, 'Rate:', '${data.selectedScheme.interestRate}% p.a.'),
                    _buildDetailRow(context, 'Tenure:', '${data.tenureYears} Years, ${data.tenureMonths} Months, ${data.tenureDays} Days'),
                    _buildDetailRow(context, 'Source A/c:', data.sourceAccount.accountNumber),
                    _buildDetailRow(context, 'Nominee:', data.selectedNominee),
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
                    _buildDetailRow(context, 'Maturity Date:', details.maturityDate),
                    _buildDetailRow(context, 'Interest Earned:', _formatCurrency(details.interestEarned), valueColor: kSuccessGreen),
                    const Divider(height: kSpacingMedium),
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
                // FIX: Removed the double asterisks (**)
                'By confirming, you authorize the debit of ${_formatCurrency(data.amount)} from your account and agree to the FD terms and conditions. OTP verification is required.',
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
                    onPressed: _isConfirming ? null : () => Navigator.of(context).pop(),
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
                  child: ElevatedButton( // Changed from ElevatedButton.icon to standard ElevatedButton
                    onPressed: _isConfirming ? null : () => _confirmDeposit(context),
                    // Removed the icon property entirely

                    child: _isConfirming
                        ? Row( // Use a Row to center the loading indicator and text
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Loading Indicator replaces the icon
                        const SizedBox(
                          width: kIconSizeSmall,
                          height: kIconSizeSmall,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(kLightSurface),
                          ),
                        ),
                        const SizedBox(width: kPaddingSmall), // Add spacing between indicator and text
                        // Text remains
                        Text('CONFIRMING...', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    )
                        : Text(
                      'CONFIRM & PAY',
                      style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSuccessGreen,
                      foregroundColor: kLightSurface,
                      minimumSize: const Size(double.infinity, kButtonHeight),
                      // Text style is handled in the child widget for the loading state consistency
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