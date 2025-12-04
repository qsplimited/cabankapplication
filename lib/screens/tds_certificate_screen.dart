// File: lib/screens/tds_certificate_screen.dart

import 'package:flutter/material.dart';
import '../api/tds_services.dart';
import '../theme/app_colors.dart'; //
import '../theme/app_dimensions.dart'; //

// Data model for mock accounts
class Account {
  final String id;
  final String type;
  final String lastFour;

  Account(this.id, this.type, this.lastFour);

  @override
  String toString() => '$type A/c xxxx $lastFour';
}

class TdsCertificateScreen extends StatefulWidget {
  const TdsCertificateScreen({super.key});

  @override
  State<TdsCertificateScreen> createState() => _TdsCertificateScreenState();
}

class _TdsCertificateScreenState extends State<TdsCertificateScreen> {
  // --- MOCK DATA ---
  final List<Account> availableAccounts = [
    Account('A001', 'Savings', '1234'),
    Account('A002', 'Fixed Deposit', '9876'),
    Account('A003', 'Current', '5555'),
  ];
  final List<String> financialYears = ['2024-2025', '2023-2024', '2022-2023'];
  final String registeredEmail = 'user@registeredemail.com';

  // --- STATE ---
  Account? selectedAccount;
  String? selectedYear;
  String? statusMessage;
  bool isProcessing = false;

  final TdsService _documentService = TdsService();

  @override
  void initState() {
    super.initState();
    selectedAccount = availableAccounts.first;
    selectedYear = financialYears.first;
  }

  // 1. Handles the entire request after TPIN is successfully entered
  Future<void> _handleRequest(String tpin) async {
    if (selectedAccount == null || selectedYear == null) return;

    setState(() {
      isProcessing = true;
      statusMessage = 'Requesting TDS Certificate...';
    });

    try {
      final result = await _documentService.tdsCertificateRequest(
        accountId: selectedAccount!.id,
        financialYear: selectedYear!,
        tpin: tpin,
      );

      setState(() {
        isProcessing = false;
        String resultStatus = result['status'] as String;
        String resultMessage = result['message'] as String;

        if (resultStatus == 'success') {
          // Confirms that the system is ready for download after success
          statusMessage = '✅ Success! $resultMessage \n\n'
              'A copy has also been sent to $registeredEmail.';
        } else {
          statusMessage = '❌ Request Failed. $resultMessage';
        }
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
        statusMessage = '❌ An unexpected error occurred: $e';
      });
    }
  }

  // 2. Initiates the security dialog
  void _openTpinDialog() {
    if (selectedAccount == null || selectedYear == null) {
      setState(() {
        statusMessage = 'Please select both an Account and a Financial Year first.';
      });
      return;
    }

    setState(() => statusMessage = null);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TpinInputDialog(
          onTpinConfirmed: (tpin) {
            Navigator.of(context).pop();
            _handleRequest(tpin);
          },
        );
      },
    );
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = statusMessage?.contains('Success') == true;
    final Color statusColor = isSuccess ? kSuccessGreen : kErrorRed; //
    bool isFormValid = selectedAccount != null && selectedYear != null && !isProcessing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TDS Certificate Request'),
        backgroundColor: kAccentOrange, //
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Processing Indicator (Top of the screen)
          if (isProcessing)
            const LinearProgressIndicator(color: kAccentOrange), //

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kPaddingMedium), //
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Select the account and financial year to receive your Form 16A (TDS on Interest).',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: kPaddingLarge), //

                  // --- SECTION 1: DOCUMENT DETAILS (Card for structured design) ---
                  _buildSectionCard(
                    context,
                    title: 'DOCUMENT DETAILS',
                    children: [
                      _buildDetailRow(
                        context,
                        label: 'Certificate Type',
                        value: 'Form 16A (TDS on Interest Income)',
                      ),
                      const Divider(height: kPaddingMedium, color: kLightDivider), //,

                      _buildDropdownField<Account>(
                        context,
                        label: 'Account Number',
                        value: selectedAccount,
                        items: availableAccounts,
                        hint: 'Select Account',
                        onChanged: (Account? newValue) {
                          setState(() {
                            selectedAccount = newValue;
                            statusMessage = null;
                          });
                        },
                        itemBuilder: (Account item) => Text(item.toString()),
                      ),

                      _buildDropdownField<String>(
                        context,
                        label: 'Financial Year (FY)',
                        value: selectedYear,
                        items: financialYears,
                        hint: 'Select Year',
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedYear = newValue;
                            statusMessage = null;
                          });
                        },
                        itemBuilder: (String item) => Text('FY $item'),
                      ),
                    ],
                  ),

                  const SizedBox(height: kPaddingLarge), //

                  // --- SECTION 2: DELIVERY & HINT (Card for structured design) ---
                  _buildSectionCard(
                    context,
                    title: 'DELIVERY & SECURITY',
                    children: [
                      _buildDetailRow(
                        context,
                        label: 'Auto-Send Copy',
                        value: registeredEmail,
                        icon: Icons.email_outlined,
                      ),
                      const Divider(height: kPaddingMedium, color: kLightDivider), //,

                      // Password Hint - Nicely designed with accent colors
                      _buildPasswordHint(context),
                    ],
                  ),

                  const SizedBox(height: kPaddingLarge), //

                  // --- 3. Status/Result Message ---
                  if (statusMessage != null && !isProcessing)
                    Container(
                      padding: const EdgeInsets.all(kPaddingSmall), //
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(kRadiusSmall), //
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // --- 4. ACTION BUTTON (Sticky at the bottom) ---
          Padding(
            padding: const EdgeInsets.all(kPaddingMedium), //
            child: ElevatedButton(
              onPressed: isFormValid ? _openTpinDialog : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, kButtonHeight), //
                backgroundColor: kAccentOrange, //
                foregroundColor: kBrandNavy, //
              ),
              child: isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kBrandNavy))
                  : Text('DOWNLOAD CERTIFICATE', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: kBrandNavy)),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------
