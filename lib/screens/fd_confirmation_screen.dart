// lib/screens/fd_confirmation_screen.dart

import 'package:cabankapplication/screens/success_screen.dart'; // Shared generic screen
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/fd_api_service.dart';
import '../models/fd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart' hide kSpacingMedium;
import '../api/mock_otp_service.dart';
import 'otp_verification_dialog.dart';

// Mock service initialization constants
final OtpService _otpService = MockOtpService();
const String mockRegisteredMobile = '9876543210';

// Local Constants
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

  String _formatCurrency(double amount) => '₹${NumberFormat('#,##0.00').format(amount)}';

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
          const SizedBox(width: 30),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
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

  // --- Core Confirmation Logic ---
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

    try {
      final response = await widget.apiService.confirmDeposit(
        otp: otpResult,
        amount: widget.inputData.amount,
        accountId: widget.inputData.sourceAccount.accountNumber,
      );

      if (!context.mounted) return;

      if (response.success && response.transactionId != null) {
        // 4. SUCCESS: Use Shared SuccessScreen and clear stack back to Dashboard
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const SuccessScreen(
              title: 'Fixed Deposit Confirmed!',
              message: 'Your Fixed Deposit has been successfully created and the amount has been debited from your account.',
            ),
            settings: const RouteSettings(name: '/success'),
          ),
              (Route<dynamic> route) => route.settings.name == '/dashboard',
        );
      } else {
        _showErrorDialog(context, response.message);
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorDialog(context, 'Transaction failed due to an unexpected error: $e');
    } finally {
      if(context.mounted) setState(() => _isConfirming = false);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'FD Amount',
                          style: textTheme.bodyLarge?.copyWith(color: kLightTextSecondary),
                        ),
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
                'By confirming, you authorize the debit of ${_formatCurrency(data.amount)} from your account and agree to the FD terms and conditions. OTP verification is required.',
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
                    onPressed: _isConfirming ? null : () => Navigator.of(context).pop(),
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
                  child: ElevatedButton(
                    onPressed: _isConfirming ? null : () => _confirmDeposit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSuccessGreen,
                      foregroundColor: kLightSurface,
                      minimumSize: const Size(double.infinity, kButtonHeight),
                    ),
                    child: _isConfirming
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('CONFIRM & PAY'),
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