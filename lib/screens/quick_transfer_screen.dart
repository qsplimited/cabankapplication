import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Assuming your banking_service.dart file is accessible via this path.
import '../api/banking_service.dart'; // Ensure this path is correct

// --- Service Initialization ---
final BankingService _bankingService = BankingService();

const Color _primaryNavyBlue = Color(0xFF003366);
const Color _successGreen = Color(0xFF4CAF50);

class QuickTransferScreen extends StatefulWidget {
  const QuickTransferScreen({super.key});

  @override
  State<QuickTransferScreen> createState() => _QuickTransferScreenState();
}

class _QuickTransferScreenState extends State<QuickTransferScreen> {
  // Form Key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _acNoController = TextEditingController();
  final TextEditingController _confirmAcNoController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // State Management
  List<Account> _debitAccounts = [];
  Account? _selectedSourceAccount;

  // CRITICAL STATE VARIABLES
  String _transactionReference = '';
  String _otpSentToMobileSuffix = '';

  bool _isTransferring = false;
  bool _isOtpRequested = false;
  bool _isRecipientVerified = false;
  Map<String, String>? _recipientDetails;

  // Flag to control form validation scope during recipient lookup
  bool _isVerifyingRecipient = false;

  // Constants
  static const int _accountNumberLength = 12;
  static const int _ifscCodeLength = 11;
  static const double _quickTransferMaxAmount = 25000.00;
  static const TransferType _transferChannel = TransferType.imps;


  @override
  void initState() {
    super.initState();
    _loadDebitAccounts();
  }

  @override
  void dispose() {
    _acNoController.dispose();
    _confirmAcNoController.dispose();
    _ifscController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loadDebitAccounts() async {
    try {
      final accounts = await _bankingService.fetchDebitAccounts();
      setState(() {
        _debitAccounts = accounts;
        if (accounts.isNotEmpty) {
          _selectedSourceAccount = accounts.first;
        }
      });
    } catch (e) {
      _showSnackBar('Failed to load accounts: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
        ),
      );
    }
  }

  /**
   * Clears all transient state related to OTP and Reference ID.
   */
  void _resetTransactionState() {
    setState(() {
      _isOtpRequested = false;
      _transactionReference = '';
      _otpController.clear();
      _otpSentToMobileSuffix = '';
    });
  }

  // --- STEP 0: Verify Recipient Account and IFSC ---
  Future<void> _verifyRecipient() async {
    if (_selectedSourceAccount == null) {
      _showSnackBar('Please select a source account.', isError: true);
      return;
    }

    setState(() => _isVerifyingRecipient = true);

    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please correct the errors in the recipient details.', isError: true);
      setState(() => _isVerifyingRecipient = false);
      return;
    }

    setState(() {
      _isTransferring = true;
      _isVerifyingRecipient = false;
    });

