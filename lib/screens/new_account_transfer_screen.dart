import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/banking_service.dart';
import '../main.dart'; // Assuming Account model is here

// Enum for the two main stages of this specific transfer flow
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
  // We'll reuse the amount entry form key from the old code logic later

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ifsController = TextEditingController();

  // --- State Variables ---
  TransferStage _currentStage = TransferStage.verification;
  bool _isLoading = false;
  String _recipientName = '';
  String _bankName = '';

  final Color _primaryColor = const Color(0xFF003366); // Dark Navy Blue

  @override
  void dispose() {
    _accountController.dispose();
    _ifsController.dispose();
    super.dispose();
  }

  // Helper to show snackbar (implementation here)
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon, color: _primaryColor),
      counterText: '',
    );
  }

  Widget _buildVerificationForm() {
    return Form(
      key: _verificationFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Display Source Account Details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _primaryColor.withOpacity(0.2))
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transfer From:', style: TextStyle(fontSize: 14, color: Colors.grey)),
                Text(widget.sourceAccount.nickname, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
                Text('Balance: ₹${widget.sourceAccount.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 30),

          TextFormField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration('Recipient Account Number', Icons.credit_card),
            validator: (value) {
              if (value == null || value.length < 10) return 'Enter a valid account number.';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Confirmation field is typically required here too, but for brevity, we focus on core fields.

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ifsController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 11,
                  decoration: _inputDecoration('IFS Code', Icons.code),
                  validator: (value) {
                    if (value == null || value.length != 11) return 'Enter 11-digit IFS Code.';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              _isLoading
                  ? const SizedBox(width: 45, height: 45, child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _verifyAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.search, size: 20),
                label: const Text('Verify', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountEntryForm() {
    // TODO: This will be where the user enters the amount, type, narration, and T-PIN.
    // This part will be fully implemented in a later step.
    return Center(
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          const SizedBox(height: 10),
          Text('Recipient Verified: $_recipientName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Bank: $_bankName'),
          const SizedBox(height: 20),
          const Text('Proceed to enter amount and complete transaction.'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Account Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_currentStage == TransferStage.amountEntry)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStage = TransferStage.verification;
                });
              },
              child: const Text('Change Details', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: _currentStage == TransferStage.verification
            ? _buildVerificationForm()
            : _buildAmountEntryForm(),
      ),
    );
  }
}