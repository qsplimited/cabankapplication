// File: lib/screens/fd_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../api/fd_api_service.dart';
import '../api/mock_rd_api_service.dart';
import '../models/fd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart' hide kSpacingMedium; // REQUIRED IMPORT for kTpinFieldSize
import 'deposit_receipt_screen.dart';

// -----------------------------------------------------------------------------
// Utility extension for title casing scheme names
// -----------------------------------------------------------------------------
extension StringExtension on String {
  String titleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

// Helper function for currency formatting
String _formatCurrency(double amount) => '₹${NumberFormat('#,##0.00').format(amount)}';


// -----------------------------------------------------------------------------
// Main Widget
// -----------------------------------------------------------------------------

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

  // --- T-PIN Dialog Logic ---
  Future<String?> _showTpinDialog(BuildContext context) {
    final TextEditingController tpinController = TextEditingController();
    final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
            builder: (context, setState) {
              final textTheme = Theme.of(context).textTheme;

              String _getTpinFromController() {
                return List.generate(6, (i) {
                  if (i < tpinController.text.length) {
                    return tpinController.text[i];
                  }
                  return '';
                }).join();
              }

              String _currentTpin = _getTpinFromController();
              final bool _isTpinComplete = _currentTpin.length == 6;

              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                title: Text(
                  'Confirm Deposit with T-PIN',
                  style: textTheme.titleLarge?.copyWith(color: kBrandNavy),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter your 6-digit Transaction PIN (T-PIN) to confirm the Fixed Deposit.',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(color: kLightTextSecondary),
                    ),
                    const SizedBox(height: kPaddingMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: kTpinFieldSize, // Uses the constant
                          child: TextFormField(
                            controller: tpinController,
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6)
                            ],
                            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.zero,
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              setState(() {

                                if (value.isNotEmpty && index < 5 && value.length > index) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0 && tpinController.text.length < index) {
                                  _focusNodes[index - 1].requestFocus();
                                }

                                _currentTpin = _getTpinFromController();
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(null); // Pass null indicating CANCEL
                    },
                    child: Text('CANCEL', style: textTheme.labelLarge?.copyWith(color: kErrorRed)),
                  ),
                  ElevatedButton(
                    onPressed: _isTpinComplete
                        ? () {
                      Navigator.of(context).pop(tpinController.text);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                      elevation: kCardElevation,
                    ),
                    child: Text(
                      'SUBMIT',
                      style: textTheme.labelLarge?.copyWith(color: kLightSurface, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: kPaddingSmall),
                ],
              );
            }
        );
      },
    );
  }


  // --- Core Confirmation Logic (UPDATED NAVIGATION) ---
  Future<void> _submitTpin(BuildContext context) async {
    if (_isConfirming) return;

    // 1. Show T-PIN Dialog
    final String? tpin = await _showTpinDialog(context);

    if (tpin == null || tpin.length != 6) return;

    setState(() => _isConfirming = true);

    try {
      // 2. Call API
      final response = await widget.apiService.confirmDeposit(
        tpin: tpin,
        amount: widget.inputData.amount,
        accountId: widget.inputData.sourceAccount.accountNumber,
      );

      if (!context.mounted) return;

      if (response.success && response.transactionId != null) {
        // 3. SUCCESS: Navigate to DepositReceiptScreen using the new `transactionId`
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => DepositReceiptScreen(
              transactionId: response.transactionId!,
              fdApiService: widget.apiService,
              rdApiService: MockRdApiService(),
              depositType: 'FD',
            ),
          ),
              (Route<dynamic> route) => route.isFirst,
        );
      } else {
        // 3. FAILURE: Show error result
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
                    Text(
                      'FD Amount',
                      style: textTheme.bodyLarge?.copyWith(color: kLightTextSecondary),
                    ),
                    const SizedBox(height: kPaddingExtraSmall),
                    Text(
                      _formatCurrency(data.amount),
                      style: textTheme.headlineMedium?.copyWith(
                        color: kFixedDepositCardColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(height: kSpacingMedium),
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
                'By confirming, you authorize the debit of ${_formatCurrency(data.amount)} from your account and agree to the FD terms and conditions.',
                style: textTheme.bodySmall?.copyWith(color: kErrorRed),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: kPaddingXXL),

            // 4. Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConfirming ? null : () => _submitTpin(context),
                icon: _isConfirming
                    ? const SizedBox(width: kIconSizeSmall, height: kIconSizeSmall, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(kLightSurface)))
                    : const Icon(Icons.lock_open, size: kIconSizeSmall, color: kLightSurface),
                label: Text(
                  _isConfirming ? 'CONFIRMING...' : 'CONFIRM & PAY',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandNavy,
                  foregroundColor: kLightSurface,
                  minimumSize: const Size(double.infinity, kButtonHeight),
                  textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  elevation: kCardElevation,
                ),
              ),
            ),
            const SizedBox(height: kPaddingSmall),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isConfirming ? null : () => Navigator.of(context).pop(),
                child: const Text('GO BACK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}