import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// IMPORTANT: This import path assumes your models and service are located here.
// Adjust this path if 'banking_service.dart' is in a different location.
import '../api/banking_service.dart';

// --- WIDGETS AND STYLING UTILS ---

const Color kPrimaryColor = Color(0xFF003366); // Navy Blue
const Color kSecondaryColor = Color(0xFFF0F0F0); // Light background for inputs
const Color kAccentColor = Color(0xFF003366); // Accent and Button color is same as Primary
const TextStyle kTitleStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: kPrimaryColor);
const TextStyle kLabelStyle = TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black54);
const TextStyle kBodyStyle = TextStyle(fontSize: 16);
const TextStyle kAccountDetailStyle = TextStyle(fontSize: 14, color: Colors.black87);
const TextStyle kBodyStyleAccent = TextStyle(fontSize: 16, color: kPrimaryColor);

// --------------------------------------------------------------------------

/// Custom widget to handle the 6-digit T-PIN input fields with only an underline.
class OtpInputFields extends StatefulWidget {
  final ValueChanged<String> onOtpChanged;
  final int pinLength; // Renamed to pinLength for generic input fields

  const OtpInputFields({
    super.key,
    required this.onOtpChanged,
    this.pinLength = 6,
  });

  @override
  State<OtpInputFields> createState() => _OtpInputFieldsState();
}

class _OtpInputFieldsState extends State<OtpInputFields> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _currentOtp = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.pinLength, (index) => TextEditingController());
    _focusNodes = List.generate(widget.pinLength, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Updates the full OTP string and notifies the parent widget.
  void _updateOtp() {
    // Join the text from all controllers
    final newOtp = _controllers.map((c) => c.text.isNotEmpty ? c.text : '').join('');

    if (_currentOtp != newOtp) {
      _currentOtp = newOtp;
      widget.onOtpChanged(_currentOtp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.pinLength, (index) {
        return SizedBox(
          width: 40, // Fixed width for each field
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            obscureText: false, // OTP is usually visible or obscured with * or •, but let's keep it numeric for clarity
            maxLength: 1,
            textAlign: TextAlign.center,
            style: kTitleStyle.copyWith(fontSize: 24, color: kPrimaryColor),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            // --- FOCUS AND PIN LOGIC IMPLEMENTED HERE ---
            onChanged: (value) {
              // 1. Auto-advance to the next field
              if (value.length == 1 && index < widget.pinLength - 1) {
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              }

              // 2. Auto-move back to the previous field on delete (backspace)
              else if (value.isEmpty && index > 0) {
                // Using a slight delay prevents potential focus conflicts
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mounted) {
                    FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                  }
                });
              }

              // 3. Update the aggregated PIN value for the parent widget
              _updateOtp();
            },

            // --- DECORATION FOR UNDERLINE ONLY (no box) ---
            decoration: InputDecoration(
              counterText: "",
              hintText: '•',
              hintStyle: kTitleStyle.copyWith(fontSize: 24, color: Colors.grey.shade300),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: kPrimaryColor, width: 3),
              ),
              errorBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
            ),
          ),
        );
      }),
    );
  }
}

// --------------------------------------------------------------------------

/// Dedicated widget for the POP-UP confirmation dialog (AlertDialog).
class TransferVerificationDialog extends StatefulWidget {
  final double amount;
  final Account sourceAccount;
  final Account destinationAccount;
  final String transactionReference; // NEW: Reference ID from initiate call
  final String message; // NEW: OTP message
  final Function(double amount, String otp, String ref) onConfirm;

  const TransferVerificationDialog({
    super.key,
    required this.amount,
    required this.sourceAccount,
    required this.destinationAccount,
    required this.transactionReference,
    required this.message,
    required this.onConfirm,
  });

  @override
  State<TransferVerificationDialog> createState() => _TransferVerificationDialogState();
}

class _TransferVerificationDialogState extends State<TransferVerificationDialog> {
  String _otp = ''; // Changed from _tpin to _otp

