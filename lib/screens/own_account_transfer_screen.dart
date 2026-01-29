import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// IMPORTANT: This import path assumes your models and service are located here.
// Adjust this path if 'banking_service.dart' is in a different location.
import '../api/banking_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

import 'transfer_success_screen.dart';

// Removed hardcoded color/style constants and will use Theme.of(context) instead.
// const Color kPrimaryColor = Color(0xFF003366);
// const Color kSecondaryColor = Color(0xFFF0F0F0);
// ... etc.

// --------------------------------------------------------------------------

/// Custom widget to handle the 6-digit T-PIN input fields with only an underline.
class OtpInputFields extends StatefulWidget {
  final ValueChanged<String> onOtpChanged;
  final int pinLength;

  const OtpInputFields({super.key, required this.onOtpChanged, this.pinLength = 6});

  @override
  State<OtpInputFields> createState() => _OtpInputFieldsState();
}

class _OtpInputFieldsState extends State<OtpInputFields> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.pinLength, (index) => TextEditingController());
    _focusNodes = List.generate(widget.pinLength, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.pinLength, (index) {
        return SizedBox(
          width: 38, // Reduced size to prevent overflow
          height: 45,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: "",
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < widget.pinLength - 1) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              // Collect all values and send to parent
              String currentOtp = _controllers.map((c) => c.text).join();
              widget.onOtpChanged(currentOtp);
            },
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
  final String transactionReference;
  final String message;
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
  String _currentOtp = '';

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible( // Prevents text overflow
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Confirm Transaction", textAlign: TextAlign.center),
      content: SizedBox( // Explicit width fixes RenderFlex/Constraint issues
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _detailRow("Amount", "₹${widget.amount.toStringAsFixed(2)}", isBold: true),
                    const Divider(),
                    _detailRow("From", widget.sourceAccount.nickname),
                    _detailRow("To", widget.destinationAccount.nickname),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(widget.message, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              OtpInputFields(
                onOtpChanged: (otp) => setState(() => _currentOtp = otp),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _currentOtp.length == 6
              ? () => widget.onConfirm(widget.amount, _currentOtp, widget.transactionReference)
              : null,
          child: const Text("Confirm Payment"),
        ),
      ],
    );
  }
}// --------------------------------------------------------------------------

class OwnAccountTransferScreen extends StatefulWidget {
  final BankingService bankingService;
  final Account sourceAccount;
  final List<Account> userAccounts;

  const OwnAccountTransferScreen({
    super.key,
    required this.bankingService,
    required this.sourceAccount,
    required this.userAccounts, // Added userAccounts for better context/setup
  });

  @override
  State<OwnAccountTransferScreen> createState() => _OwnAccountTransferScreenState();
}

class _OwnAccountTransferScreenState extends State<OwnAccountTransferScreen> {
  // Use the passed-in service
  late final BankingService _bankingService = widget.bankingService;

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
    // Assuming widget.userAccounts contains all accounts and we need to fetch the debit subset later if necessary
    _sourceAccounts = widget.userAccounts; // Start with all accounts
    _selectedSource = widget.userAccounts.isNotEmpty ? widget.userAccounts.first : null;

    if (_selectedSource != null) {
      _filterDestinationAccounts();
      _isLoading = false;
    } else {
      // If no accounts are passed, attempt a full fetch (fallback logic)
      _fetchAccounts();
    }

