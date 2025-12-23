import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// NOTE: Ensure your banking_service.dart file uses the mock implementation you provided.
import 'package:cabankapplication/api/banking_service.dart';
import 'package:cabankapplication/screens/transfer_result_screen.dart';

// Theme Imports
import 'package:cabankapplication/theme/app_colors.dart';
import 'package:cabankapplication/theme/app_dimensions.dart';

// -----------------------------------------------------------------------------
// --- STYLED OTP INPUT FIELD WIDGET ---
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

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
            // Use headlineSmall as a base for large OTP font
            style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: colorScheme.primary),

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
              hintStyle: textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  color: colorScheme.onSurface.withOpacity(0.2)),
              contentPadding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusSmall),
                borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.4), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusSmall),
                borderSide: BorderSide(color: colorScheme.primary, width: 3),
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
      if(mounted) setState(() { _calculatedFee = 0.0; _totalDebitAmount = 0.0; _calculationError = null; });
      return;
    }

    if(mounted) setState(() { _isCalculating = true; _calculationError = null; });

    try {
      final details = await widget.bankingService.calculateTransferDetails(
        transferType: _selectedTransferType,
        amount: amount,
        sourceAccountNumber: widget.sourceAccount.accountNumber,
      );
      if (!mounted) return;
      setState(() {
        _calculatedFee = details['fee'] as double;
        _totalDebitAmount = details['totalDebit'] as double;
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

    if (widget.sourceAccount.accountNumber.isEmpty || widget.beneficiary.accountNumber.isEmpty) {
      _showSnackbar('Missing source or beneficiary account details.', isError: true);
      return;
    }

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
        _transactionReference = (result['transactionReference'] ?? '') as String;
        _simulatedOtp = (result['mockOtp'] ?? '') as String;
        _otpMessage = (result['message'] ?? 'OTP sent to mobile.') as String;
        _otpRequested = true;
        _enteredOtp = '';
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _simulatedOtp = '';
      });
      _showSnackbar('Failed to send OTP: ${e.toString().split(': ').last}', isError: true);
    } finally {
      if (mounted) setState(() => _isOtpSending = false);
    }
  }


  Future<void> _submitTransferWithOtp() async {
    if (_enteredOtp.length != _otpLength) return;

    // --- MOCK OTP VALIDATION ---
    if (_enteredOtp != _simulatedOtp) {
      if (!mounted) return;
      Navigator.pop(context);
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
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TransferResultScreen(message: result, isSuccess: true)),
      );

    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().split(': ').last;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TransferResultScreen(message: errorMessage, isSuccess: false)),
      );
    } finally {
      if (mounted) setState(() => _isTransferring = false);
    }
  }

  // --- UI and Helper Methods ---

  void _showSnackbar(String message, {bool isError = false, bool isSuccess = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    Color color = colorScheme.primary;
    if (isError) color = colorScheme.error;
    if (isSuccess) color = kSuccessGreen;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor, TextStyle? customLabelStyle, TextStyle? customValueStyle}) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPaddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              // Default style for white on primary card
              style: customLabelStyle ?? textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontSize: 15)),
          const SizedBox(width: kPaddingTen),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              // Default style for bold white on primary card
              style: customValueStyle ?? textTheme.titleMedium?.copyWith(
                  color: valueColor ?? Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferSummaryCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
      margin: const EdgeInsets.only(bottom: kPaddingLarge),
      color: colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.account_balance_wallet, color: colorScheme.onPrimary, size: kIconSizeSmall),
              const SizedBox(width: kPaddingSmall),
              Text('FROM ACCOUNT', style: textTheme.labelLarge?.copyWith(fontSize: 13, color: colorScheme.onPrimary.withOpacity(0.7))),
            ]),
            _buildDetailRow(
              widget.sourceAccount.nickname,
              'A/c: ${widget.bankingService.maskAccountNumber(widget.sourceAccount.accountNumber)}',
              valueColor: kAccentOrange,
              customLabelStyle: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
            ),
            _buildDetailRow('Current Balance', '₹${widget.sourceAccount.balance.toStringAsFixed(2)}', valueColor: colorScheme.onPrimary),
            const Divider(height: kPaddingExtraLarge, thickness: 1, color: Colors.white24),
            Row(children: [
              Icon(Icons.send_to_mobile, color: colorScheme.onPrimary, size: kIconSizeSmall),
              const SizedBox(width: kPaddingSmall),
              Text('TO BENEFICIARY', style: textTheme.labelLarge?.copyWith(fontSize: 13, color: colorScheme.onPrimary.withOpacity(0.7))),
            ]),
            _buildDetailRow(
              widget.beneficiary.nickname,
              widget.bankingService.maskAccountNumber(widget.beneficiary.accountNumber),
              valueColor: colorScheme.onPrimary,
              customLabelStyle: textTheme.titleMedium?.copyWith(color: colorScheme.onPrimary),
            ),
            _buildDetailRow(
              'Bank/IFSC',
              '${widget.beneficiary.bankName} (${widget.beneficiary.ifsCode})',
              valueColor: colorScheme.onPrimary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferTypeSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final rules = widget.bankingService.getTransferTypeRules();

    if (_isInternalTransfer) {
      return Padding(
        padding: const EdgeInsets.only(bottom: kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfer Method', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
            const SizedBox(height: kPaddingSmall),
            Container(
              padding: const EdgeInsets.all(kPaddingMedium),
              decoration: BoxDecoration(
                color: kSuccessGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(kRadiusSmall),
                border: Border.all(color: kSuccessGreen.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: kSuccessGreen),
                  const SizedBox(width: kPaddingTen),
                  Text('Internal Transfer (Instant & Free)', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kSuccessGreen)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      final externalTypes = TransferType.values.where((t) => t != TransferType.internal).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select Transfer Method', style: textTheme.titleMedium?.copyWith(color: colorScheme.primary)),
          const SizedBox(height: kPaddingTen),
          Wrap(
            spacing: kPaddingTen,
            runSpacing: kPaddingTen,
            children: externalTypes.map((type) {
              final isSelected = _selectedTransferType == type;
              return ChoiceChip(
                label: Text(type.name.toUpperCase()),
                selected: isSelected,
                selectedColor: colorScheme.primary,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedTransferType = type;
                      _recalculateFees(double.tryParse(_amountController.text) ?? 0.0);
                    });
                  }
                },
                labelStyle: textTheme.titleSmall?.copyWith(
                  color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusSmall),
                  side: BorderSide(color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.3)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: kPaddingMedium),
          Container(
            padding: const EdgeInsets.all(kPaddingMedium),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(kRadiusSmall),
              border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
            ),
            child: Text(rules[_selectedTransferType] ?? 'Select a transfer type to view rules.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onBackground.withOpacity(0.6))),
          ),
          const SizedBox(height: kPaddingLarge),
        ],
      );
    }
  }

  /// Builds the content for the OTP verification dialog.
  Widget _buildConfirmationModalContent(BuildContext context, StateSetter modalSetState) {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(kPaddingLarge),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Payment Confirmation', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
            const Divider(height: kPaddingLarge, indent: 60, endIndent: 60),

            Container(
              padding: const EdgeInsets.all(kPaddingMedium),
              decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(kRadiusSmall)),
              child: Column(
                children: [
                  _buildDetailRow('Amount', '₹${amount.toStringAsFixed(2)}', valueColor: colorScheme.onSurface, customLabelStyle: textTheme.bodyMedium),
                  if (_calculatedFee > 0)
                    _buildDetailRow('Fee', '+ ₹${_calculatedFee.toStringAsFixed(2)}', valueColor: kErrorRed, customLabelStyle: textTheme.bodyMedium),
                  const Divider(),
                  _buildDetailRow(
                    'Total Debit',
                    '₹${_totalDebitAmount.toStringAsFixed(2)}',
                    valueColor: colorScheme.primary,
                    customLabelStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    customValueStyle: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: kPaddingExtraLarge),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: kPaddingSmall),
                Text('Enter Verification Code', style: textTheme.titleLarge?.copyWith(color: colorScheme.primary)),
              ],
            ),
            const SizedBox(height: kPaddingTen),

            Text(
                '$_otpMessage.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7), fontStyle: FontStyle.italic)
            ),

            const SizedBox(height: kPaddingLarge),

            StyledOtpInputFields(
              onOtpChanged: (otp) {
                // IMPORTANT: 1. Update the main screen's state variable
                setState(() {
                  _enteredOtp = otp;
                });
                // IMPORTANT: 2. Use modalSetState to force the dialog UI to rebuild instantly.
                modalSetState(() {
                  // Rebuilds dialog UI based on updated _enteredOtp from main state
                });
              },
            ),

            // --- DEBUG LINE ADDED FOR USER FEEDBACK (Now updates instantly) ---
            Padding(
              padding: const EdgeInsets.only(top: kPaddingSmall),
              child: Text(
                'Entered OTP Length: ${_enteredOtp.length} / $_otpLength',
                style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _enteredOtp.length == _otpLength ? kSuccessGreen : colorScheme.error),
              ),
            ),
            // --- END DEBUG LINE ---

            const SizedBox(height: kPaddingMedium),

            TextButton(
              onPressed: _isOtpSending ? null : _requestOtp,
              child: Text(
                _isOtpSending ? 'Sending new OTP...' : 'Didn\'t receive the code? RESEND OTP',
                style: textTheme.titleMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: kPaddingLarge),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTransferring ? null : () {Navigator.pop(context);},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      side: BorderSide(color: colorScheme.primary, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                    ),
                    child: Text('CANCEL', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: kPaddingTen),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTransferring || _enteredOtp.length != _otpLength ? null : _submitTransferWithOtp,
                    icon: _isTransferring ? const SizedBox(width: kIconSizeSmall, height: kIconSizeSmall, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified_user, color: Colors.white),
                    label: Text(_isTransferring ? 'Processing...' : 'CONFIRM PAY', style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kSuccessGreen,
                      disabledBackgroundColor: kSuccessGreen.withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                    ),
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // --- OTP Verification Dialog Display ---
    if (_otpRequested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_transactionReference.isNotEmpty && ModalRoute.of(context)?.isCurrent == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
              child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter modalSetState) {
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
                // _simulatedOtp is intentionally kept for mock testing visibility
              });
            }
          });
          _otpRequested = false;
        }
      });
    }
    // --- End OTP Verification Dialog Display ---

    return Scaffold(
      appBar: AppBar(
        title: Text('Transfer to ${widget.beneficiary.nickname}', style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary)),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
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
                  suffixIcon: _isCalculating ? Padding(padding: const EdgeInsets.all(kPaddingTen), child: SizedBox(width: kIconSizeSmall, height: kIconSizeSmall, child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary))) : null,
                  // The rest of the decoration (border, focused border) is handled by the theme
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
              const SizedBox(height: kPaddingLarge),
              TextFormField(
                controller: _narrationController,
                decoration: const InputDecoration(labelText: 'Narration / Remarks (Optional)', prefixIcon: Icon(Icons.comment)),
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: kPaddingLarge),

              // --- MOCK DEBUGGING MESSAGE: REMAINS FOR TESTING SUCCESSFUL FLOW ---
              if (_simulatedOtp.isNotEmpty && !_isTransferring)
                Container(
                  padding: const EdgeInsets.all(kPaddingTen),
                  margin: const EdgeInsets.only(bottom: kPaddingLarge),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(kRadiusSmall),
                    border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      'TESTING ONLY: Mock OTP is ${_simulatedOtp}',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              // --- END MOCK DEBUGGING MESSAGE ---

              if ((double.tryParse(_amountController.text) ?? 0.0) > 0 && _calculationError == null && !_isCalculating)
                Container(
                  padding: const EdgeInsets.all(kPaddingMedium),
                  margin: const EdgeInsets.only(bottom: kPaddingExtraLarge),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(kRadiusSmall),
                    border: Border.all(color: colorScheme.onSurface.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('Transfer Fee', '₹${_calculatedFee.toStringAsFixed(2)}', valueColor: colorScheme.onSurface, customLabelStyle: textTheme.bodyMedium),
                      const Divider(height: kPaddingTen),
                      _buildDetailRow(
                        'Total Debit Amount',
                        '₹${_totalDebitAmount.toStringAsFixed(2)}',
                        valueColor: colorScheme.primary,
                        customLabelStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        customValueStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 18),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.only(bottom: kPaddingExtraLarge),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCalculating || _calculationError != null || _isOtpSending || _isTransferring ? null : _requestOtp,
                    icon: _isOtpSending || _isTransferring ? const SizedBox(width: kIconSizeSmall, height: kIconSizeSmall, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.arrow_forward_ios, size: kIconSizeSmall, color: Colors.white),
                    label: Text(_isOtpSending ? 'SENDING OTP...' : 'PROCEED TO CONFIRM', style: textTheme.titleLarge?.copyWith(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                      // Shape is handled by the default ElevatedButtonTheme
                    ),
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