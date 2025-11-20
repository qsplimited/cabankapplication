import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// NOTE: Ensure your banking_service.dart file uses the mock implementation you provided.
import 'package:cabankapplication/api/banking_service.dart';
import 'package:cabankapplication/screens/transfer_result_screen.dart';


// -----------------------------------------------------------------------------
// --- STYLED OTP INPUT FIELD WIDGET (Included for completeness) ---
// -----------------------------------------------------------------------------

/// Custom widget to handle the 6-digit OTP input fields with a modern style.
class StyledOtpInputFields extends StatefulWidget {
  final ValueChanged<String> onOtpChanged;
  final int otpLength;

  const StyledOtpInputFields({
    super.key,
    required this.onOtpChanged,
    this.otpLength = 6,
  });

  @override
  State<StyledOtpInputFields> createState() => _StyledOtpInputFieldsState();
}

class _StyledOtpInputFieldsState extends State<StyledOtpInputFields> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;
  String _currentOtp = '';

  // Theme colors for input
  final Color _primaryColor = const Color(0xFF003366);

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.otpLength, (index) => TextEditingController());
    _focusNodes = List.generate(widget.otpLength, (index) => FocusNode());
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
    // Collect the text from all controllers, filtering out any empty ones
    final newOtp = _controllers.map((c) => c.text.isNotEmpty ? c.text : '').join('');

    // Only call onOtpChanged if the OTP string has actually changed
    if (_currentOtp != newOtp) {
      _currentOtp = newOtp;
      widget.onOtpChanged(_currentOtp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(widget.otpLength, (index) {
        // Reduced width from 48 to 40 to prevent RenderFlex overflow and minimize box size.
        return SizedBox(
          width: 40,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _primaryColor),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],

            onChanged: (value) {
              if (value.length == 1 && index < widget.otpLength - 1) {
                // Move to next field if a digit is entered
                FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                // Move back on delete
                Future.delayed(const Duration(milliseconds: 50), () {
                  if (mounted) {
                    FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                  }
                });
              }
              _updateOtp();
            },

            decoration: InputDecoration(
              counterText: "",
              hintText: '0',
              hintStyle: TextStyle(fontSize: 24, color: Colors.grey.shade300),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor, width: 3),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// -----------------------------------------------------------------------------
// --- TRANSFER AMOUNT ENTRY SCREEN ---
// -----------------------------------------------------------------------------

class TransferAmountEntryScreen extends StatefulWidget {
  final Account sourceAccount;
  final Beneficiary beneficiary;
  final BankingService bankingService;

  const TransferAmountEntryScreen({
    Key? key,
    required this.sourceAccount,
    required this.beneficiary,
    required this.bankingService,
  }) : super(key: key);

  @override
  State<TransferAmountEntryScreen> createState() => _TransferAmountEntryScreenState();
}

class _TransferAmountEntryScreenState extends State<TransferAmountEntryScreen> {
  // --- Constants and Theme ---
  final Color _primaryColor = const Color(0xFF003366);
  final Color _accentColor = const Color(0xFFE53935);
  final Color _successColor = const Color(0xFF2E7D32);
  final TextStyle _labelStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54);

  // --- Transfer State ---
  late bool _isInternalTransfer;
  TransferType _selectedTransferType = TransferType.imps;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();

  // --- Calculation State ---
  double _calculatedFee = 0.0;
  double _totalDebitAmount = 0.0;
  bool _isCalculating = false;
  String? _calculationError;

  // --- OTP State ---
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _otpRequested = false;
  bool _isOtpSending = false;
  bool _isTransferring = false;
  String _transactionReference = '';
  String _simulatedOtp = ''; // Kept internally for mock validation only
  String _otpMessage = '';
  String _enteredOtp = '';
  static const int _otpLength = 6;

  // Debounce timer for fee calculation
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _isInternalTransfer = widget.bankingService.isInternalIfsc(widget.beneficiary.ifsCode);

    if (_isInternalTransfer) {
      _selectedTransferType = TransferType.internal;
    } else {
      _selectedTransferType = TransferType.imps;
    }

    _amountController.addListener(_recalculateFeesDebounced);
    _recalculateFees(1.0);
  }

  @override
  void dispose() {
    _amountController.removeListener(_recalculateFeesDebounced);
    _amountController.dispose();
    _narrationController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _recalculateFeesDebounced() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      _recalculateFees(amount);
    });
  }

  Future<void> _recalculateFees(double amount) async {
    // Skip calculation if amount is zero, but allow calculation for the initial 1.0 check
    if (amount <= 0 && amount != 1.0) {
      setState(() { _calculatedFee = 0.0; _totalDebitAmount = 0.0; _calculationError = null; });
      return;
    }

    setState(() { _isCalculating = true; _calculationError = null; });

    try {
      // NOTE: Call is safe as parameters are checked in initState/form validation
      final details = await widget.bankingService.calculateTransferDetails(
        transferType: _selectedTransferType,
        amount: amount,
        sourceAccountNumber: widget.sourceAccount.accountNumber,
      );
      if (!mounted) return;
      setState(() {
        _calculatedFee = details['fee'] as double; // Explicitly cast to double
        _totalDebitAmount = details['totalDebit'] as double; // Explicitly cast to double
        _isCalculating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _calculationError = e.toString().split(': ').last;
        _calculatedFee = 0.0;
        _totalDebitAmount = 0.0;
        _isCalculating = false;
      });
    }
  }


  // --- OTP FLOW HANDLERS ---

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      _showSnackbar('Please enter a transfer amount.', isError: true);
      return;
    }
    // Re-check calculation error before proceeding
    if (_calculationError != null) {
      _showSnackbar('Cannot proceed due to validation error: $_calculationError', isError: true);
      return;
    }

    // --- Null Safety Check for API Parameters ---
    if (widget.sourceAccount.accountNumber.isEmpty || widget.beneficiary.accountNumber.isEmpty) {
      _showSnackbar('Missing source or beneficiary account details.', isError: true);
      return;
    }
    // ------------------------------------------

    setState(() => _isOtpSending = true);

    try {
      // Re-run the fee calculation one last time to ensure latest details are used
      await _recalculateFees(amount);
      if (_calculationError != null) {
        _showSnackbar('Cannot proceed due to validation error: $_calculationError', isError: true);
        return;
      }

      final result = await widget.bankingService.requestFundTransferOtp(
        recipientAccount: widget.beneficiary.accountNumber,
        amount: amount,
        sourceAccountNumber: widget.sourceAccount.accountNumber,
        transferType: _selectedTransferType,
      );

      if (!mounted) return;
      setState(() {
        // Explicitly cast to String to prevent the null-type error if the mock returns null for a field.
        _transactionReference = (result['transactionReference'] ?? '') as String;
        _simulatedOtp = (result['mockOtp'] ?? '') as String; // Get the mock OTP
        _otpMessage = (result['message'] ?? 'OTP sent to mobile.') as String;
        _otpRequested = true;
        _enteredOtp = '';
        // Note: The modal is shown in the build method's post-frame callback
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _simulatedOtp = ''; // Clear OTP if request failed
      });
      _showSnackbar('Failed to send OTP: ${e.toString().split(': ').last}', isError: true);
    } finally {
      if (mounted) setState(() => _isOtpSending = false);
    }
  }


  Future<void> _submitTransferWithOtp() async {
    // Check if the button was enabled by mistake (shouldn't happen, but safe)
    if (_enteredOtp.length != _otpLength) return;

    // --- MOCK OTP VALIDATION (Simulates failure for wrong OTP) ---
    // NOTE: The mock service handles the official validation, but we can do a quick check here.
    if (_enteredOtp != _simulatedOtp) {
      if (!mounted) return;
      // Close the modal before showing the result screen
      Navigator.pop(context);
      // FIX: Use push() instead of pushReplacement() to keep the current screen on the stack
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TransferResultScreen(
          message: 'The entered OTP is incorrect or has expired. Please retry the transfer.',
          isSuccess: false,
        )),
      );
      return;
    }
    // --- END MOCK VALIDATION ---

    setState(() => _isTransferring = true);

    try {
      final amount = double.parse(_amountController.text);
      final result = await widget.bankingService.submitFundTransfer(
        recipientAccount: widget.beneficiary.accountNumber,
        recipientName: widget.beneficiary.name,
        ifsCode: widget.beneficiary.ifsCode,
        transferType: _selectedTransferType,
        amount: amount,
        narration: _narrationController.text,
        transactionReference: _transactionReference,
        transactionOtp: _enteredOtp,
        sourceAccountNumber: widget.sourceAccount.accountNumber,
      );

      if (!mounted) return;
      // Close the modal before navigating to the result screen
      Navigator.pop(context);
      // FIX: Use push() instead of pushReplacement() to keep the current screen on the stack
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TransferResultScreen(message: result, isSuccess: true)),
      );

    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().split(': ').last;
      // Close the modal before navigating to the result screen
      Navigator.pop(context);
      // FIX: Use push() instead of pushReplacement() to keep the current screen on the stack
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TransferResultScreen(message: errorMessage, isSuccess: false)),
      );
    } finally {
      // Important: This setState will only update the main screen's state, but the dialog is already closed.
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  // --- UI and Helper Methods ---

  void _showSnackbar(String message, {bool isError = false, bool isSuccess = false}) {
    Color color = _primaryColor;
    if (isError) color = _accentColor;
    if (isSuccess) color = _successColor;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, TextStyle? customLabelStyle, TextStyle? customValueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: customLabelStyle ?? _labelStyle.copyWith(color: Colors.white70, fontSize: 15)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: customValueStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                  .copyWith(color: valueColor ?? Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferSummaryCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 25),
      color: _primaryColor,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20), const SizedBox(width: 8), const Text('FROM ACCOUNT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),]),
            _buildDetailRow(widget.sourceAccount.nickname,'A/c: ${widget.bankingService.maskAccountNumber(widget.sourceAccount.accountNumber)}',valueColor: Colors.yellowAccent,customLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),),
            _buildDetailRow('Current Balance', '₹${widget.sourceAccount.balance.toStringAsFixed(2)}', valueColor: Colors.white),
            const Divider(height: 30, thickness: 1, color: Colors.white24),
            Row(children: [const Icon(Icons.send_to_mobile, color: Colors.white, size: 20), const SizedBox(width: 8), const Text('TO BENEFICIARY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),]),
            _buildDetailRow(widget.beneficiary.nickname,widget.bankingService.maskAccountNumber(widget.beneficiary.accountNumber),valueColor: Colors.white,customLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),),
            _buildDetailRow('Bank/IFSC','${widget.beneficiary.bankName} (${widget.beneficiary.ifsCode})',valueColor: Colors.white,),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferTypeSelector() {
    if (_isInternalTransfer) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfer Method', style: _labelStyle.copyWith(fontSize: 16, color: _primaryColor)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flash_on, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Internal Transfer (Instant & Free)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      final externalTypes = TransferType.values.where((t) => t != TransferType.internal).toList();
      final rules = widget.bankingService.getTransferTypeRules();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Transfer Method', style: _labelStyle.copyWith(fontSize: 16, color: _primaryColor)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: externalTypes.map((type) {
              final isSelected = _selectedTransferType == type;
              return ChoiceChip(
                label: Text(type.name.toUpperCase()),
                selected: isSelected,
                selectedColor: _primaryColor,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedTransferType = type;
                      _recalculateFees(double.tryParse(_amountController.text) ?? 0.0);
                    });
                  }
                },
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _primaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: isSelected ? _primaryColor : Colors.grey.shade300),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primaryColor.withOpacity(0.2)),
            ),
            child: Text(rules[_selectedTransferType] ?? 'Select a transfer type to view rules.',style: const TextStyle(fontSize: 13, color: Colors.black54),),
          ),
          const SizedBox(height: 20),
        ],
      );
    }
  }

  /// Builds the content for the OTP verification dialog.
  Widget _buildConfirmationModalContent(BuildContext context, StateSetter modalSetState) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // Use Padding and SingleChildScrollView to ensure content fits neatly in the Dialog
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // MODIFICATION: Changed heading to smaller text size and different label
            Text('Payment Confirmation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
            const Divider(height: 20, indent: 60, endIndent: 60),

            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10),),
              child: Column(
                children: [
                  _buildDetailRow('Amount', '₹${amount.toStringAsFixed(2)}', valueColor: Colors.black, customLabelStyle: const TextStyle(color: Colors.black54)),
                  if (_calculatedFee > 0)
                    _buildDetailRow('Fee', '+ ₹${_calculatedFee.toStringAsFixed(2)}', valueColor: Colors.red.shade700, customLabelStyle: const TextStyle(color: Colors.black54)),
                  const Divider(),
                  _buildDetailRow(
                    'Total Debit',
                    '₹${_totalDebitAmount.toStringAsFixed(2)}',
                    valueColor: _primaryColor,
                    customLabelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 17),
                    customValueStyle: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 8),
                Text('Enter Verification Code', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
              ],
            ),
            const SizedBox(height: 10),

            // MODIFICATION: OTP message
            Text(
                '$_otpMessage.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic)
            ),
            const SizedBox(height: 25),

            StyledOtpInputFields(
              onOtpChanged: (otp) {
                // IMPORTANT: 1. Update the main screen's state variable
                setState(() {
                  _enteredOtp = otp;
                });
                // IMPORTANT: 2. Use modalSetState to force the dialog UI to rebuild instantly.
                modalSetState(() {
                  // No need to set state variables here as they are updated by the main setState.
                });
              },
            ),

            // --- DEBUG LINE ADDED FOR USER FEEDBACK (Now updates instantly) ---
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Entered OTP Length: ${_enteredOtp.length} / $_otpLength',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _enteredOtp.length == _otpLength ? _successColor : _accentColor),
              ),
            ),
            // --- END DEBUG LINE ---

            const SizedBox(height: 15),

            TextButton(
              onPressed: _isOtpSending ? null : _requestOtp,
              child: Text(
                _isOtpSending ? 'Sending new OTP...' : 'Didn\'t receive the code? RESEND OTP',
                style: TextStyle(color: _accentColor, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 25),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTransferring ? null : () {Navigator.pop(context);},
                    style: OutlinedButton.styleFrom(foregroundColor: _primaryColor, side: BorderSide(color: _primaryColor, width: 2), padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    // This logic is correct and should now enable the button when length is 6
                    onPressed: _isTransferring || _enteredOtp.length != _otpLength ? null : _submitTransferWithOtp,
                    icon: _isTransferring ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified_user, color: Colors.white),
                    label: Text(_isTransferring ? 'Processing...' : 'CONFIRM PAY', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(backgroundColor: _successColor, disabledBackgroundColor: _successColor.withOpacity(0.5), padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // --- OTP Verification Dialog Display ---
    if (_otpRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_transactionReference.isNotEmpty && ModalRoute.of(context)?.isCurrent == true) {
          showDialog(
            context: context,
            barrierDismissible: false, // Prevents closing by tapping outside
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              // FIX: Use a StatefulBuilder to get the local StateSetter for the dialog
              child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter modalSetState) {
                    // Pass the local state setter to the content builder
                    return _buildConfirmationModalContent(context, modalSetState);
                  }
              ),
            ),
          ).then((_) {
            // Reset OTP state when dialog is dismissed
            if(mounted) {
              setState(() {
                _otpRequested = false;
                _enteredOtp = '';
                _transactionReference = '';
                // Do not clear _simulatedOtp here so it stays on the screen for testing
              });
            }
          });
          _otpRequested = false; // Prevents re-showing if state rebuilds quickly
        }
      });
    }
    // --- End OTP Verification Dialog Display ---

    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer to ${widget.beneficiary.nickname}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTransferSummaryCard(),
              _buildTransferTypeSelector(),

              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Transfer Amount (Min: ₹1.00)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  suffixIcon: _isCalculating ? Padding(padding: const EdgeInsets.all(10.0), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor))) : null,
                  border: const OutlineInputBorder(),
                  errorText: _calculationError,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')), ],
                validator: (value) {
                  final amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) return 'Enter a valid amount.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _narrationController,
                decoration: const InputDecoration(labelText: 'Narration / Remarks (Optional)', prefixIcon: Icon(Icons.comment), border: const OutlineInputBorder(),),
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // --- MOCK DEBUGGING MESSAGE: REMAINS FOR TESTING SUCCESSFUL FLOW ---
              if (_simulatedOtp.isNotEmpty && !_isTransferring)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade300)),
                  child: Center(
                    child: Text(
                      'TESTING ONLY: Mock OTP is ${_simulatedOtp}',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              // --- END MOCK DEBUGGING MESSAGE ---

              if ((double.tryParse(_amountController.text) ?? 0.0) > 0 && _calculationError == null && !_isCalculating)
                Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 30),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                  child: Column(
                    children: [
                      _buildDetailRow('Transfer Fee', '₹${_calculatedFee.toStringAsFixed(2)}', valueColor: Colors.black, customLabelStyle: const TextStyle(color: Colors.black54)),
                      const Divider(height: 10),
                      _buildDetailRow(
                        'Total Debit Amount',
                        '₹${_totalDebitAmount.toStringAsFixed(2)}',
                        valueColor: _primaryColor,
                        customLabelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                        customValueStyle: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 18),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCalculating || _calculationError != null || _isOtpSending || _isTransferring ? null : _requestOtp,
                    icon: _isOtpSending || _isTransferring ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
                    label: Text(_isOtpSending ? 'SENDING OTP...' : 'PROCEED TO CONFIRM', style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 18)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}