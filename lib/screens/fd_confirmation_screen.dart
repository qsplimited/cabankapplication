import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/fd_api_service.dart';
import '../models/fd_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'fd_result_screen.dart';

// -----------------------------------------------------------------------------
// Utility extension for title casing scheme names
// -----------------------------------------------------------------------------
extension StringExtension on String {
  String titleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

// -----------------------------------------------------------------------------
// Main Widget
// -----------------------------------------------------------------------------

class FdConfirmationScreen extends StatefulWidget {
  final FdApiService apiService;
  final FdInputData inputData;
  final MaturityDetails maturityDetails;

  const FdConfirmationScreen({
    super.key,
    required this.apiService,
    required this.inputData,
    required this.maturityDetails,
  });

  @override
  State<FdConfirmationScreen> createState() => _FdConfirmationScreenState();
}

class _FdConfirmationScreenState extends State<FdConfirmationScreen> {
  bool _isConfirming = false;

  // Helper widget to display a single detail row
  Widget _buildDetailRow(BuildContext context, String label, String value, {Color? valueColor, TextStyle? valueStyle, bool isHighlight = false}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final valueTextStyle = valueStyle ?? textTheme.titleMedium?.copyWith(
      fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
      color: valueColor ?? colorScheme.onSurface,
    );

    final labelTextStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface.withOpacity(0.7),
      fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPaddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: labelTextStyle,
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: valueTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  // Handles the final T-PIN confirmation and navigates to the result screen
  Future<void> _handleConfirmDeposit(String tpin) async {
    if (_isConfirming || tpin.length != 6) return;

    // Set confirming state
    if (mounted) {
      setState(() => _isConfirming = true);
    }

    try {
      final response = await widget.apiService.confirmDeposit(
        tpin: tpin,
        amount: widget.inputData.amount,
        accountId: widget.inputData.sourceAccount.accountNumber,
      );

      if (!mounted) return;
      // Navigate to the result screen on success/API completion
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FdResultScreen(response: response),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Navigate to result screen with a generic failure response after error
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FdResultScreen(
            response: FdConfirmationResponse(
              success: false,
              message: 'Transaction failed due to network error or server issue: ${e.toString()}',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isConfirming = false);
      }
    }
  }

  // Shows the T-PIN input dialog using the new isolated widget
  void _showTpinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TpinInputDialog(),
    ).then((result) {
      // Check if the result is a valid T-PIN.
      if (result is String && result.length == 6) {
        final tpin = result;

        // CRITICAL FIX: Schedule the API call/state update for the next frame.
        // This is a safety measure to ensure the main widget tree is settled
        // after the dialog is completely closed and its resources are gone.
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleConfirmDeposit(tpin);
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final input = widget.inputData;
    final maturity = widget.maturityDetails;

    // Formatting tenure string
    final tenureString = (input.tenureYears > 0 ? '${input.tenureYears}Y ' : '') +
        (input.tenureMonths > 0 ? '${input.tenureMonths}M ' : '') +
        (input.tenureDays > 0 ? '${input.tenureDays}D' : '');

    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Deposit', style: textTheme.titleLarge?.copyWith(color: kLightSurface)),
        backgroundColor: colorScheme.primary,
        iconTheme: const IconThemeData(color: kLightSurface),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General FD Details Section
            Text('Deposit Summary', style: textTheme.titleLarge?.copyWith(color: kBrandNavy, fontWeight: FontWeight.bold)),
            const Divider(height: kDividerHeight * 2),

            Card(
              elevation: kCardElevation,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
              child: Padding(
                padding: const EdgeInsets.all(kPaddingMedium),
                child: Column(
                  children: [
                    _buildDetailRow(context, 'Scheme Name', input.selectedScheme.name.titleCase()),
                    _buildDetailRow(context, 'Interest Rate', '${input.selectedScheme.interestRate.toStringAsFixed(2)}% p.a.'),
                    _buildDetailRow(context, 'Deposit Tenure', tenureString.trim()),
                    _buildDetailRow(context, 'Source Account', input.sourceAccount.accountNumber),
                    _buildDetailRow(context, 'Nominee', input.selectedNominee),
                  ],
                ),
              ),
            ),
            const SizedBox(height: kPaddingXXL),

            // Maturity Details Section
            Text('Interest & Maturity Details', style: textTheme.titleLarge?.copyWith(color: kBrandNavy, fontWeight: FontWeight.bold)),
            const Divider(height: kDividerHeight * 2),

            Card(
              elevation: kCardElevation,
              color: kInfoBlue.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
              child: Padding(
                padding: const EdgeInsets.all(kPaddingMedium),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      'Principal Amount',
                      '₹${maturity.principalAmount.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      context,
                      'Total Interest Earned',
                      '₹${maturity.interestEarned.toStringAsFixed(2)}',
                      valueColor: kSuccessGreen,
                    ),
                    const Divider(height: kDividerHeight * 2),
                    _buildDetailRow(
                      context,
                      'Maturity Date',
                      maturity.maturityDate,
                      valueStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: kBrandNavy),
                      isHighlight: true,
                    ),
                    _buildDetailRow(
                      context,
                      'Maturity Amount',
                      '₹${maturity.maturityAmount.toStringAsFixed(2)}',
                      valueStyle: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: kErrorRed),
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: kPaddingXXL),

            // Confirmation Button
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _showTpinDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kSuccessGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                  elevation: kCardElevation,
                ),
                child: Text(
                  _isConfirming ? 'AUTHORIZING...' : 'CONFIRM DEPOSIT',
                  style: textTheme.titleMedium?.copyWith(color: kLightSurface, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: kPaddingMedium),
            // Edit Details Button
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: OutlinedButton(
                onPressed: _isConfirming ? null : () => Navigator.of(context).pop(),
                child: const Text('EDIT DETAILS'),
              ),
            ),
            const SizedBox(height: kPaddingXXL),
          ],
        ),
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// CRITICAL FIX: New Isolated Widget for T-PIN Input and FocusNode Management
// -----------------------------------------------------------------------------

class TpinInputDialog extends StatefulWidget {
  const TpinInputDialog({super.key});

