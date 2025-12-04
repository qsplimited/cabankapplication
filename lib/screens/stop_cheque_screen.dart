// Path: lib/screens/stop_cheque_screen.dart (Corrected file)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/cheque_service.dart';
// Assuming the theme files are in these paths
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

// Helper function to format currency
String formatCurrency(double amount) {
  return '₹${amount.toStringAsFixed(2)}';
}

class StopChequeScreen extends StatefulWidget {
  const StopChequeScreen({super.key});

  @override
  State<StopChequeScreen> createState() => _StopChequeScreenState();
}

enum ChequeSelectionType { single, range }

class _StopChequeScreenState extends State<StopChequeScreen> {
  final ChequeService _chequeService = ChequeService();
  final _formKey = GlobalKey<FormState>();

  // State for Account and Request details
  List<Account> _eligibleAccounts = [];
  Account? _selectedAccount;
  String? _selectedReason;

  // State for Cheque Numbers
  ChequeSelectionType _selectionType = ChequeSelectionType.single;
  final TextEditingController _singleChequeController = TextEditingController();
  final TextEditingController _startChequeController = TextEditingController();
  final TextEditingController _endChequeController = TextEditingController();

  // State for Submission and Fees
  double _totalFee = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _singleChequeController.addListener(_calculateFee);
    _startChequeController.addListener(_calculateFee);
    _endChequeController.addListener(_calculateFee);
  }

  @override
  void dispose() {
    _singleChequeController.removeListener(_calculateFee);
    _startChequeController.removeListener(_calculateFee);
    _endChequeController.removeListener(_calculateFee);
    _singleChequeController.dispose();
    _startChequeController.dispose();
    _endChequeController.dispose();
    super.dispose();
  }

  Future<void> _fetchAccounts() async {
    setState(() { _isLoading = true; });
    try {
      final accounts = await _chequeService.fetchEligibleAccounts();
      setState(() {
        _eligibleAccounts = accounts;
        _selectedAccount = accounts.isNotEmpty ? accounts.first : null;
      });
      _calculateFee();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load accounts: ${e.toString()}';
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _calculateFee() {
    if (_selectedAccount == null) return;
    int chequeCount = 0;

    try {
      if (_selectionType == ChequeSelectionType.single) {
        if (_singleChequeController.text.length == 6 && int.tryParse(_singleChequeController.text) != null) {
          chequeCount = 1;
        }
      } else {
        final startCheque = int.tryParse(_startChequeController.text);
        final endCheque = int.tryParse(_endChequeController.text);
        if (startCheque != null && endCheque != null && endCheque >= startCheque && _startChequeController.text.length == 6 && _endChequeController.text.length == 6) {
          chequeCount = endCheque - startCheque + 1;
        }
      }
    } catch (_) {
      chequeCount = 0;
    }

    final newFee = _chequeService.getStopChequeFee(chequeCount);
    if (newFee != _totalFee) {
      setState(() {
        _totalFee = newFee;
      });
    }
  }

  // --- Submission Entry Point ---
  Future<void> _handleSubmission() async {
    if (!_formKey.currentState!.validate() || _selectedAccount == null || _selectedReason == null || _totalFee <= 0) {
      setState(() {
        _errorMessage = 'Please complete all required fields and ensure a valid cheque number/range is entered.';
      });
      return;
    }

    // --- STEP 1: T-Pin Verification (Calls the centralized service method) ---
    final bool tpinVerified = await _showTpinVerificationDialog(context);

    if (!tpinVerified) {
      // T-Pin was cancelled or failed verification
      return;
    }

    // --- STEP 2: Actual Service Submission (Only if T-Pin is verified) ---
    await _submitRequest();
  }

  // --- Core Service Submission Logic ---
  Future<void> _submitRequest() async {
    List<String> chequeNumbers = [];
    if (_selectionType == ChequeSelectionType.single) {
      chequeNumbers.add(_singleChequeController.text);
    } else {
      final start = int.tryParse(_startChequeController.text) ?? 0;
      final end = int.tryParse(_endChequeController.text) ?? 0;
      for (int i = start; i <= end; i++) {
        chequeNumbers.add(i.toString().padLeft(6, '0'));
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final referenceId = await _chequeService.submitStopChequeRequest(
        accountNo: _selectedAccount!.accountNo,
        chequeNumbers: chequeNumbers,
        reason: _selectedReason!,
      );

      _showResultModal(
        isSuccess: true,
        title: 'Cheque Payment Stopped',
        message: 'Your request to stop payment on ${chequeNumbers.length} cheques has been successfully processed. The fee of ${formatCurrency(_totalFee)} has been debited from your account.',
        referenceId: referenceId,
      );
      _resetForm();
    } on Exception catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      _showResultModal(
        isSuccess: false,
        title: 'Transaction Failed',
        message: errorMsg,
      );
      setState(() {
        _errorMessage = errorMsg;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _singleChequeController.clear();
    _startChequeController.clear();
    _endChequeController.clear();
    setState(() {
      _selectedReason = null;
      _totalFee = 0.0;
      _errorMessage = null;
      _calculateFee();
    });
  }


  // --- T-Pin Verification Modal Dialog (REUSABLE) ---
  Future<bool> _showTpinVerificationDialog(BuildContext context) async {
    final List<TextEditingController> controllers = List.generate(6, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
    bool isVerifying = false;
    String? tpinError;

    // Returns the boolean result of the verification
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setStateTpin) {
              final theme = Theme.of(context);

              // *** FIX: Declare submitTpin() BEFORE handleTpinInput() ***
              void submitTpin() async {
                final String tpin = controllers.map((c) => c.text).join();
                if (tpin.length != 6) {
                  setStateTpin(() {
                    tpinError = 'Please enter all 6 digits.';
                  });
                  return;
                }

                setStateTpin(() {
                  isVerifying = true;
                  tpinError = null;
                });

                // Calling the centralized service method
                final isSuccess = await _chequeService.verifyTpin(tpin);

                setStateTpin(() { isVerifying = false; });

                if (isSuccess) {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context).pop(true); // Success: Pop dialog with true result
                } else {
                  setStateTpin(() {
                    tpinError = 'Invalid T-Pin. Please try again. (Hint: Mock T-Pin is 123456)';
                  });
                  for (var c in controllers) { c.clear(); }
                  focusNodes.first.requestFocus();
                }
              }
              // **********************************************************


              void handleTpinInput(String value, int index) {
                if (value.length == 1 && index < 5) {
                  FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                } else if (value.isEmpty && index > 0) {
                  FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                }
                // Automatically submit if all 6 digits are entered
                if (controllers.every((c) => c.text.isNotEmpty)) {
                  submitTpin();
                }

                if (tpinError != null) {
                  setStateTpin(() { tpinError = null; });
                }
              }


              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
                title: Text('Enter 6-Digit T-Pin', style: theme.textTheme.titleLarge),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Enter your Transaction Pin to authorize the fee debit and request submission.', style: theme.textTheme.bodyMedium),
                    const SizedBox(height: kPaddingMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 40,
                          child: TextFormField(
                            controller: controllers[index],
                            focusNode: focusNodes[index],
                            obscureText: true,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            readOnly: isVerifying,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(
                              counterText: '',
                              contentPadding: EdgeInsets.symmetric(vertical: kPaddingMedium, horizontal: kPaddingExtraSmall),
                              hintText: '–',
                            ),
                            onChanged: (value) => handleTpinInput(value, index),
                          ),
                        );
                      }),
                    ),
                    if (tpinError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: kPaddingSmall),
                        child: Text(
                          tpinError!,
                          style: theme.textTheme.bodySmall?.copyWith(color: kErrorRed),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: isVerifying ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: isVerifying ? null : submitTpin,
                    child: isVerifying
                        ? SizedBox(
                      width: kIconSizeSmall,
                      height: kIconSizeSmall,
                      child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                    )
                        : const Text('Verify & Proceed'),
                  ),
                ],
              );
            });
      },
    ) ?? false;
  }

  // --- UI Builder Methods (Consistent with previous structure) ---

  Widget _buildAccountSelector(BuildContext context) {
    if (_eligibleAccounts.isEmpty && !_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(kPaddingMedium),
        child: Text('No eligible accounts for stop cheque service.'),
      );
    }
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Account', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: kPaddingSmall),
            DropdownButtonFormField<Account>(
              value: _selectedAccount,
              decoration: const InputDecoration(
                labelText: 'Account Number',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              isExpanded: true,
              items: _eligibleAccounts.map((account) {
                final lastFour = account.accountNo.length >= 4 ? account.accountNo.substring(account.accountNo.length - 4) : account.accountNo;
                return DropdownMenuItem<Account>(
                  value: account,
                  child: Text(
                    '${account.accountName} (****$lastFour) - ${formatCurrency(account.balance)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }).toList(),
              onChanged: (Account? newValue) {
                setState(() { _selectedAccount = newValue; });
                _calculateFee();
              },
              validator: (value) => value == null ? 'Please select an account' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChequeInputCard(BuildContext context) {
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cheque Details', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: kPaddingSmall),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<ChequeSelectionType>(
                    title: const Text('Single Cheque'),
                    value: ChequeSelectionType.single,
                    groupValue: _selectionType,
                    onChanged: (ChequeSelectionType? value) {
                      setState(() { _selectionType = value!; });
                      _calculateFee();
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: RadioListTile<ChequeSelectionType>(
                    title: const Text('Cheque Range'),
                    value: ChequeSelectionType.range,
                    groupValue: _selectionType,
                    onChanged: (ChequeSelectionType? value) {
                      setState(() { _selectionType = value!; });
                      _calculateFee();
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kPaddingSmall),
            _selectionType == ChequeSelectionType.single
                ? TextFormField(
              controller: _singleChequeController,
              decoration: const InputDecoration(
                labelText: 'Cheque Number (6 digits)',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
                hintText: 'e.g., 001234',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter a cheque number';
                if (value.length != 6 || int.tryParse(value) == null) return 'Must be a valid 6-digit number';
                return null;
              },
            )
                : Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startChequeController,
                    decoration: const InputDecoration(
                      labelText: 'Start Cheque No.',
                      hintText: 'e.g., 001234',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value.length != 6 || int.tryParse(value) == null) return '6-digit number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: kPaddingMedium),
                Expanded(
                  child: TextFormField(
                    controller: _endChequeController,
                    decoration: const InputDecoration(
                      labelText: 'End Cheque No.',
                      hintText: 'e.g., 001239',
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      if (value.length != 6 || int.tryParse(value) == null) return '6-digit number';
                      final start = int.tryParse(_startChequeController.text);
                      final end = int.tryParse(value);
                      if (start != null && end != null && end < start) {
                        return 'End must be >= Start';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonAndFeeCard(BuildContext context) {
    final theme = Theme.of(context);

    int count = 0;
    if (_selectionType == ChequeSelectionType.single && _singleChequeController.text.length == 6) {
      count = 1;
    } else if (_selectionType == ChequeSelectionType.range) {
      final start = int.tryParse(_startChequeController.text);
      final end = int.tryParse(_endChequeController.text);
      if (start != null && end != null && _startChequeController.text.length == 6 && _endChequeController.text.length == 6 && end >= start) {
        count = end - start + 1;
      }
    }

    final baseFee = count * ChequeService.kStopChequeFee;
    final gst = baseFee * ChequeService.kStopChequeGST;

    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedReason,
              decoration: const InputDecoration(
                labelText: 'Stop Cheque Reason',
                prefixIcon: Icon(Icons.help_outline),
              ),
              isExpanded: true,
              items: _chequeService.mockStopReasons.map((reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason, style: theme.textTheme.bodyMedium),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() { _selectedReason = newValue; });
              },
              validator: (value) => value == null ? 'Please select a reason' : null,
            ),
            const SizedBox(height: kPaddingMedium),
            Divider(color: theme.dividerColor),
            const SizedBox(height: kPaddingMedium),

            // Fee Breakdown Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cheques to be Stopped', style: theme.textTheme.bodyMedium),
                Text('$count', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: kPaddingExtraSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Base Fee (₹${ChequeService.kStopChequeFee.toStringAsFixed(2)}/cheque)', style: theme.textTheme.bodyMedium),
                Text(formatCurrency(baseFee), style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: kPaddingExtraSmall),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GST (${(ChequeService.kStopChequeGST * 100).toInt()}%)', style: theme.textTheme.bodyMedium),
                Text(formatCurrency(gst), style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: kPaddingSmall),
            Divider(color: theme.dividerColor),
            const SizedBox(height: kPaddingSmall),

            // Total Fee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Fee (Incl. GST)',
                  style: theme.textTheme.titleMedium,
                ),
                Text(
                  formatCurrency(_totalFee),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: kErrorRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kPaddingSmall),
            Text(
              'Service charges are defined by the bank\'s schedule of charges. This fee will be debited immediately upon authorization.',
              style: theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic, color: kLightTextSecondary),
            ),
            const SizedBox(height: kPaddingExtraSmall),
            if (_selectedAccount != null && _totalFee > 0)
              Text(
                'Fee will be debited from account balance: ${formatCurrency(_selectedAccount!.balance)}.',
                style: theme.textTheme.labelSmall?.copyWith(color: kWarningYellow),
              ),
          ],
        ),
      ),
    );
  }

  // Custom modal for success/error
  void _showResultModal({required bool isSuccess, required String title, required String message, String? referenceId}) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
          title: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? kSuccessGreen : kErrorRed,
                size: kIconSizeLarge,
              ),
              const SizedBox(width: kPaddingSmall),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(color: isSuccess ? kSuccessGreen : kErrorRed),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: theme.textTheme.bodyLarge),
              if (referenceId != null)
                Padding(
                  padding: const EdgeInsets.only(top: kPaddingMedium),
                  child: Text(
                    'Reference ID: $referenceId',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isButtonEnabled = !_isLoading && _selectedAccount != null && _selectedReason != null && _totalFee > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Stop Cheque Payment',
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        backgroundColor: kAccentOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && _eligibleAccounts.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildAccountSelector(context),
              const SizedBox(height: kPaddingMedium),
              _buildChequeInputCard(context),
              const SizedBox(height: kPaddingMedium),
              _buildReasonAndFeeCard(context),
              const SizedBox(height: kPaddingLarge),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: kPaddingMedium),
                  child: Text(
                    'Error: $_errorMessage!',
                    style: theme.textTheme.bodyMedium?.copyWith(color: kErrorRed),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Button
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + kPaddingMedium,
                ),
                child: ElevatedButton.icon(
                  onPressed: isButtonEnabled ? _handleSubmission : null, // Triggers T-Pin modal first
                  icon: _isLoading
                      ? SizedBox(
                    width: kIconSizeSmall,
                    height: kIconSizeSmall,
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.lock_open),
                  label: Text(
                    _isLoading ? 'Processing Request...' : 'Confirm Stop Payment',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, kButtonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    textStyle: theme.textTheme.labelLarge,
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