// File: transfer_amount_entry_screen.dart (FINAL REVISED DESIGN)

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
  // --- Constants and Theme ---
  final Color _primaryColor = const Color(0xFF003366); // App Bar Color (Dark Blue)
  final Color _accentColor = const Color(0xFFE53935); // Secondary/Error Color (Red)
  final Color _successColor = Colors.green.shade700; // Success/Confirm Pay Color
  final TextStyle _labelStyle = const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54);
  final TextStyle _valueStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black);

  // --- Transfer State ---
  TransferType _selectedTransferType = TransferType.imps;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _narrationController = TextEditingController();
  final TextEditingController _tpinController = TextEditingController();

  // --- Calculation State (For validation only, NOT displayed per request) ---
  double _calculatedFee = 0.0;
  double _totalDebitAmount = 0.0;
  bool _isCalculating = false;
  String? _calculationError;

  // --- UI Flow State ---
  bool _showConfirmation = false;
  bool _isTransferring = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // --- Rules ---
  late final Map<TransferType, String> _transferRules;
  // USER REQUESTED 6 DIGITS
  static const int _tpinLength = 6;

  @override
  void initState() {
    super.initState();
    _transferRules = widget.bankingService.getTransferTypeRules();
    _amountController.addListener(_recalculateFeesDebounced);
    _recalculateFees(1.0); // Initial check for limits
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

  // Logic is retained for validation (limits, funds check)
  Future<void> _recalculateFees(double amount) async {
    if (amount <= 0 && amount != 1.0) {
      setState(() { _calculatedFee = 0.0; _totalDebitAmount = 0.0; _calculationError = null; });
      return;
    }

    setState(() { _isCalculating = true; _calculationError = null; });

    try {
      final details = await widget.bankingService.calculateTransferDetails(
        transferType: _selectedTransferType, amount: amount, sourceAccountNumber: widget.sourceAccount.accountNumber,
      );
      if (!mounted) return;
      setState(() {
        _calculatedFee = details['fee']!; _totalDebitAmount = details['totalDebit']!; _isCalculating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _calculationError = e.toString().split(': ').last; _calculatedFee = 0.0; _totalDebitAmount = 0.0; _isCalculating = false;
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
        transferType: _selectedTransferType,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: customLabelStyle ?? _labelStyle.copyWith(color: Colors.white70, fontSize: 15)),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: customValueStyle ?? _valueStyle.copyWith(color: valueColor ?? Colors.white, fontSize: 16))),
        ],
      ),
    );
  }

  // UPDATED: Attractive Source and Destination Card (Step 1)
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
                Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('FROM ACCOUNT', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            _buildDetailRow(
              widget.sourceAccount.nickname,
              'A/c: ${widget.bankingService.maskAccountNumber(widget.sourceAccount.accountNumber)}',
              valueColor: Colors.yellowAccent,
              customLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            _buildDetailRow('Current Balance', '₹${widget.sourceAccount.balance.toStringAsFixed(2)}', valueColor: Colors.white70),

            const Divider(height: 30, thickness: 1, color: Colors.white24),

            // --- TO Beneficiary ---
            Row(
              children: [
                Icon(Icons.send_to_mobile, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('TO BENEFICIARY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
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
              valueColor: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransferTypeSelector() {
    final externalTypes = TransferType.values.where((t) => t != TransferType.internal).toList();

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
                color: isSelected ? Colors.white : Colors.black87,
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
            _transferRules[_selectedTransferType] ?? 'Select a transfer type to view rules.',
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailsStep() {
    // Step 1: Amount, Type, Narration
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTransferTypeSelector(),

          // Amount Input
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryColor),
            decoration: InputDecoration(
              labelText: 'Amount to Transfer',
              hintText: '0.00',
              prefixText: '₹ ',
              prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _accentColor, width: 3), borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 15.0),
            ),
            validator: (value) {
              if (value == null || double.tryParse(value) == null || double.tryParse(value)! <= 0) return 'Enter a valid amount (Min. ₹1).';
              return null;
            },
          ),
          const SizedBox(height: 15),

          // Narration Input
          TextFormField(
            controller: _narrationController, maxLength: 50,
            decoration: InputDecoration(
              labelText: 'Narration / Remarks (Optional)',
              hintText: 'e.g., Monthly Rent Payment',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor, width: 2), borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),

          // Display calculation error if any
          if (_isCalculating) Center(child: LinearProgressIndicator(color: _accentColor)),
          if (_calculationError != null)
            Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red)),
                child: Text('Validation Error: $_calculationError', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            ),

          const SizedBox(height: 10),

          // Proceed Button (Matching AppBar color)
          ElevatedButton.icon(
            onPressed: _isCalculating || _amountController.text.isEmpty || _calculationError != null ? null : _confirmTransfer,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text('Proceed to Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 8,
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    // Step 2: Final Summary and T-PIN entry
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    // Using Builder to wrap scrollable content and button
    return Builder(
        builder: (context) {
          // Calculate bottom padding dynamically to ensure scrollability above the fixed button
          final bottomPadding = MediaQuery.of(context).padding.bottom;

          return Stack(
            children: [
              // Scrollable Content Area
              SingleChildScrollView(
                // IMPORTANT: Add extra padding for the fixed button and device bottom bar
                padding: EdgeInsets.only(
                    top: 5,
                    bottom: 120 + bottomPadding, // 120 is enough space for the fixed button + extra padding
                    left: 0,
                    right: 0
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Transaction Summary Card (Focus on transaction details only) ---
                    Card(
                      elevation: 4,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: _primaryColor.withOpacity(0.1))),
                      child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.receipt_long, color: _primaryColor),
                                  SizedBox(width: 8),
                                  Text('Transaction Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryColor)),
                                ],
                              ),
                              const Divider(color: Colors.black12, height: 25),

                              _buildDetailRow(
                                  'Amount',
                                  '₹${amount.toStringAsFixed(2)}',
                                  valueColor: _primaryColor,
                                  customLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                                  customValueStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _primaryColor)
                              ),
                              _buildDetailRow(
                                'Type',
                                _selectedTransferType.name.toUpperCase(),
                                valueColor: Colors.black87,
                                customLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                              ),
                              _buildDetailRow(
                                'Remarks',
                                _narrationController.text.isEmpty ? '(No remarks)' : _narrationController.text,
                                valueColor: Colors.black87,
                                customLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87),
                              ),

                              // Displaying where the money is going for final clarity
                              const Divider(color: Colors.black12, height: 25),
                              Text('Transferring to: ${widget.beneficiary.nickname} (${widget.bankingService.maskAccountNumber(widget.beneficiary.accountNumber)})',
                                  style: const TextStyle(fontSize: 14, color: Colors.black54)),
                            ],
                          )
                      ),
                    ),
                    const SizedBox(height: 40),

                    // --- T-PIN Entry Area ---
                    Center(
                      child: Text('Enter $_tpinLength-Digit Transaction PIN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryColor)),
                    ),
                    const SizedBox(height: 15),

                    // UPDATED T-PIN Input Field (6 Digits)
                    Center(
                      child: SizedBox(
                        width: 300,
                        child: TextFormField(
                          controller: _tpinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          textAlign: TextAlign.center,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_tpinLength)],
                          style: TextStyle(fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.w900, color: _primaryColor),
                          decoration: InputDecoration(
                            hintText: List.filled(_tpinLength, '*').join(), // e.g., "******"
                            counterText: '',
                            filled: true,
                            fillColor: _primaryColor.withOpacity(0.05),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _accentColor, width: 3)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Go Back/Cancel Button (Kept in scrollable area)
                    TextButton(
                        onPressed: () { setState(() => _showConfirmation = false); },
                        child: Text('Cancel / Go Back to Edit Details', style: TextStyle(color: _primaryColor, fontSize: 16))),
                  ],
                ),
              ),

              // --- Fixed Bottom Payment Button (Standard Banking App Look) ---
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 15, 20, 15 + bottomPadding), // Add device bottom padding here
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 5)],
                  ),
                  child: _isTransferring
                      ? Center(child: CircularProgressIndicator(color: _successColor))
                      : ElevatedButton.icon(
                    onPressed: _tpinController.text.length == _tpinLength ? _submitTransfer : null,
                    icon: const Icon(Icons.lock_open_rounded, size: 24),
                    label: const Text('CONFIRM TRANSACTION & PAY'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _successColor, // Unique Success Color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      disabledBackgroundColor: Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
            ],
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showConfirmation ? 'Confirm Transaction' : 'Fund Transfer Details'),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _showConfirmation
          ? _buildConfirmationStep() // Confirmation Step handles its own scrolling/layout
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prominent Display of Source and Destination
            _buildTransferSummaryCard(),

            // Details Step
            _buildDetailsStep(),

            // IMPORTANT: Ensure the scrollable content has extra space at the bottom
            // to avoid the content being clipped by system UI.
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }
}