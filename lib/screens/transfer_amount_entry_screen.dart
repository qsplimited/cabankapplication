import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 💡 IMPORTANT: Import all necessary types and the service from the canonical API file.
import 'package:cabankapplication/api/banking_service.dart';
import 'package:cabankapplication/screens/transfer_result_screen.dart';


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
  // --- Constants and Theme (MODERNIZED COLORS) ---
  final Color _primaryColor = const Color(0xFF003366); // Dark Blue (App Bar, Main Buttons)
  final Color _accentColor = const Color(0xFFE53935); // Secondary/Error Color (Red)
  final Color _successColor = const Color(0xFF2E7D32); // Success/Confirm Pay Color (Dark Green)
  final TextStyle _labelStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54);

  // --- Transfer State ---
  late bool _isInternalTransfer;
  TransferType _selectedTransferType = TransferType.imps;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _tpinController = TextEditingController();

  // --- Calculation State ---
  double _calculatedFee = 0.0;
  double _totalDebitAmount = 0.0;
  bool _isCalculating = false;
  String? _calculationError;

  // --- UI Flow State ---
  bool _showConfirmation = false;
  bool _isTransferring = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  static const int _tpinLength = 6;

  @override
  void initState() {
    super.initState();
    // 💡 CORE LOGIC: Check if the beneficiary is internal to determine UI flow
    _isInternalTransfer = widget.bankingService.isInternalIfsc(widget.beneficiary.ifsCode);

    if (_isInternalTransfer) {
      // If internal, lock the transfer type
      _selectedTransferType = TransferType.internal;
    } else {
      // If external, default to IMPS (or any preferred external type)
      _selectedTransferType = TransferType.imps;
    }

    _amountController.addListener(_recalculateFeesDebounced);
    _recalculateFees(1.0); // Initial check for limits/rules without an actual amount
  }

  @override
  void dispose() {
    _amountController.removeListener(_recalculateFeesDebounced);
    _amountController.dispose();
    _narrationController.dispose();
    _tpinController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // --- Fee Calculation and Debounce ---
  Timer? _debounce;
  void _recalculateFeesDebounced() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 700), () {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      _recalculateFees(amount);
    });
  }

  Future<void> _recalculateFees(double amount) async {
    // Skip calculation if amount is zero, unless it's the initial check (amount=1.0)
    if (amount <= 0 && amount != 1.0) {
      setState(() { _calculatedFee = 0.0; _totalDebitAmount = 0.0; _calculationError = null; });
      return;
    }

    setState(() { _isCalculating = true; _calculationError = null; });

    try {
      final details = await widget.bankingService.calculateTransferDetails(
        transferType: _selectedTransferType,
        amount: amount,
        sourceAccountNumber: widget.sourceAccount.accountNumber,
      );
      if (!mounted) return;
      setState(() {
        _calculatedFee = details['fee']!;
        _totalDebitAmount = details['totalDebit']!;
        _isCalculating = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Error means limit reached or insufficient funds, clear fee/total
      setState(() {
        _calculationError = e.toString().split(': ').last;
        _calculatedFee = 0.0;
        _totalDebitAmount = 0.0;
        _isCalculating = false;
      });
    }
  }

  // --- Flow Handlers ---
  void _confirmTransfer() {
    if (_formKey.currentState!.validate()) {
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      if (amount <= 0) {
        _showSnackbar('Please enter a transfer amount.');
        return;
      }
      if (_calculationError != null) {
        _showSnackbar('Cannot proceed due to validation error: $_calculationError');
        return;
      }
      // Set to true, which triggers the modal in the build method
      setState(() {
        _showConfirmation = true; _tpinController.clear();
      });
    }
  }

  Future<void> _submitTransfer() async {
    if (_tpinController.text.length != _tpinLength) {
      _showSnackbar('T-PIN must be $_tpinLength digits.');
      return;
    }

    setState(() => _isTransferring = true);

    try {
      final amount = double.parse(_amountController.text);
      final result = await widget.bankingService.submitFundTransfer(
        recipientAccount: widget.beneficiary.accountNumber,
        recipientName: widget.beneficiary.name,
        ifsCode: widget.beneficiary.ifsCode,
        transferType: _selectedTransferType, // Uses internal or external type
        amount: amount,
        narration: _narrationController.text,
        transactionPin: _tpinController.text,
        sourceAccountNumber: widget.sourceAccount.accountNumber,
      );

      if (!mounted) return;
      // Navigate to success screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TransferResultScreen(message: result, isSuccess: true)),
      );

    } catch (e) {
      if (!mounted) return;
      final errorMessage = e.toString().split(': ').last;
      // Navigate to failure screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TransferResultScreen(message: errorMessage, isSuccess: false)),
      );
    } finally {
      // Reset the state, though navigation will typically cover this
      setState(() => _isTransferring = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: _accentColor),
    );
  }

  // --- UI Builder Methods ---
  Widget _buildDetailRow(String label, String value, {Color? valueColor, TextStyle? customLabelStyle, TextStyle? customValueStyle}) {
    // Improved Row for better alignment and text wrapping
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: customLabelStyle ?? _labelStyle.copyWith(color: Colors.white70, fontSize: 15)),
          const SizedBox(width: 10), // Spacing between label and value
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

  // Attractive Source and Destination Card
  Widget _buildTransferSummaryCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 25),
      color: _primaryColor, // Use primary color for a premium look
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FROM Account ---
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('FROM ACCOUNT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
              ],
            ),
            _buildDetailRow(
              widget.sourceAccount.nickname,
              'A/c: ${widget.bankingService.maskAccountNumber(widget.sourceAccount.accountNumber)}',
              valueColor: Colors.yellowAccent,
              customLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            _buildDetailRow('Current Balance', '₹${widget.sourceAccount.balance.toStringAsFixed(2)}', valueColor: Colors.white),

            const Divider(height: 30, thickness: 1, color: Colors.white24),

            // --- TO Beneficiary ---
            Row(
              children: [
                const Icon(Icons.send_to_mobile, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('TO BENEFICIARY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white70)),
              ],
            ),
            _buildDetailRow(
              widget.beneficiary.nickname,
              widget.bankingService.maskAccountNumber(widget.beneficiary.accountNumber),
              valueColor: Colors.white,
              customLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            _buildDetailRow(
              'Bank/IFSC',
              '${widget.beneficiary.bankName} (${widget.beneficiary.ifsCode})',
              valueColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  // Dynamically shows/hides the transfer type options
  Widget _buildTransferTypeSelector() {
    if (_isInternalTransfer) {
      // Case 1: Internal Transfer (IFSC matched)
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
      // Case 2: External Transfer (IMPS/NEFT/RTGS)
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

          // Display Rules based on selection
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _primaryColor.withOpacity(0.2)),
            ),
            child: Text(
              rules[_selectedTransferType] ?? 'Select a transfer type to view rules.',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }
  }

  // Transfer Confirmation/T-PIN Modal (The new pop-up design)
  Widget _buildConfirmationModal() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    return SingleChildScrollView( // CRITICAL: Makes the content scrollable for keyboard push
      child: Container(
        // CRITICAL: Adjusts padding for the soft keyboard when open
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 30, left: 20, right: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HEADING SIZE AND STYLE
            Text('Confirm Transfer', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _primaryColor)),
            const Divider(height: 20, indent: 80, endIndent: 80),

            // Confirmation Details Summary
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, // Light grey background for summary (high contrast)
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300)
              ),
              child: Column(
                children: [
                  // Detail Rows with appropriate color/size for clarity
                  _buildDetailRow('Amount', '₹${amount.toStringAsFixed(2)}', valueColor: Colors.black, customLabelStyle: const TextStyle(color: Colors.black54)),
                  if (_calculatedFee > 0)
                    _buildDetailRow('Fee', '+ ₹${_calculatedFee.toStringAsFixed(2)}', valueColor: Colors.red.shade700, customLabelStyle: const TextStyle(color: Colors.black54)),
                  const Divider(),
                  // HIGHLIGHTED TOTAL DEBIT (BOLD, PRIMARY COLOR, LARGER FONT)
                  _buildDetailRow(
                    'Total Debit',
                    '₹${_totalDebitAmount.toStringAsFixed(2)}',
                    valueColor: _primaryColor,
                    customLabelStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 17),
                    customValueStyle: TextStyle(fontWeight: FontWeight.bold, color: _primaryColor, fontSize: 20),
                  ),
                  const Divider(height: 15),
                  _buildDetailRow(
                      'Transfer Type',
                      _selectedTransferType.name.toUpperCase(),
                      valueColor: Colors.black, customLabelStyle: const TextStyle(color: Colors.black54)),
                  _buildDetailRow('To Payee', widget.beneficiary.nickname, valueColor: Colors.black, customLabelStyle: const TextStyle(color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // T-PIN Entry (6-digit format)
            TextFormField(
              controller: _tpinController,
              decoration: InputDecoration(
                labelText: 'Enter 6-Digit T-PIN for Security',
                // Use a larger label text for emphasis
                labelStyle: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold),
                prefixIcon: Icon(Icons.lock_person, color: _primaryColor, size: 24), // Clearer icon
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: _primaryColor, width: 2), // Focus color
                ),
                counterText: '', // Hide default character counter
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: _tpinLength,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) => (value?.length != _tpinLength) ? 'T-PIN must be 6 digits.' : null,
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isTransferring ? null : () {
                        // IMPORTANT: Dismiss the modal via Navigator before setting state
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor, width: 2), // Thicker border
                          padding: const EdgeInsets.symmetric(vertical: 18)), // Taller button
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isTransferring ? null : _submitTransfer,
                      icon: _isTransferring ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.verified_user, color: Colors.white),
                      label: Text(_isTransferring ? 'Processing...' : 'CONFIRM PAY', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _successColor,
                          padding: const EdgeInsets.symmetric(vertical: 18)), // Taller button
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Show the confirmation modal as a standard bottom sheet on top of the main screen
    if (_showConfirmation) {
      // Use showModalBottomSheet for a true modal experience
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only show if not already showing (to prevent multiple calls)
        if (ModalRoute.of(context)?.isCurrent == true) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // CRITICAL: Allows sheet to take up almost the full screen height (necessary for keyboard responsiveness)
            isDismissible: false, // Force user to use CANCEL/CONFIRM buttons
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            builder: (context) => _buildConfirmationModal(),
          ).then((_) {
            // Reset the state when the sheet is closed (e.g., via CANCEL button or success/failure navigation)
            if(mounted) {
              setState(() => _showConfirmation = false);
            }
          });
          // This line prevents the modal from being repeatedly built
          _showConfirmation = false;
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        // Title size and style are clean and bold
        title: Text('Transfer to ${widget.beneficiary.nickname}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // The body is fully scrollable and contains all input fields and the button
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // 1. Source/Beneficiary Summary
              _buildTransferSummaryCard(),

              // 2. Transfer Type Selector
              _buildTransferTypeSelector(),

              // 3. Amount Entry
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Transfer Amount (Min: ₹1.00)',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  suffixIcon: _isCalculating
                      ? Padding(padding: const EdgeInsets.all(10.0), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor)))
                      : null,
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

              // 4. Narration/Remarks
              TextFormField(
                controller: _narrationController,
                decoration: const InputDecoration(
                  labelText: 'Narration / Remarks (Optional)',
                  prefixIcon: Icon(Icons.comment),
                  border: OutlineInputBorder(),
                ),
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),

              // 5. Fee and Total Display (Styled for high contrast)
              if ((double.tryParse(_amountController.text) ?? 0.0) > 0 && _calculationError == null && !_isCalculating)
                Container(
                  padding: const EdgeInsets.all(15),
                  margin: const EdgeInsets.only(bottom: 30), // Added bottom margin for spacing before the button
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300)
                  ),
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

              // 6. Proceed Button (Aligned to the bottom of the scroll view)
              Padding(
                // This padding ensures the button is never flush against the bottom of the visible screen area if not scrolling
                padding: const EdgeInsets.only(bottom: 30.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isCalculating || _calculationError != null ? null : _confirmTransfer,
                    icon: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white),
                    label: const Text('PROCEED TO CONFIRM', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor, padding: const EdgeInsets.symmetric(vertical: 18)),
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