  // Helper widget to display a single confirmation detail line
  Widget _buildDetailRow({required String label, required String value, bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label on the left
          Expanded(
            flex: 2,
            child: Text(label, style: kBodyStyle.copyWith(color: Colors.black54)),
          ),

          // Value on the right
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: isAmount
                  ? kTitleStyle.copyWith(fontSize: 18, color: kPrimaryColor)
                  : kBodyStyle.copyWith(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 14),
              overflow: TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceFull = widget.sourceAccount.accountNumber;
    final destFull = widget.destinationAccount.accountNumber;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Text(
        'Verify Transfer with OTP',
        textAlign: TextAlign.center,
        style: kTitleStyle.copyWith(fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- TRANSFER DETAILS ---
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 16),

            // Transfer Amount (Highlighted)
            _buildDetailRow(
              label: 'Transfer Amount',
              value: '₹${widget.amount.toStringAsFixed(2)}',
              isAmount: true,
            ),
            const Divider(height: 1, color: Colors.grey),

            // From Account (Full Number Display)
            _buildDetailRow(
              label: 'From',
              value: '${widget.sourceAccount.nickname} (${sourceFull})',
            ),

            // To Account (Full Number Display)
            _buildDetailRow(
              label: 'To',
              value: '${widget.destinationAccount.nickname} (${destFull})',
            ),

            const SizedBox(height: 24),

            // --- OTP INPUT SECTION ---
            Text(
                widget.message, // Display the masked mobile number message
                style: kBodyStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 15)
            ),
            const SizedBox(height: 16),

            // Underline Pin Input (Now for OTP)
            OtpInputFields(
              onOtpChanged: (otp) {
                setState(() {
                  _otp = otp;
                });
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      // --- ACTION BUTTONS ---
      actionsPadding: const EdgeInsets.all(16),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: kBodyStyle.copyWith(color: Colors.red.shade700, fontWeight: FontWeight.bold),
              ),
            ),

            // Confirm & Pay Button
            ElevatedButton(
              onPressed: _otp.length == 6
                  ? () => widget.onConfirm(widget.amount, _otp, widget.transactionReference)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                disabledBackgroundColor: kPrimaryColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
              ),
              child: Text(
                'Verify & Pay',
                style: kTitleStyle.copyWith(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// --------------------------------------------------------------------------

class OwnAccountTransferScreen extends StatefulWidget {
  const OwnAccountTransferScreen({
    super.key, required BankingService bankingService, required Account sourceAccount, required List<Account> userAccounts,
  });

  @override
  State<OwnAccountTransferScreen> createState() => _OwnAccountTransferScreenState();
}

class _OwnAccountTransferScreenState extends State<OwnAccountTransferScreen> {
  final BankingService _bankingService = BankingService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();

  List<Account> _sourceAccounts = [];
  List<Account> _destinationAccounts = [];
  Account? _selectedSource;
  Account? _selectedDestination;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isTransferring = false; // Flag for overall transfer process

  // State specific to the OTP flow
  String? _currentReferenceId;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _amountController.addListener(_updateUI);
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateUI);
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  void _updateUI() => setState(() {});

  // --- DATA FETCHING & FILTERING ---

  Future<void> _fetchAccounts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final debitAccounts = await _bankingService.fetchDebitAccounts();
      setState(() {
        _sourceAccounts = debitAccounts;
        _selectedSource = _sourceAccounts.isNotEmpty ? _sourceAccounts.first : null;
        _filterDestinationAccounts();
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'Failed to load accounts: ${e.toString().replaceAll('Exception: ', '')}';
        _isLoading = false;
      });
    }
  }

  void _filterDestinationAccounts() {
    if (_selectedSource != null) {
      final destinations = _bankingService.filterDestinationAccounts(_selectedSource!.accountNumber);
      setState(() {
        _destinationAccounts = destinations;

        if (_selectedDestination != null && !_destinationAccounts.any((a) => a.accountNumber == _selectedDestination!.accountNumber)) {
          // If the previously selected destination account is now the source, select a new one
          _selectedDestination = _destinationAccounts.isNotEmpty ? _destinationAccounts.first : null;
        } else if (_selectedDestination == null && _destinationAccounts.isNotEmpty) {
          _selectedDestination = _destinationAccounts.first;
        } else if (_destinationAccounts.isEmpty) {
          _selectedDestination = null;
        }

      });
    } else {
      setState(() {
        _destinationAccounts = [];
        _selectedDestination = null;
      });
    }
  }

  // --- TRANSFER EXECUTION (Two-Step OTP Flow) ---

  void _handleInitiateTransfer() {
    if (_isTransferring) return;

    if (_selectedSource == null || _selectedDestination == null || _amountController.text.isEmpty) {
      setState(() => _errorMessage = 'Please select both accounts and enter a valid amount.');
      return;
    }

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Amount must be greater than ₹0.');
      return;
    }

    // Since this is an internal transfer (no fees/limits check is complex), we use a simplified check
    if (amount > (_selectedSource?.balance ?? 0.0)) {
      setState(() => _errorMessage = 'Insufficient funds. Available: ₹${(_selectedSource?.balance ?? 0.0).toStringAsFixed(2)}');
      return;
    }

    _initiateTransfer(amount);
  }

  /// Step 1: Calls API to check balance/limits and get OTP/Reference ID
  Future<void> _initiateTransfer(double amount) async {
    setState(() {
      _isTransferring = true;
      _errorMessage = null;
      _currentReferenceId = null;
    });

    try {
      // NOTE: Even for internal transfers, the mock API requires a call to requestFundTransferOtp
      final response = await _bankingService.requestFundTransferOtp(
        recipientAccount: _selectedDestination!.accountNumber,
        amount: amount,
        sourceAccountNumber: _selectedSource!.accountNumber,
        transferType: TransferType.internal, // This will skip fees/limits in internal logic
      );

      if (!mounted) return;
      setState(() {
        _currentReferenceId = response['transactionReference'] as String;
        _isTransferring = false; // Allow the user to proceed to the OTP dialog
      });

      // Show the verification dialog immediately after receiving the reference
      _showVerificationDialog(amount, response['message'] as String);

    } on TransferException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isTransferring = false;
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred during initiation: ${e.toString()}';
        _isTransferring = false;
      });
    }
  }

  void _showVerificationDialog(double amount, String otpMessage) {
    // Ensure we have the necessary data before showing the dialog
    if (_currentReferenceId == null) {
      setState(() => _errorMessage = 'Failed to get transaction reference.');
      return;
    }

    final sourceAccountDisplay = _selectedSource!;
    final destAccountDisplay = _selectedDestination!;

    showDialog(
      context: context,
      barrierDismissible: false, // Force user to use buttons
      builder: (BuildContext context) {
        return TransferVerificationDialog(
          amount: amount,
          sourceAccount: sourceAccountDisplay,
          destinationAccount: destAccountDisplay,
          transactionReference: _currentReferenceId!,
          message: otpMessage,
          onConfirm: (amount, otp, ref) {
            Navigator.of(context).pop(); // Close the OTP dialog
            _verifyAndExecuteTransfer(amount, otp, ref);
          },
        );
      },
    );
  }

  /// Step 2: Calls API to verify OTP and execute the transfer
  Future<void> _verifyAndExecuteTransfer(double amount, String otp, String ref) async {
    setState(() {
      _isTransferring = true; // Set flag for final processing stage
      _errorMessage = null;
    });

    try {
      final String resultMessage = await _bankingService.submitFundTransfer(
        recipientAccount: _selectedDestination!.accountNumber,
        recipientName: _selectedDestination!.nickname,
        transferType: TransferType.internal,
        amount: amount,
        narration: _narrationController.text.isEmpty ? 'Own Account Transfer' : _narrationController.text,
        transactionReference: ref, // NEW: Pass Reference ID
        transactionOtp: otp, // NEW: Pass OTP
        sourceAccountNumber: _selectedSource!.accountNumber,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Transfer Successful! 🎉', style: kTitleStyle.copyWith(fontSize: 18)),
          content: Text(resultMessage, style: kBodyStyle),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst); // Navigate back to the main dashboard
                _resetForm(); // Reset form state
              },
              child: const Text('Done', style: TextStyle(color: kPrimaryColor)),
            ),
          ],
        ),
      );
    } on TransferException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isTransferring = false;
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred during verification: ${e.toString()}';
        _isTransferring = false;
      });
    }
  }

  void _resetForm() {
    _amountController.clear();
    _narrationController.clear();
    setState(() {
      _isTransferring = false;
      _errorMessage = null;
      _currentReferenceId = null;
    });
    // Re-fetch accounts to update balances
    _fetchAccounts();
  }

  // --- UI BUILDER METHODS ---

  Widget _buildAccountDropdown<T>({
    required String label,
    required T? selectedValue,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemToString,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: kLabelStyle),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: kSecondaryColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade400, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: selectedValue,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: kPrimaryColor),
              style: kAccountDetailStyle.copyWith(color: kPrimaryColor, fontWeight: FontWeight.w600),
              hint: Text('Select $label', style: kAccountDetailStyle),
              onChanged: items.isNotEmpty ? onChanged : null,
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(itemToString(item), overflow: TextOverflow.ellipsis),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _accountToDisplayString(Account account) {
    // Dynamically generating type label from enum name
    String typeLabel = account.accountType.name.splitMapJoin(
      RegExp(r'[A-Z]'),
      onMatch: (m) => ' ${m.group(0)}',
      onNonMatch: (n) => n,
    ).trim();
    typeLabel = typeLabel.substring(0, 1).toUpperCase() + typeLabel.substring(1);

    // Using maskAccountNumber for the main screen dropdown display
    final maskedNumber = _bankingService.maskAccountNumber(account.accountNumber);
    final balance = '₹${account.balance.toStringAsFixed(2)}';

    return '${account.nickname} ($typeLabel - $maskedNumber) | Bal: $balance';
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = _selectedSource != null &&
        _selectedDestination != null &&
        _amountController.text.isNotEmpty &&
        (double.tryParse(_amountController.text) ?? 0.0) > 0;

    // Determine the loading message
    String loadingMessage = 'Loading Accounts...';
    if (_isTransferring) {
      if (_currentReferenceId == null) {
        loadingMessage = 'Initiating Transfer & Requesting OTP...';
      } else {
        loadingMessage = 'Processing Transfer...';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Own Account Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading || (_isTransferring && _currentReferenceId == null)
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: kPrimaryColor),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(loadingMessage, style: kBodyStyleAccent),
            )
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FROM ACCOUNT SELECTION ---
            _buildAccountDropdown<Account>(
              label: 'From Account (Source)',
              selectedValue: _selectedSource,
              items: _sourceAccounts,
              onChanged: (Account? newValue) {
                setState(() {
                  _selectedSource = newValue;
                  _filterDestinationAccounts();
                });
              },
              itemToString: _accountToDisplayString,
            ),
            const SizedBox(height: 20),

            // --- TO ACCOUNT SELECTION ---
            _buildAccountDropdown<Account>(
              label: 'To Account (Destination)',
              selectedValue: _selectedDestination,
              items: _destinationAccounts,
              onChanged: (Account? newValue) {
                setState(() => _selectedDestination = newValue);
              },
              itemToString: _accountToDisplayString,
            ),
            const SizedBox(height: 30),

            // --- AMOUNT INPUT ---
            Text('Amount (₹)', style: kLabelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: kBodyStyle.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Minimum ₹1.00',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),

            if (_selectedSource != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Available Balance: ₹${_selectedSource!.balance.toStringAsFixed(2)}',
                  style: kLabelStyle.copyWith(color: Colors.green.shade700, fontStyle: FontStyle.italic),
                ),
              ),

            const SizedBox(height: 20),

            // --- NARRATION (OPTIONAL) ---
            Text('Narration (Optional)', style: kLabelStyle),
            const SizedBox(height: 8),
            TextField(
              controller: _narrationController,
              style: kBodyStyle,
              decoration: InputDecoration(
                hintText: 'e.g., Savings to FD Top-up',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 30),

            // --- ERROR MESSAGE ---
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
              ),

            // --- SUBMIT BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Calls the initiation step
                onPressed: isFormValid && !_isTransferring ? _handleInitiateTransfer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  disabledBackgroundColor: kAccentColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: Text(
                  'Initiate Transfer (Fee: ₹0.00)',
                  style: kTitleStyle.copyWith(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}