    _amountController.addListener(_updateUI);
  }

  // Fallback data fetch if accounts weren't passed via constructor
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

  @override
  void dispose() {
    _amountController.removeListener(_updateUI);
    _amountController.dispose();
    _narrationController.dispose();
    super.dispose();
  }

  void _updateUI() => setState(() {});

  // --- DATA FILTERING ---

  void _filterDestinationAccounts() {
    if (_selectedSource != null) {
      // Filter the initial list of accounts to exclude the source account
      final destinations = _sourceAccounts.where((a) => a.accountNumber != _selectedSource!.accountNumber).toList();
      setState(() {
        _destinationAccounts = destinations;

        // Reset destination if the current one is no longer valid or if it's null
        if (_selectedDestination == null ||
            _selectedDestination!.accountNumber == _selectedSource!.accountNumber ||
            !_destinationAccounts.any((a) => a.accountNumber == _selectedDestination!.accountNumber)) {

          _selectedDestination = _destinationAccounts.isNotEmpty ? _destinationAccounts.first : null;
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

// 1. The Initiate Button Handler
  void _handleInitiateTransfer() async {
    // 1. Basic UI Check
    if (_selectedSource == null || _selectedDestination == null) {
      setState(() => _errorMessage = "Please select source and destination accounts.");
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      setState(() => _errorMessage = "Enter a valid transfer amount.");
      return;
    }

    // 2. Start Loading State
    setState(() {
      _isTransferring = true;
      _errorMessage = null;
    });

    try {
      // 3. Request OTP from Service
      final result = await _bankingService.requestFundTransferOtp(
        recipientAccount: _selectedDestination!.accountNumber,
        amount: amount,
        sourceAccountNumber: _selectedSource!.accountNumber,
        transferType: TransferType.internal,
      );

      // 4. Trigger Dialog with Reference ID
      if (mounted) {
        _showVerificationDialog(
            amount,
            result['message'] ?? "Verify Transaction",
            result['transactionReference'] as String
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      // 5. Always stop the loading spinner
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  void _showVerificationDialog(double amount, String message, String referenceId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String localOtp = "";
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Confirm OTP"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Small transaction summary
                      Text("Paying: ₹$amount", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),

                      // Compact OTP boxes
                      OtpInputFields(
                        onOtpChanged: (otp) => setDialogState(() => localOtp = otp),
                      ),

                      const SizedBox(height: 30),

                      // THE VERIFY BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: localOtp.length == 6
                              ? () {
                            Navigator.pop(ctx);
                            _executeFinalTransfer(amount, localOtp, referenceId);
                          }
                              : null,
                          child: const Text("VERIFY & PAY"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

// Helper row for details
  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }

// 3. The Execution Handler
// inside own_account_transfer_screen.dart
  Future<void> _executeFinalTransfer(double amount, String otp, String ref) async {
    setState(() => _isTransferring = true);
    try {
      await _bankingService.submitFundTransfer(
        recipientAccount: _selectedDestination!.accountNumber,
        recipientName: _selectedDestination!.nickname,
        transferType: TransferType.internal,
        amount: amount,
        transactionReference: ref,
        transactionOtp: otp,
        sourceAccountNumber: _selectedSource!.accountNumber,
      );

      if (mounted) {
        // INSTEAD OF DIALOG, WE NAVIGATE
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransferSuccessScreen(
              transactionId: ref,
              amount: amount,
              fromAccount: _selectedSource!.nickname,
              toAccount: _selectedDestination!.nickname,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  Future<void> _initiateTransfer(double amount) async {
    setState(() {
      _isTransferring = true;
      _errorMessage = null;
      _currentReferenceId = null;
    });

    try {
      final response = await _bankingService.requestFundTransferOtp(
        recipientAccount: _selectedDestination!.accountNumber,
        amount: amount,
        sourceAccountNumber: _selectedSource!.accountNumber,
        transferType: TransferType.internal,
      );

      if (!mounted) return;

      final refId = response['transactionReference'] as String;
      final msg = response['message'] as String;

      setState(() {
        _currentReferenceId = refId;
        _isTransferring = false;
      });

      // FIX: Pass all 3 required arguments here
      _showVerificationDialog(amount, msg, refId);

    } on TransferException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isTransferring = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred: ${e.toString()}';
        _isTransferring = false;
      });
    }
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
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          final textTheme = Theme.of(context).textTheme;

          return AlertDialog(
            title: Text(
              'Transfer Successful! 🎉',
              style: textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kSuccessGreen // Use success green for the title
              ),
            ),
            content: Text(resultMessage, style: textTheme.bodyMedium),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst); // Navigate back to the main dashboard
                  _resetForm(); // Reset form state
                },
                child: Text(
                  'Done',
                  style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                ),
              ),
            ],
          );
        },
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
      // Note: No need to call _fetchAccounts if we assume userAccounts is reliable
      // If data is stale, uncomment _fetchAccounts() here
    });
  }

  // --- UI BUILDER METHODS ---

  Widget _buildAccountDropdown<T>({
    required String label,
    required T? selectedValue,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemToString,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Refactored hardcoded style
        Text(label, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        // Refactored hardcoded 8 to kPaddingSmall
        const SizedBox(height: kPaddingSmall),
        Container(
          // Refactored hardcoded padding
          padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kPaddingExtraSmall),
          decoration: BoxDecoration(
            // Use kInputBackgroundColor or surface depending on preference
            color: kInputBackgroundColor,
            borderRadius: BorderRadius.circular(kRadiusMedium),
            // Refactored hardcoded border
            border: Border.all(color: kInputBorderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
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
              // Refactored hardcoded icon color
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
              // Refactored hardcoded style
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
              hint: Text('Select $label', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.5))),
              onChanged: items.isNotEmpty ? onChanged : null,
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  // Refactored hardcoded padding
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: kPaddingSmall),
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
        title: Text(
          'Own Account Transfer',
          // Refactored hardcoded style
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
        ),
        // Refactored hardcoded colors
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: _isLoading || (_isTransferring && _currentReferenceId == null)
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Refactored hardcoded color
            CircularProgressIndicator(color: colorScheme.primary),
            Padding(
              // Refactored hardcoded padding
              padding: const EdgeInsets.only(top: kPaddingMedium),
              child: Text(
                loadingMessage,
                // Refactored hardcoded style
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w500),
              ),
            )
          ],
        ),
      )
          : SingleChildScrollView(
        // Refactored hardcoded 20 to kIconSizeSmall
        padding: const EdgeInsets.all(kIconSizeSmall),
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
            // Refactored hardcoded 20 to kIconSizeSmall
            const SizedBox(height: kIconSizeSmall),

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
            // Refactored hardcoded 30 to kPaddingExtraLarge - 2.0
            const SizedBox(height: kPaddingExtraLarge - 2.0),

            // --- AMOUNT INPUT ---
            Text('Amount (₹)', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            // Refactored hardcoded 8 to kPaddingSmall
            const SizedBox(height: kPaddingSmall),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              // Refactored hardcoded style
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: 'Minimum ₹1.00',
                prefixText: '₹ ',
                // Refactored hardcoded radius
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(kPaddingTen)),
                // Refactored hardcoded border
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kPaddingTen), borderSide: const BorderSide(color: kInputBorderColor, width: 1.5)),
                // Refactored hardcoded border
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kPaddingTen), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                // Refactored hardcoded padding
                contentPadding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kRadiusMedium),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),

            if (_selectedSource != null)
              Padding(
                // Refactored hardcoded 8.0 to kPaddingSmall
                padding: const EdgeInsets.only(top: kPaddingSmall),
                child: Text(
                  'Available Balance: ₹${_selectedSource!.balance.toStringAsFixed(2)}',
                  // Refactored hardcoded style
                  style: textTheme.bodySmall?.copyWith(color: kSuccessGreen, fontStyle: FontStyle.italic, fontWeight: FontWeight.w500),
                ),
              ),

            // Refactored hardcoded 20 to kIconSizeSmall
            const SizedBox(height: kIconSizeSmall),

            // --- NARRATION (OPTIONAL) ---
            Text('Narration (Optional)', style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            // Refactored hardcoded 8 to kPaddingSmall
            const SizedBox(height: kPaddingSmall),
            TextField(
              controller: _narrationController,
              style: textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'e.g., Savings to FD Top-up',
                // Refactored hardcoded radius
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(kPaddingTen)),
                // Refactored hardcoded border
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kPaddingTen), borderSide: const BorderSide(color: kInputBorderColor, width: 1.5)),
                // Refactored hardcoded border
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(kPaddingTen), borderSide: BorderSide(color: colorScheme.primary, width: 2)),
                // Refactored hardcoded padding
                contentPadding: const EdgeInsets.symmetric(horizontal: kPaddingMedium, vertical: kRadiusMedium),
              ),
            ),
            // Refactored hardcoded 30 to kPaddingExtraLarge - 2.0
            const SizedBox(height: kPaddingExtraLarge - 2.0),

            // --- ERROR MESSAGE ---
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                // Refactored hardcoded padding/margin
                padding: const EdgeInsets.all(kRadiusMedium),
                margin: const EdgeInsets.only(bottom: kIconSizeSmall),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(kRadiusSmall),
                  border: Border.all(color: colorScheme.error),
                ),
                child: Text(_errorMessage!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.w500)),
              ),

            // --- SUBMIT BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                // Calls the initiation step
                onPressed: isFormValid && !_isTransferring ? _handleInitiateTransfer : null,
                style: ElevatedButton.styleFrom(
                  // Refactored hardcoded colors
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
                  // Refactored hardcoded padding
                  padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                  // Refactored hardcoded radius
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                  elevation: kCardElevation,
                ),
                child: Text(
                  'Initiate Transfer (Fee: ₹0.00)',
                  // Refactored hardcoded style
                  style: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}