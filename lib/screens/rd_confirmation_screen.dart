// File: lib/screens/rd_confirmation_screen.dart (REVERTED TO PREVIOUS LOGIC)

import 'package:flutter/material.dart';

// Assuming these models and theme constants are available via imports
import '../api/rd_api_service.dart';
import '../api/mock_otp_service.dart'; // NEW IMPORT
import '../models/rd_models.dart';
// REMOVED: import '../models/receipt_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'success_screen.dart';
import 'otp_verification_dialog.dart'; // NEW IMPORT

// Mock service initialization (In a real app, use Dependency Injection)
final OtpService _otpService = MockOtpService();


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
        children: [
          // FIX: Label size adjusted to bodyMedium, using secondary color
          Text(label, style: textTheme.bodyMedium?.copyWith(color: kLightTextSecondary)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              // FIX: Default value style changed to bodyLarge, which is less prominent than titleMedium
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

  // --- Helper Widget to build a section card ---
  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    Color? color,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: kCardElevation,
      color: color ?? Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title remains titleLarge (20px) for section heading clarity
            Text(title, style: textTheme.titleLarge?.copyWith(color: kBrandNavy)),
            const Divider(color: kLightDivider, height: kPaddingMedium),
            ...children,
          ],
        ),
      ),
    );
  }

  // --- Core Logic for Finalizing Deposit (REVERTED to Old Logic) ---
  void _confirmDeposit(BuildContext context) async {

    // 1. Launch OTP Verification Dialog
    final bool? otpVerified = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must verify or explicitly close
      builder: (context) => OtpVerificationDialog(
        otpService: _otpService,
        // Using the mock registered mobile number for the dialog
        mobileNumber: mockRegisteredMobile,
      ),
    );

    // 2. Check OTP result
    if (otpVerified == true) {
      // 3. OTP successful, finalize deposit (Simulate API call: apiService.openRD(inputData))
      // Show final processing feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('OTP verified. Finalizing Recurring Deposit...'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Simulate Final API delay
      await Future.delayed(const Duration(milliseconds: 1000));

      // 4. Navigate to a success screen and clear the navigation stack below it
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          // REVERTED: Using old SuccessScreen constructor with strings
          builder: (context) => const SuccessScreen(
            title: 'RD Created Successfully!',
            message: 'Your new Recurring Deposit contract is now active and the first installment has been debited from your account.',
          ),
        ),
            (Route<dynamic> route) => route.isFirst,
      );
    } else {
      // OTP failed or dialog dismissed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaction failed or OTP verification cancelled.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Helper function to format amount
    String formatCurrency(double amount) => '₹${amount.toStringAsFixed(2)}';

    // Frequency conversion for display
    final frequencyMap = {
      'Monthly': 'Every Month',
      'Quarterly': 'Every 3 Months',
      'Half-Yearly': 'Every 6 Months',
    };

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
            // --- 1. DEPOSIT SUMMARY ---
            _buildSectionCard(
              context: context,
              title: 'Deposit Summary',
              children: [
                _buildDetailRow(context, 'Source Account:', inputData.sourceAccount.accountNumber),
                _buildDetailRow(context, 'Scheme Name:', inputData.selectedScheme.name),
                _buildDetailRow(context, 'Interest Rate:', '${inputData.selectedScheme.interestRate.toStringAsFixed(2)}% p.a.'),
                _buildDetailRow(
                    context,
                    'Tenure:',
                    '${inputData.tenureYears} Years, ${inputData.tenureMonths} Months'
                ),
                _buildDetailRow(
                    context,
                    'Deposit Frequency:',
                    '${frequencyMap[inputData.frequencyMode] ?? inputData.frequencyMode}'
                ),
                _buildDetailRow(context, 'Nominee:', inputData.selectedNominee),
              ],
            ),
            const SizedBox(height: kPaddingMedium),

            // --- 2. PAYMENT & MATURITY DETAILS (Moved from Input Screen) ---
            _buildSectionCard(
              context: context,
              title: 'Maturity Details (Estimated)',
              color: kInputBackgroundColor,
              children: [
                // The amount to be paid NOW (first installment)
                _buildDetailRow(
                  context,
                  'Installment Amount (Initial Debit):',
                  formatCurrency(inputData.installmentAmount),
                  valueColor: kFixedDepositCardColor,
                ),
                const Divider(height: kSpacingMedium),

                // Maturity Breakdown (Principal & Interest)
                _buildDetailRow(
                    context,
                    'Total Principal Investment:',
                    formatCurrency(maturityDetails.totalPrincipalAmount)
                ),
                _buildDetailRow(
                  context,
                  'Total Interest Earned (Est.):',
                  formatCurrency(maturityDetails.interestEarned),
                  valueColor: kSuccessGreen,
                ),
                const Divider(height: kSpacingMedium),

                // Final Maturity Amount & Date
                _buildDetailRow(
                    context,
                    'Estimated Maturity Amount:',
                    formatCurrency(maturityDetails.maturityAmount),
                    valueStyle: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kBrandNavy
                    )
                ),
                _buildDetailRow(
                    context,
                    'Estimated Maturity Date:',
                    maturityDetails.maturityDate,
                    valueColor: kBrandNavy
                ),
              ],
            ),
            const SizedBox(height: kPaddingXXL),

            // --- 3. ACTION BUTTONS (Edit Details and Confirm) ---
            Row(
              children: [
                // 1. Edit Details / Back Button (Outlined/Secondary Action)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(), // Go back to RdInputScreen
                    icon: const Icon(Icons.edit, size: kIconSizeSmall),
                    label: const Text('EDIT DETAILS'),
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
                    // Icon changed to reflect security/verification required
                    icon: const Icon(Icons.lock_open, size: kIconSizeSmall),
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