  @override
  State<TpinInputDialog> createState() => _TpinInputDialogState();
}

class _TpinInputDialogState extends State<TpinInputDialog> {
  // Create 6 controllers and 6 focus nodes for individual digit input
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    // Dispose all resources here, BEFORE the widget is removed from the tree.
    for (var node in _focusNodes) {
      // No need for try/catch or complicated logic, just standard disposal
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Combine all digits into a single string
  String get _currentTpin => _controllers.map((c) => c.text).join();
  bool get _isTpinComplete => _currentTpin.length == 6;


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
      title: Center(
        child: Text('Enter 6-digit T-PIN', style: textTheme.titleLarge?.copyWith(color: kBrandNavy)),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Please enter your Transaction PIN to authorize this fixed deposit creation.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: kPaddingLarge),

          // Custom T-PIN Input (6 separate fields with auto-advance)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) {
              return SizedBox(
                width: 40, // Small width for single digit box
                child: TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: kBrandNavy),
                  maxLength: 1, // Only one digit per field
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '', // Hide the length counter
                    contentPadding: const EdgeInsets.all(kPaddingSmall),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusExtraSmall),
                      borderSide: const BorderSide(color: kDarkTextSecondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(kRadiusExtraSmall),
                      borderSide: BorderSide(color: colorScheme.primary, width: 2),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {}); // Rebuild to check completeness
                    if (value.isNotEmpty && index < 5) {
                      // Auto-advance
                      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
                    } else if (value.isEmpty && index > 0) {
                      // Backspace
                      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
                    }
                  },
                ),
              );
            }),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false); // Pass false indicating CANCEL
          },
          child: Text('CANCEL', style: textTheme.labelLarge?.copyWith(color: kErrorRed)),
        ),
        ElevatedButton(
          onPressed: _isTpinComplete
              ? () {
            Navigator.of(context).pop(_currentTpin); // Pass the tpin string
          }
              : null, // Only enabled when 6 digits are entered
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
            elevation: kCardElevation,
          ),
          child: Text(
            'SUBMIT',
            style: textTheme.labelLarge?.copyWith(color: kLightSurface, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: kPaddingSmall),
      ],
    );
  }
}