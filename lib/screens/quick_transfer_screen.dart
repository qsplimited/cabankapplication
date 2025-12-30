// File: lib/screens/quick_transfer_screen.dart (Final Corrected Version)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import local theme constants
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_sizes.dart'; // Contains AppSizes.paddingS, AppSizes.paddingM, etc.
// Assuming your banking_service.dart file is accessible via this path.
import '../api/banking_service.dart'; // Ensure this path is correct

// --- Service Initialization ---
final BankingService _bankingService = BankingService();

// Note: Removed hardcoded color constants, they are now accessed via Theme or app_colors.dart

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
      _showSnackBar('Failed to load accounts: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          // Use Theme Colors for SnackBar
          backgroundColor: isError ? Theme.of(context).colorScheme.error : kSuccessGreen,
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
      _showSnackBar(e.message, isError: true);
      setState(() {
        _isRecipientVerified = false;
        _recipientDetails = null;
        _resetTransactionState();
      });
    } catch (e) {
      _showSnackBar('Verification failed: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
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
      _showSnackBar('Please verify recipient details first.', isError: true);
      return;
    }

    // Force validation of Amount and Remarks fields before requesting OTP
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
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Error initiating transfer: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    } finally {
      setState(() => _isTransferring = false);
    }
  }

  // --- STEP 2: Submit Transfer with OTP ---
  Future<void> _submitTransfer() async {
    if (_transactionReference.isEmpty) {
      _showSnackBar('Transaction expired or not initiated. Please request OTP again.', isError: true);
      return;
    }

    if (_otpController.text.length != 6) {
      _showSnackBar('Please enter the 6-digit OTP.', isError: true);
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
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      _showSnackBar('Transfer failed: ${e.toString().replaceAll('Exception: ', '')}', isError: true);
    } finally {
      setState(() => _isTransferring = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    // Accessing theme data once
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_debitAccounts.isEmpty && !_isTransferring) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quick Transfer (IMPS)', style: textTheme.titleLarge?.copyWith(
            color: Colors.white, // Ensure text is white on orange
            fontWeight: FontWeight.bold,
          )),
          // APPLYING THE ACCENT ORANGE COLOR HERE
          backgroundColor: kAccentOrange,
          // Set icons (back button, etc.) to white
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true, // Optional: centers the title for a cleaner look
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kAccentOrange), // Match loader to theme
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Transfer (IMPS)'),
        // AppBar style is set in AppTheme, only explicitly overriding if needed.
        // Keeping it clean here.
      ),
      body: SingleChildScrollView(
        // UI FIX: Added bottom padding to prevent button overlap
        padding: const EdgeInsets.symmetric(horizontal: kPaddingMedium), // Use constant
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.only(
              top: kPaddingMedium, // Use constant
              // CRITICAL: Adds space equal to system navigation bar height
              bottom: kPaddingMedium + MediaQuery.of(context).padding.bottom, // Use constant
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Source Account Selection (Dropdown)
                _buildSourceAccountSelection(context),
                const SizedBox(height: kSpacingMedium), // Use constant

                // 2. Recipient Details
                Text('Recipient Details', style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSizes.paddingS), // CORRECTED: Used AppSizes.paddingS

                _buildTextField(
                  context,
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
                  context,
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
                  context,
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
                const SizedBox(height: AppSizes.paddingS), // CORRECTED: Used AppSizes.paddingS

                // 2.5 Recipient Verification Section
                if (!_isOtpRequested) ...[
                  if (_isRecipientVerified)
                    _buildRecipientVerificationStatus(context)
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isTransferring ? null : _verifyRecipient,
                        icon: _isTransferring ?
                        SizedBox(width: kIconSizeSmall, height: kIconSizeSmall, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2)) :
                        const Icon(Icons.verified_user_outlined),
                        label: Text(_isTransferring ? 'VERIFYING...' : 'VERIFY RECIPIENT'),
                        style: ElevatedButton.styleFrom(
                          // Using a semantic color (Accent Orange/Warning) for verification
                          backgroundColor: kAccentOrange,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: kPaddingMedium), // Use constant
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)), // Use constant
                        ),
                      ),
                    ),
                  const SizedBox(height: kSpacingMedium), // Use constant
                ],


                // 3. Amount and Remarks - Enabled only after verification
                Text('Transaction Details', style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSizes.paddingS), // CORRECTED: Used AppSizes.paddingS

                _buildTextField(
                    context,
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
                    context,
                    _remarksController,
                    'Remarks (Optional)',
                    Icons.notes,
                    null,
                    TextInputType.text,
                    isOptional: true,
                    enabled: !_isOtpRequested && !_isTransferring && _isRecipientVerified
                ),
                const SizedBox(height: kSpacingLarge), // Use constant

                // 4. OTP Authorization Section (Conditional)
                if (_isOtpRequested) ...[
                  Text('Authorization (6-digit OTP)', style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS), // CORRECTED: Used AppSizes.paddingS
                    child: Text('OTP sent to mobile ending in ******$_otpSentToMobileSuffix',
                        // Use a semantic color for OTP/Info message
                        style: textTheme.bodyMedium!.copyWith(color: kInfoBlue)),
                  ),
                  _buildTextField(
                    context,
                    _otpController,
                    'Enter 6-digit OTP',
                    Icons.lock_outline,
                        (value) => value!.length != 6 ? 'OTP must be 6 digits' : null,
                    TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: kSpacingMedium), // Use constant

                  // Submit Button (Step 2)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTransferring ? null : _submitTransfer,
                      style: ElevatedButton.styleFrom(
                        // Use Success Green for final transfer action
                        backgroundColor: kSuccessGreen,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: kPaddingMedium), // Use constant
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)), // Use constant
                        minimumSize: const Size(double.infinity, kButtonHeight), // Use constant
                      ),
                      child: _isTransferring
                          ? SizedBox(width: kIconSizeSmall, height: kIconSizeSmall, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2))
                          : Text('AUTHORIZE & TRANSFER', style: textTheme.labelLarge?.copyWith(fontSize: 16)), // Use textTheme
                    ),
                  ),

                ] else if (_isRecipientVerified) ...[
                  // Request OTP Button (Step 1) - Only available after verification
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTransferring ? null : _requestOtp,
                      // The style is automatically handled by the ElevatedButtonTheme defined in app_theme.dart,
                      // but explicitly setting it to Primary for clarity
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                        minimumSize: const Size(double.infinity, kButtonHeight),
                      ),
                      child: _isTransferring
                          ? SizedBox(width: kIconSizeSmall, height: kIconSizeSmall, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2))
                          : Text('PROCEED & REQUEST OTP', style: textTheme.labelLarge?.copyWith(fontSize: 16)),
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

  Widget _buildSourceAccountSelection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: kCardElevation, // Use constant
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)), // Use constant
      // Use the theme's background color with opacity for a subtle card
      color: colorScheme.background.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium), // Use constant
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DYNAMIC TITLE FIX: Display the selected account nickname
            Text(
              'Transfer From: ${_selectedSourceAccount?.nickname ?? 'Select Source Account'}',
              style: textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary // Use primary color for card title
              ),
            ),
            const Divider(),
            if (_debitAccounts.isEmpty)
              Text('Loading accounts or no debitable accounts found...', style: textTheme.bodyMedium)
            else
              DropdownButtonFormField<Account>(
                value: _selectedSourceAccount,
                decoration: InputDecoration(
                  labelText: 'Select Source Account',
                  // The input decoration theme is largely handled by AppTheme
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingS, vertical: kPaddingMedium), // CORRECTED: Used AppSizes.paddingS
                ),
                isExpanded: true,
                items: _debitAccounts.map((Account account) {
                  return DropdownMenuItem<Account>(
                    value: account,
                    child: Text(
                      '${account.nickname} (${_bankingService.maskAccountNumber(account.accountNumber)}) - ₹${account.balance.toStringAsFixed(2)}',
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium, // Use textTheme
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

  Widget _buildRecipientVerificationStatus(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isRecipientVerified && _recipientDetails != null) {
      return Card(
        // Use a light success color for verification status
        color: kSuccessGreen.withOpacity(0.05),
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusSmall), // Use constant
            side: BorderSide(color: kSuccessGreen, width: 1)
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.paddingM), // CORRECTED: Used AppSizes.paddingM
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recipient Verified ✅', style: textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold, color: kSuccessGreen)),
              const SizedBox(height: AppSizes.paddingXS), // Use constant
              Text('Name: ${_recipientDetails!['officialName']}', style: textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w500)),
              Text('Bank: ${_recipientDetails!['bankName']}', style: textTheme.labelSmall!.copyWith(color: colorScheme.onSurface.withOpacity(0.6))), // Use textTheme and theme color
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }


  Widget _buildTextField(
      BuildContext context,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.paddingM), // CORRECTED: Used AppSizes.paddingM
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
          prefixIcon: Icon(icon, color: colorScheme.primary.withOpacity(0.7)), // Use theme color
          // Input border/fill color/content padding are handled by AppTheme
          counterText: "",
          // Overriding AppTheme's fill property for disabled fields
          filled: !enabled,
          fillColor: !enabled ? (colorScheme.brightness == Brightness.light ? kInputBackgroundColor : colorScheme.surface.withOpacity(0.5)) : colorScheme.surface,
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

// Extension to safely parse string to double - Logic remains the same
extension on String {
  double? tryParseDouble() {
    return double.tryParse(this);
  }
}

// --- SUCCESS SCREEN (Refactored & Fixed) ---

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Complete'),
        // Use semantic color for success screen AppBar
        backgroundColor: kAccentOrange,
        foregroundColor: colorScheme.onPrimary, // White text/icons
        automaticallyImplyLeading: false, // Prevents back button on success
        elevation: 0, // Flat success screen
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            // Ensures content is scrollable if device is small
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding( // Added Padding widget to apply space around the content
                  padding: const EdgeInsets.all(AppSizes.paddingXL), // Using AppSizes.paddingXL (24.0)
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Success Icon
                      Icon(
                        Icons.check_circle_outline,
                        color: kSuccessGreen,
                        size: kIconSizeExtraLarge * 2, // Use constant (approx 90)
                      ),
                      // FIX: Replaced undefined kPaddingL with defined kPaddingLarge
                      const SizedBox(height: kPaddingLarge),

                      // Title
                      Text(
                        'Transfer Successful!',
                        textAlign: TextAlign.center,
                        style: textTheme.headlineMedium!.copyWith(
                          color: kSuccessGreen,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingXL), // Using AppSizes.paddingXL

                      // Transaction Details Card
                      Card(
                        // CardTheme properties are applied from app_theme.dart
                        child: Padding(
                          // FIX: Replaced undefined kPaddingL with defined kPaddingLarge
                          padding: const EdgeInsets.all(kPaddingLarge),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow(context, 'Amount:', '₹$amount'),
                              _buildDetailRow(context, 'To A/C:', _bankingService.maskAccountNumber(recipientAccount)),
                              _buildDetailRow(context, 'Reference ID:', transactionId),
                              _buildDetailRow(context, 'Time:', _formatDateTime(DateTime.now())),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(), // Pushes the button to the bottom

                      // Done Button
                      Padding(
                        padding: EdgeInsets.only(top: kPaddingLarge, bottom: MediaQuery.of(context).padding.bottom), // Use constant
                        child: ElevatedButton(
                          onPressed: () {
                            // Navigate back to the home screen (or previous context)
                            Navigator.of(context).pop();
                          },
                          // Use the theme's primary button style
                          style: Theme.of(context).elevatedButtonTheme.style,
                          child: Text('DONE', style: textTheme.labelLarge?.copyWith(fontSize: 18)), // Use textTheme
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

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingS), // CORRECTED: Used AppSizes.paddingS
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium!.copyWith(color: colorScheme.onSurface.withOpacity(0.6))), // Use textTheme and theme color
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold), // Use textTheme
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    // Basic formatting for presentation - Logic remains the same
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}