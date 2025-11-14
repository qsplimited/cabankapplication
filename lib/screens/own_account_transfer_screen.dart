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
class PinInputFields extends StatefulWidget {
  final ValueChanged<String> onPinChanged;
  final int pinLength;

  const PinInputFields({
    super.key,
    required this.onPinChanged,
    this.pinLength = 6,
  });

  @override
  State<PinInputFields> createState() => _PinInputFieldsState();
}

class _PinInputFieldsState extends State<PinInputFields> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _currentPin = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.pinLength, (index) => TextEditingController());
    _focusNodes = List.generate(widget.pinLength, (index) => FocusNode());

    // NOTE: Removed addListener loop from here. Focus logic is now in onChanged.
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

  /// Updates the full PIN string and notifies the parent widget.
  void _updatePin() {
    // Join the text from all controllers
    final newPin = _controllers.map((c) => c.text.isNotEmpty ? c.text : '').join('');

    if (_currentPin != newPin) {
      _currentPin = newPin;
      widget.onPinChanged(_currentPin);
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
            obscureText: true,
            obscuringCharacter: '•',
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
              _updatePin();
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
class TransferConfirmationDialog extends StatefulWidget {
  final double amount;
  final Account sourceAccount;
  final Account destinationAccount;
  final Function(double amount, String tpin) onConfirm;

  const TransferConfirmationDialog({
    super.key,
    required this.amount,
    required this.sourceAccount,
    required this.destinationAccount,
    required this.onConfirm,
  });

  @override
  State<TransferConfirmationDialog> createState() => _TransferConfirmationDialogState();
}

class _TransferConfirmationDialogState extends State<TransferConfirmationDialog> {
  String _tpin = '';
  // Removed _bankingService since it's only used for masking which is now removed.

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
    // --- NO MASKING - DISPLAY FULL ACCOUNT NUMBER ---
    final sourceFull = widget.sourceAccount.accountNumber;
    final destFull = widget.destinationAccount.accountNumber;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      title: Text(
        'Confirm Transfer Details',
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

            // --- PIN INPUT SECTION ---
            Text(
                'Enter 6-Digit Transaction PIN to Authorize',
                style: kBodyStyle.copyWith(fontWeight: FontWeight.w600, fontSize: 15)
            ),
            const SizedBox(height: 16),

            // Underline Pin Input (Now with working auto-advance)
            PinInputFields(
              onPinChanged: (pin) {
                setState(() {
                  _tpin = pin;
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
              onPressed: _tpin.length == 6
                  ? () => widget.onConfirm(widget.amount, _tpin)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                disabledBackgroundColor: kPrimaryColor.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 3,
              ),
              child: Text(
                'Confirm & Pay',
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
  // NOTE: I've removed the required fields from the constructor because
  // the state class fetches its own data using the service instance.
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
  bool _isTransferring = false;

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
      // Assuming filterDestinationAccounts only needs the account number string
      final destinations = _bankingService.filterDestinationAccounts(_selectedSource!.accountNumber);
      setState(() {
        _destinationAccounts = destinations;

        if (_selectedDestination != null && !_destinationAccounts.any((a) => a.accountNumber == _selectedDestination!.accountNumber)) {
          _selectedDestination = _destinationAccounts.first;
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

  // --- TRANSFER EXECUTION ---

  void _showConfirmationDialog() {
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
    if (amount > (_selectedSource?.balance ?? 0.0)) {
      setState(() => _errorMessage = 'Insufficient funds. Available: ₹${(_selectedSource?.balance ?? 0.0).toStringAsFixed(2)}');
      return;
    }

    final sourceAccountDisplay = _selectedSource!;
    final destAccountDisplay = _selectedDestination!;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TransferConfirmationDialog(
          amount: amount,
          sourceAccount: sourceAccountDisplay,
          destinationAccount: destAccountDisplay,
          onConfirm: (amount, tpin) {
            Navigator.of(context).pop();
            _performTransfer(amount, tpin);
          },
        );
      },
    );
  }

  Future<void> _performTransfer(double amount, String tpin) async {
    setState(() {
      _isTransferring = true;
      _errorMessage = null;
    });

    try {
      final String resultMessage = await _bankingService.submitFundTransfer(
        recipientAccount: _selectedDestination!.accountNumber,
        recipientName: _selectedDestination!.nickname,
        transferType: TransferType.internal, // Assuming internal for own account transfer
        amount: amount,
        narration: _narrationController.text.isEmpty ? 'Internal Transfer' : _narrationController.text,
        transactionPin: tpin,
        sourceAccountNumber: _selectedSource!.accountNumber,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Transfer Successful!', style: kTitleStyle.copyWith(fontSize: 18)),
          content: Text(resultMessage, style: kBodyStyle),
          actions: [
            TextButton(
              onPressed: () {
                // 1. Close the success dialog
                Navigator.of(context).pop();

                // 2. Reset the form state (clear inputs, refresh balance)
                _resetForm();

                // 3. Navigate back to the dashboard/previous screen
                Navigator.of(context).pop();
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
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Own Account Transfer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading || _isTransferring
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: kPrimaryColor),
            if (_isTransferring)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text('Processing Transfer...', style: kBodyStyleAccent),
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
                onPressed: isFormValid ? _showConfirmationDialog : null, // Changed to showDialog
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentColor,
                  disabledBackgroundColor: kAccentColor.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                child: Text(
                  'Confirm Transfer (Fee: ₹0.00)',
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