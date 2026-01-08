import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/banking_service.dart';
import '../main.dart'; // Assuming Account model is here


import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';


enum TransferStage { verification, amountEntry }

class NewAccountTransferScreen extends StatefulWidget {
  final BankingService bankingService;
  final Account sourceAccount;

  const NewAccountTransferScreen({
    Key? key,
    required this.bankingService,
    required this.sourceAccount,
  }) : super(key: key);

  @override
  State<NewAccountTransferScreen> createState() => _NewAccountTransferScreenState();
}

class _NewAccountTransferScreenState extends State<NewAccountTransferScreen> {
  // --- Controllers and Keys ---
  final GlobalKey<FormState> _verificationFormKey = GlobalKey<FormState>();

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ifsController = TextEditingController();

  // --- State Variables ---
  TransferStage _currentStage = TransferStage.verification;
  bool _isLoading = false;
  String _recipientName = '';
  String _bankName = '';



  @override
  void dispose() {
    _accountController.dispose();
    _ifsController.dispose();
    super.dispose();
  }

  // Helper to show snackbar (Refactored to use theme colors)
  void _showSnackBar(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        // Refactored hardcoded colors to theme/constants
        backgroundColor: isError ? colorScheme.error : kSuccessGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- STAGE 1: ACCOUNT VERIFICATION (Core Logic from your old screen) ---
  Future<void> _verifyAccount() async {
    if (!_verificationFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      final result = await widget.bankingService.lookupRecipient(
        recipientAccount: _accountController.text.trim(),
        ifsCode: _ifsController.text.trim(),
      );

      setState(() {
        _recipientName = result['officialName']!;
        _bankName = result['bankName']!;
        _currentStage = TransferStage.amountEntry; // Move to next stage
        _showSnackBar('Account Verified: $_recipientName', isError: false);
      });
    } catch (e) {
      String errorMessage = e is String ? e : (e as Exception).toString().replaceFirst('Exception: ', '');
      _showSnackBar(errorMessage, isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // --- WIDGET BUILDERS ---

  // Refactored to accept ColorScheme to apply primary color correctly
  InputDecoration _inputDecoration(String label, IconData icon, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      // Refactored hardcoded 12 to kRadiusMedium
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      // Refactored hardcoded color
      prefixIcon: Icon(icon, color: colorScheme.primary),
      counterText: '',
    );
  }

  Widget _buildVerificationForm() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _verificationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Display Source Account Details (Refactored styling)
          Container(
            // Refactored hardcoded 16 to kPaddingMedium
            padding: const EdgeInsets.all(kPaddingMedium),
            decoration: BoxDecoration(
              // Refactored hardcoded color with theme opacity
                color: colorScheme.primary.withOpacity(0.05),
                // Refactored hardcoded 12 to kRadiusMedium
                borderRadius: BorderRadius.circular(kRadiusMedium),
                // Refactored hardcoded color
                border: Border.all(color: colorScheme.primary.withOpacity(0.2))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer From:',
                  // Refactored hardcoded style
                  style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                ),
                Text(
                  widget.sourceAccount.nickname,
                  // Refactored hardcoded style
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'Balance: ₹${widget.sourceAccount.balance.toStringAsFixed(2)}',
                  // Refactored hardcoded style
                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          // Refactored hardcoded 30 to kPaddingExtraLarge
          const SizedBox(height: kPaddingExtraLarge),

          TextFormField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration('Recipient Account Number', Icons.credit_card, colorScheme),
            validator: (value) {
              if (value == null || value.length < 10) return 'Enter a valid account number.';
              return null;
            },
          ),
          // Refactored hardcoded 16 to kPaddingMedium
          const SizedBox(height: kPaddingMedium),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ifsController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 11,
                  decoration: _inputDecoration('IFS Code', Icons.code, colorScheme),
                  validator: (value) {
                    if (value == null || value.length != 11) return 'Enter 11-digit IFS Code.';
                    return null;
                  },
                ),
              ),
              // Refactored hardcoded 10 to kPaddingTen
              const SizedBox(width: kPaddingTen),
              _isLoading
                  ? SizedBox(
                // Refactored hardcoded 45 to kIconSizeExtraLarge
                width: kIconSizeExtraLarge,
                height: kIconSizeExtraLarge,
                // Refactored CircularProgressIndicator color
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
                  : ElevatedButton.icon(
                onPressed: _verifyAccount,
                style: ElevatedButton.styleFrom(
                  // Refactored hardcoded colors to theme/constants
                  backgroundColor: kSuccessGreen,
                  foregroundColor: colorScheme.onPrimary, // Auto-select white/black for contrast
                  // Refactored hardcoded 16 and 15
                  padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingMedium - 1),
                  // Refactored hardcoded 12 to kRadiusMedium
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                ),
                // Refactored hardcoded 20 to kIconSizeSmall
                icon: const Icon(Icons.search, size: kIconSizeSmall),
                // Refactored hardcoded style
                label: Text('Verify', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountEntryForm() {
    final textTheme = Theme.of(context).textTheme;
    // TODO: This will be where the user enters the amount, type, narration, and T-PIN.

    return Center(
      child: Column(
        children: [
          // Refactored hardcoded Colors.green and 60
          const Icon(Icons.check_circle, color: kSuccessGreen, size: kIconSizeXXL),
          // Refactored hardcoded 10 to kPaddingTen
          const SizedBox(height: kPaddingTen),
          Text(
            'Recipient Verified: $_recipientName',
            // Refactored hardcoded style
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            'Bank: $_bankName',
            style: textTheme.bodyMedium,
          ),
          // Refactored hardcoded 20 to kIconSizeSmall
          const SizedBox(height: kIconSizeSmall),
          Text(
            'Proceed to enter amount and complete transaction.',
            style: textTheme.bodyLarge,
          ),
          // Placeholder button to demonstrate flow
          ElevatedButton(
            onPressed: () {
              // Simulate proceeding to final step
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ready for Amount and T-PIN entry.'))
              );
            },
            child: const Text('Continue to Payment'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Account Transfer',
          // Refactored hardcoded style
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Refactored hardcoded colors
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        actions: [
          if (_currentStage == TransferStage.amountEntry)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStage = TransferStage.verification;
                });
              },
              // Refactored hardcoded style
              child: Text('Change Details', style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        // Refactored hardcoded 24.0 to kPaddingLarge
        padding: const EdgeInsets.all(kPaddingLarge),
        child: _currentStage == TransferStage.verification
            ? _buildVerificationForm()
            : _buildAmountEntryForm(),
      ),
    );
  }
}