    try {
      final details = await _bankingService.lookupRecipient(
        recipientAccount: _acNoController.text,
        ifsCode: _ifscController.text.toUpperCase(),
      );

      setState(() {
        _recipientDetails = details;
        _isRecipientVerified = true;
      });
      _showSnackBar('Recipient Verified: ${details['officialName']!}. You may now enter the amount.', isError: false);

    } on TransferException catch (e) {
      _showSnackBar(e.message);
      setState(() {
        _isRecipientVerified = false;
        _recipientDetails = null;
        _resetTransactionState();
      });
    } catch (e) {
      _showSnackBar('Verification failed: ${e.toString().replaceAll('Exception: ', '')}');
      setState(() {
        _isRecipientVerified = false;
        _recipientDetails = null;
        _resetTransactionState();
      });
    } finally {
      setState(() => _isTransferring = false);
    }
  }


  // --- STEP 1: Request OTP ---
  Future<void> _requestOtp() async {
    if (!_isRecipientVerified) {
      _showSnackBar('Please verify recipient details first.');
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    _resetTransactionState();

    setState(() => _isTransferring = true);

    try {
      final response = await _bankingService.requestFundTransferOtp(
        recipientAccount: _acNoController.text,
        amount: double.parse(_amountController.text),
        sourceAccountNumber: _selectedSourceAccount!.accountNumber,
        transferType: _transferChannel,
      );

      final String fullMessage = response['message'] as String;
      final String ref = response['transactionReference'] as String;

      if (fullMessage.contains('******')) {
        _otpSentToMobileSuffix = fullMessage.substring(fullMessage.length - 4);
      } else {
        _otpSentToMobileSuffix = 'XXXX';
      }

      setState(() {
        _transactionReference = ref; // STORE THE NEW REFERENCE ID
        _isOtpRequested = true;
      });

      // MOCK OTP is printed here for testing
      // ignore: avoid_print
      print('DEBUG: MOCK OTP is ${response['mockOtp']}');

      _showSnackBar('OTP successfully requested. Check your phone.', isError: false);
    } on TransferException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Error initiating transfer: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => _isTransferring = false);
    }
  }

  // --- STEP 2: Submit Transfer with OTP ---
  Future<void> _submitTransfer() async {
    if (_transactionReference.isEmpty) {
      _showSnackBar('Transaction expired or not initiated. Please request OTP again.');
      return;
    }

    if (_otpController.text.length != 6) {
      _showSnackBar('Please enter the 6-digit OTP.');
      return;
    }

    setState(() => _isTransferring = true);

    try {
      final recipientName = _recipientDetails!['officialName']!;

      final transactionId = await _bankingService.submitFundTransfer(
        sourceAccountNumber: _selectedSourceAccount!.accountNumber,
        recipientAccount: _acNoController.text,
        recipientName: recipientName,
        ifsCode: _ifscController.text.toUpperCase(),
        transferType: _transferChannel,
        amount: double.parse(_amountController.text),
        narration: _remarksController.text.isEmpty ? 'Quick Transfer IMPS' : _remarksController.text,
        transactionReference: _transactionReference,
        transactionOtp: _otpController.text,
      );

      // Navigate to the full-screen success page
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => SuccessScreen(
              transactionId: transactionId,
              amount: _amountController.text,
              recipientAccount: _acNoController.text,
            ),
          ),
        );
      }

    } on TransferException catch (e) {
      _resetTransactionState();
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Transfer failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => _isTransferring = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_debitAccounts.isEmpty && !_isTransferring) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quick Transfer (IMPS)', style: TextStyle(color: Colors.white)), backgroundColor: _primaryNavyBlue),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Transfer (IMPS)'),
        backgroundColor: _primaryNavyBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // UI FIX: Added bottom padding to prevent button overlap
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.only(
              top: 16.0,
              // CRITICAL: Adds space equal to system navigation bar height
              bottom: 16.0 + MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Source Account Selection (Dropdown)
                _buildSourceAccountSelection(),
                const SizedBox(height: 20),

                // 2. Recipient Details
                Text('Recipient Details', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                _buildTextField(
                  _acNoController,
                  'Recipient Account Number',
                  Icons.account_balance,
                      (value) => value!.length != _accountNumberLength ? 'A/C No. must be $_accountNumberLength digits' : null,
                  TextInputType.number,
                  maxLength: _accountNumberLength,
                  enabled: !_isOtpRequested && !_isRecipientVerified,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),

                _buildTextField(
                  _confirmAcNoController,
                  'Confirm A/C Number',
                  Icons.check_circle_outline,
                      (value) {
                    if (value!.length != _accountNumberLength) return 'A/C No. must be $_accountNumberLength digits';
                    if (value != _acNoController.text) return 'Account numbers must match';
                    return null;
                  },
                  TextInputType.number,
                  maxLength: _accountNumberLength,
                  enabled: !_isOtpRequested && !_isRecipientVerified,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),

                _buildTextField(
                  _ifscController,
                  'IFSC Code',
                  Icons.code,
                      (value) => value!.length != _ifscCodeLength ? 'IFSC must be $_ifscCodeLength characters' : null,
                  TextInputType.text,
                  maxLength: _ifscCodeLength,
                  enabled: !_isOtpRequested && !_isRecipientVerified,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Z]'))],
                ),
                const SizedBox(height: 10),

                // 2.5 Recipient Verification Section
                if (!_isOtpRequested) ...[
                  if (_isRecipientVerified)
                    _buildRecipientVerificationStatus()
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isTransferring ? null : _verifyRecipient,
                        icon: _isTransferring ?
                        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) :
                        const Icon(Icons.verified_user_outlined),
                        label: Text(_isTransferring ? 'VERIFYING...' : 'VERIFY RECIPIENT'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                ],


                // 3. Amount and Remarks - Enabled only after verification
                Text('Transaction Details', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                _buildTextField(
                    _amountController,
                    'Amount (Max ₹${_quickTransferMaxAmount.toStringAsFixed(0)})',
                    Icons.currency_rupee,
                        (value) {
                      if (_isVerifyingRecipient) return null;

                      final amount = double.tryParse(value ?? '');
                      if (amount == null) return 'Enter a valid numeric amount.';
                      if (amount <= 0) return 'Amount must be greater than zero.';
                      if (amount > _quickTransferMaxAmount) return 'Max limit is ₹${_quickTransferMaxAmount.toStringAsFixed(0)} for Quick Transfer';

                      return null;
                    },
                    TextInputType.number,
                    enabled: !_isOtpRequested && !_isTransferring && _isRecipientVerified
                ),

                _buildTextField(
                    _remarksController,
                    'Remarks (Optional)',
                    Icons.notes,
                    null,
                    TextInputType.text,
                    isOptional: true,
                    enabled: !_isOtpRequested && !_isTransferring && _isRecipientVerified
                ),
                const SizedBox(height: 30),

                // 4. OTP Authorization Section (Conditional)
                if (_isOtpRequested) ...[
                  Text('Authorization (6-digit OTP)', style: Theme.of(context).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('OTP sent to mobile ending in ******$_otpSentToMobileSuffix', style: const TextStyle(color: Colors.green)),
                  ),
                  _buildTextField(
                    _otpController,
                    'Enter 6-digit OTP',
                    Icons.lock_outline,
                        (value) => value!.length != 6 ? 'OTP must be 6 digits' : null,
                    TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 20),

                  // Submit Button (Step 2)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTransferring ? null : _submitTransfer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isTransferring
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('AUTHORIZE & TRANSFER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),

                ] else if (_isRecipientVerified) ...[
                  // Request OTP Button (Step 1) - Only available after verification
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTransferring ? null : _requestOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryNavyBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isTransferring
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('PROCEED & REQUEST OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSourceAccountSelection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: _primaryNavyBlue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DYNAMIC TITLE FIX: Display the selected account nickname
            Text(
              'Transfer From: ${_selectedSourceAccount?.nickname ?? 'Select Source Account'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryNavyBlue),
            ),
            const Divider(),
            if (_debitAccounts.isEmpty)
              const Text('Loading accounts or no debitable accounts found...')
            else
              DropdownButtonFormField<Account>(
                value: _selectedSourceAccount,
                decoration: const InputDecoration(
                  labelText: 'Select Source Account',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                ),
                isExpanded: true,
                items: _debitAccounts.map((Account account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Text(
                      '${account.nickname} (${_bankingService.maskAccountNumber(account.accountNumber)}) - ₹${account.balance.toStringAsFixed(2)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: _isOtpRequested ? null : (Account? newAccount) {
                  setState(() {
                    _selectedSourceAccount = newAccount;
                    _isRecipientVerified = false;
                    _recipientDetails = null;
                    _resetTransactionState(); // Reset state when source account changes
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientVerificationStatus() {
    if (_isRecipientVerified && _recipientDetails != null) {
      return Card(
        color: Colors.lightGreen.shade50,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: Colors.green, width: 1)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Recipient Verified ✅', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 5),
              Text('Name: ${_recipientDetails!['officialName']}', style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('Bank: ${_recipientDetails!['bankName']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }


  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      String? Function(String?)? validator,
      TextInputType keyboardType, {
        bool isOptional = false,
        int? maxLength,
        bool enabled = true,
        TextCapitalization textCapitalization = TextCapitalization.none,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        enabled: enabled,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        onChanged: (_) {
          if (mounted) {
            if (controller == _acNoController || controller == _confirmAcNoController || controller == _ifscController) {
              setState(() {
                _isRecipientVerified = false;
                _recipientDetails = null;
              });
              _resetTransactionState();
            }
            if (controller == _amountController && _isOtpRequested) {
              _resetTransactionState();
            }
          }
        },
        decoration: InputDecoration(
          labelText: isOptional ? '$label (Optional)' : label,
          prefixIcon: Icon(icon, color: _primaryNavyBlue.withOpacity(0.7)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          counterText: "",
          filled: !enabled,
          fillColor: Colors.grey.shade100,
        ),
        validator: (value) {
          if (!isOptional && (value == null || value.isEmpty)) {
            if (controller == _amountController && _isVerifyingRecipient) {
              return null;
            }
            return '$label is required.';
          }
          if (validator != null) {
            return validator(value);
          }
          return null;
        },
      ),
    );
  }
}

// Extension to safely parse string to double
extension on String {
  double? tryParseDouble() {
    return double.tryParse(this);
  }
}

// --- NEW SUCCESS SCREEN FOR RESPONSIVENESS ---

class SuccessScreen extends StatelessWidget {
  final String transactionId;
  final String amount;
  final String recipientAccount;

  const SuccessScreen({
    super.key,
    required this.transactionId,
    required this.amount,
    required this.recipientAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Complete'),
        backgroundColor: _successGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Prevents back button on success
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Ensures content is scrollable if device is small
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Success Icon
                      const Icon(
                        Icons.check_circle_outline,
                        color: _successGreen,
                        size: 96.0,
                      ),
                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Transfer Successful!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _successGreen,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Transaction Details Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Amount:', '₹$amount'),
                              _buildDetailRow('To A/C:', _bankingService.maskAccountNumber(recipientAccount)),
                              _buildDetailRow('Reference ID:', transactionId),
                              _buildDetailRow('Time:', _formatDateTime(DateTime.now())),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(), // Pushes the button to the bottom

                      // Done Button
                      Padding(
                        padding: EdgeInsets.only(top: 30.0, bottom: MediaQuery.of(context).padding.bottom),
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate back to the home screen (or previous context)
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryNavyBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('DONE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // Basic formatting for presentation
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}