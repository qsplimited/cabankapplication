import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import '../api/banking_service.dart';

// Enum for the two main stages of the transfer flow
enum TransferStage { verification, amountEntry }

class TransferFundsScreen extends StatefulWidget {
  final BankingService bankingService;

  const TransferFundsScreen({Key? key, required this.bankingService}) : super(key: key);

  @override
  State<TransferFundsScreen> createState() => _TransferFundsScreenState();
}

class _TransferFundsScreenState extends State<TransferFundsScreen> {
  // State variables for the screen
  final GlobalKey<FormState> _verificationFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _transferFormKey = GlobalKey<FormState>();

  // Controllers for input fields
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _ifsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();

  // State variables for transfer process
  TransferStage _currentStage = TransferStage.verification;
  bool _isLoading = false;

  // Recipient details after successful verification
  String _recipientName = '';
  String _bankName = '';

  // Financial data - Changed to nullable and initialized in initState
  double? _currentBalance;
  TransferType _selectedTransferType = TransferType.imps;

  // T-PIN controller for the secure modal
  final TextEditingController _tpinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Use _fetchAccountBalance to correctly handle the Future
    _fetchAccountBalance();
  }

  // Asynchronously fetch the account balance
  Future<void> _fetchAccountBalance() async {
    try {
      final account = await widget.bankingService.fetchAccountSummary();
      setState(() {
        _currentBalance = account.balance;
      });
    } catch (e) {
      _showSnackBar('Failed to load balance.', isError: true);
    }
  }

  @override
  void dispose() {
    _accountController.dispose();
    _ifsController.dispose();
    _amountController.dispose();
    _narrationController.dispose();
    _tpinController.dispose();
    super.dispose();
  }

  // Helper function to show alerts/messages
  void _showSnackBar(String message, {bool isError = false}) {
    // Dismiss existing snackbars
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- STAGE 1: ACCOUNT VERIFICATION ---
  Future<void> _verifyAccount() async {
    if (!_verificationFormKey.currentState!.validate()) {
      return;
    }

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // NOW COMPILING: Calls the newly implemented lookupRecipient
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- STAGE 2: FUND TRANSFER SUBMISSION ---
  void _showConfirmationModal() {
    if (!_transferFormKey.currentState!.validate()) {
      return;
    }

    // Reset T-PIN controller for a fresh entry
    _tpinController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            // Ensure padding for the keyboard
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text('Secure Transaction Confirmation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(height: 20),

              // Confirmation Details
              _buildConfirmationDetail('Recipient Name', _recipientName),
              _buildConfirmationDetail('Account Number', _accountController.text),
              _buildConfirmationDetail('Amount', '₹${_amountController.text}'),
              _buildConfirmationDetail('Transfer Type', _selectedTransferType.name.toUpperCase()),

              const SizedBox(height: 20),

              // T-PIN Input Field
              TextFormField(
                controller: _tpinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6, // **ENFORCING 6-DIGIT T-PIN**
                decoration: InputDecoration(
                  labelText: 'Enter 6-Digit Transaction PIN',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.security),
                  counterText: '', // Hide the character counter
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'T-PIN must be 6 digits.';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => _confirmTransfer(modalContext),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text(
                  'Confirm & Send Money',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConfirmationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // Final API call to submit the transaction
  void _confirmTransfer(BuildContext modalContext) async {
    if (_tpinController.text.length != 6) {
      _showSnackBar('Please enter a valid 6-digit T-PIN.', isError: true);
      return;
    }

    // Prevent double submission
    if (_isLoading) return;

    // Use a temporary context to manage loading state inside the modal
    // while preventing the main screen's state from interfering.
    // However, since _isLoading is a state variable of the main screen, we must use setState.

    setState(() {
      _isLoading = true;
    });

    // Close the keyboard if open
    FocusScope.of(modalContext).unfocus();

    try {
      final resultMessage = await widget.bankingService.submitFundTransfer(
        recipientAccount: _accountController.text,
        recipientName: _recipientName,
        ifsCode: _ifsController.text,
        transferType: _selectedTransferType,
        amount: double.parse(_amountController.text),
        narration: _narrationController.text.trim(),
        transactionPin: _tpinController.text, // PASSING THE T-PIN TO THE API
      );

      // Re-fetch current balance after transaction
      await _fetchAccountBalance();

      // Reset UI state for a new transfer
      setState(() {
        _currentStage = TransferStage.verification;
        _accountController.clear();
        _ifsController.clear();
        _amountController.clear();
        _narrationController.clear();
        _tpinController.clear();
      });

      // Close modal and show success message
      Navigator.of(modalContext).pop();
      _showSnackBar(resultMessage, isError: false);

    } catch (e) {
      String errorMessage = e.toString().contains('Exception:')
          ? (e as Exception).toString().replaceFirst('Exception: ', '')
          : e.toString();

      // Close modal and show error message
      // Ensure we check if the modal context is still mounted before popping
      if (Navigator.of(modalContext).canPop()) {
        Navigator.of(modalContext).pop();
      }

      _showSnackBar(errorMessage, isError: true);

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine balance text based on loading state
    String balanceText = _currentBalance == null
        ? 'Loading...'
        : '₹${_currentBalance!.toStringAsFixed(2)}';

    bool isBalanceLoading = _currentBalance == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fund Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Button to reset the flow if needed
          if (_currentStage == TransferStage.amountEntry)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStage = TransferStage.verification;
                });
              },
              child: const Text('New Transfer', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _currentStage == TransferStage.verification ? _verificationFormKey : _transferFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Current Balance Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Available Balance', style: TextStyle(fontSize: 14, color: Colors.grey)),
                    Row(
                      children: [
                        Text(balanceText, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        if (isBalanceLoading)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- STAGE 1: VERIFICATION FORM ---
              if (_currentStage == TransferStage.verification) ...[
                const Text('Recipient Details (Verify First)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accountController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration('Recipient Account Number', Icons.account_balance_wallet),
                  validator: (value) {
                    if (value == null || value.length < 10) {
                      return 'Enter a valid account number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ifsController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 11,
                        decoration: _inputDecoration('IFS Code', Icons.code),
                        validator: (value) {
                          if (value == null || value.length != 11) {
                            return 'Enter 11-digit IFS Code.';
                          }
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
              ]

              // --- STAGE 2: AMOUNT AND PAYMENT FORM ---
              else if (_currentStage == TransferStage.amountEntry) ...[
                _buildRecipientCard(),
                const SizedBox(height: 32),

                const Text('Transaction Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: _inputDecoration('Amount to Transfer (₹)', Icons.currency_rupee),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an amount.';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Enter a valid positive amount.';
                    }
                    // Prevent submission if balance is still loading
                    if (_currentBalance == null) {
                      return 'Balance is still loading, please wait.';
                    }
                    if (amount > _currentBalance!) {
                      return 'Amount exceeds available balance: ₹${_currentBalance!.toStringAsFixed(2)}';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Narration Field
                TextFormField(
                  controller: _narrationController,
                  maxLength: 50,
                  decoration: _inputDecoration('Narration (Optional)', Icons.description),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Transfer Type Selector
                InputDecorator(
                  decoration: _inputDecoration('Transfer Type', Icons.compare_arrows).copyWith(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TransferType>(
                      value: _selectedTransferType,
                      isExpanded: true,
                      items: TransferType.values.map((TransferType type) {
                        return DropdownMenuItem<TransferType>(
                          value: type,
                          child: Text(type.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (TransferType? newValue) {
                        setState(() {
                          _selectedTransferType = newValue!;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Proceed Button
                ElevatedButton(
                  onPressed: _currentBalance == null ? null : _showConfirmationModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 5,
                  ),
                  child: Text(
                    _currentBalance == null ? 'Loading Balance...' : 'Proceed to Payment',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Common Input Decoration style
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      prefixIcon: Icon(icon, color: Colors.indigo),
      counterText: '',
    );
  }

  // Recipient details card after successful verification
  Widget _buildRecipientCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verified Recipient', style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.green),
          _buildDetailRow('Name', _recipientName, Icons.person),
          _buildDetailRow('A/C No.', _accountController.text, Icons.credit_card),
          _buildDetailRow('Bank', _bankName, Icons.account_balance),
        ],
      ),
    );
  }

  // Helper for detail rows
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.indigo),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