// SHARED WIDGETS (Design helpers)
// -----------------------------------------------------------------

Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
  return Card(
    elevation: kCardElevation, //
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(kRadiusMedium), //
    ),
    child: Padding(
      padding: const EdgeInsets.all(kPaddingMedium), //
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: kBrandLightBlue, //
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Divider(color: kLightDivider), //
          ...children,
        ],
      ),
    ),
  );
}

Widget _buildDetailRow(BuildContext context, {required String label, required String value, IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: kPaddingSmall / 2), //
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: kPaddingSmall), //
            child: Icon(icon, size: kIconSizeSmall, color: kBrandLightBlue), //,
          ),
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: kLightTextSecondary), //
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

Widget _buildDropdownField<T>(
    BuildContext context, {
      required String label,
      required T? value,
      required List<T> items,
      required String hint,
      required ValueChanged<T?> onChanged,
      required Widget Function(T) itemBuilder,
    }) {
  return Padding(
    padding: const EdgeInsets.only(bottom: kPaddingMedium), //
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: kPaddingExtraSmall), //
        DropdownButtonFormField<T>(
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: kPaddingSmall, vertical: kPaddingTen), //
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(kRadiusSmall), //
            ),
          ),
          value: value,
          hint: Text(hint),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: itemBuilder(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

Widget _buildPasswordHint(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(kPaddingSmall), //
    decoration: BoxDecoration(
      color: kAccentOrange.withOpacity(0.1), //
      borderRadius: BorderRadius.circular(kRadiusSmall), //
      border: Border.all(color: kAccentOrange), //
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, color: kAccentOrange, size: kIconSize), //,
        const SizedBox(width: kPaddingSmall), //
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PDF Password Hint (Crucial)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: kAccentOrange, //
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: kPaddingExtraSmall), //
              Text(
                'The downloaded PDF is secured. Password format is: \n'
                    '**[First 4 letters of PAN (CAPS)]** + **[Date of Birth (DDMMYYYY)]**',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// -----------------------------------------------------------------
// TPIN INPUT DIALOG WIDGET (Fixed Pin Slot Design)
// -----------------------------------------------------------------

class TpinInputDialog extends StatefulWidget {
  final ValueChanged<String> onTpinConfirmed;

  const TpinInputDialog({
    super.key,
    required this.onTpinConfirmed,
  });

  @override
  State<TpinInputDialog> createState() => _TpinInputDialogState();
}

class _TpinInputDialogState extends State<TpinInputDialog> {
  static const int _tpinLength = 6;
  final List<TextEditingController> _controllers = List.generate(_tpinLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_tpinLength, (_) => FocusNode());
  bool _isTpinLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onPinChange(String value, int index) {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
    if (value.length == 1 && index < _tpinLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    if (index == _tpinLength - 1 && value.length == 1) {
      _submitTpin();
    }
  }

  // FIX APPLIED HERE
  void _submitTpin() {
    // Collect, join, and TRIM the digits to ensure a perfect string match.
    final tpin = _controllers.map((c) => c.text).join().trim();

    if (tpin.length != _tpinLength) {
      setState(() {
        _errorMessage = 'Please enter all $_tpinLength digits.';
      });
      return;
    }

    setState(() => _isTpinLoading = true);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.onTpinConfirmed(tpin);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusMedium), //
      ),
      title: Text(
        'Authorize Download',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: kBrandNavy), //
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Please enter your $_tpinLength-digit Transaction PIN (TPIN) to authorize the download of your sensitive tax document.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: kPaddingMedium), //

            // TPIN Input Boxes (The "------" design pattern)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tpinLength, (index) {
                return SizedBox(
                  width: 40,
                  child: TextFormField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    obscureText: true,
                    textAlign: TextAlign.center,
                    enabled: !_isTpinLoading,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: kPaddingMedium), //
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kRadiusSmall), //
                        borderSide: const BorderSide(color: kLightTextSecondary), //
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(kRadiusSmall), //
                        borderSide: const BorderSide(color: kAccentOrange, width: 2.0), //
                      ),
                    ),
                    onChanged: (value) => _onPinChange(value, index),
                  ),
                );
              }),
            ),
            const SizedBox(height: kPaddingSmall), //

            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kErrorRed), //
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isTpinLoading ? null : () => Navigator.of(context).pop(),
          child: Text('CANCEL', style: TextStyle(color: kBrandNavy)), //
        ),
        ElevatedButton(
          onPressed: _isTpinLoading ? null : _submitTpin,
          style: ElevatedButton.styleFrom(
            backgroundColor: kAccentOrange, //
            foregroundColor: kBrandNavy, //
          ),
          child: _isTpinLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: kBrandNavy)) //
              : const Text('CONFIRM'),
        ),
      ],
    );
  }
}