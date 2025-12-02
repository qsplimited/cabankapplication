// File: cheque_request_review_screen.dart (Finalized Design with T-PIN Verification)

import 'package:flutter/material.dart';
// Import dependencies from the project structure
import '../api/cheque_service.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

// Initialize the service
final ChequeService _chequeService = ChequeService();

// Define a placeholder screen to navigate back to (assuming it's named 'ServicesManagementScreen')
// Since we don't have the actual services screen, we'll use a generic placeholder.
class ServicesManagementScreen extends StatelessWidget {
  const ServicesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Services Management')),
      body: const Center(child: Text('Returned to Services Screen.')),
    );
  }
}

class ChequeRequestReviewScreen extends StatefulWidget {
  // Data passed from the previous screen
  final Account account;
  final int leaves;
  final int quantity;
  final String deliveryAddress;
  final String? reason;
  final double totalFee; // Calculated fee passed for UI consistency

  const ChequeRequestReviewScreen({
    super.key,
    required this.account,
    required this.leaves,
    required this.quantity,
    required this.deliveryAddress,
    this.reason,
    required this.totalFee,
  });

  @override
  State<ChequeRequestReviewScreen> createState() => _ChequeRequestReviewScreenState();
}

class _ChequeRequestReviewScreenState extends State<ChequeRequestReviewScreen> {
  bool _isSubmitting = false;

  // Mock T-PIN for local validation (Replace this with a real API call)
  static const String _mockCorrectTpin = "123456";

  // Checks if the request is free for display purposes
  bool get _isFirstRequestFree {
    return _chequeService.isFirstRequest(widget.account.accountNo);
  }

  // ====================================================================
  // 1. T-PIN VALIDATION DIALOG (Redesigned with Auto-Focus Fix)
  // ====================================================================

  void _showTpinDialog() {
    // Controllers and Focus Nodes for 6 separate T-PIN fields
    final List<TextEditingController> tpinControllers = List.generate(6, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
    final formKey = GlobalKey<FormState>();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) {
        bool isVerifying = false;

        return StatefulBuilder(
          builder: (context, setStateInDialog) {
            return AlertDialog(
              title: const Text('Confirm Transaction'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Please enter your 6-digit T-PIN to authorize this request.'),
                    const SizedBox(height: kPaddingLarge),

                    // T-PIN Input Row with auto-advance logic
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(6, (index) {
                        return SizedBox(
                          width: 40,
                          child: TextFormField(
                            controller: tpinControllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            maxLength: 1, // Only one character per box
                            decoration: InputDecoration(
                              counterText: "",
                              contentPadding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.4), width: 2),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: colorScheme.primary, width: 3),
                              ),
                            ),
                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                            onChanged: (value) {
                              if (value.length == 1) {
                                // Automatically move focus to the next field
                                if (index < 5) {
                                  FocusScope.of(context).requestFocus(focusNodes[index + 1]);
                                } else {
                                  // Last field, dismiss keyboard
                                  FocusScope.of(context).unfocus();
                                }
                              } else if (value.isEmpty && index > 0) {
                                // If the user deletes a digit, move focus back to the previous field
                                FocusScope.of(context).requestFocus(focusNodes[index - 1]);
                              }
                            },
                            validator: (value) => (value == null || value.isEmpty) ? '' : null,
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () async {
                    // Manually check if all fields have input (since validate() on an empty textfield returns null, not false)
                    bool allValid = tpinControllers.every((c) => c.text.length == 1);

                    if (allValid) {
                      // Ensure validation runs on the form key for visual feedback on boxes
                      if (!formKey.currentState!.validate()) {
                        return;
                      }

                      setStateInDialog(() {
                        isVerifying = true;
                      });

                      // Combine the 6 inputs into a single T-PIN string
                      final submittedTpin = tpinControllers.map((c) => c.text).join();

                      // --- MOCK T-PIN VALIDATION LOGIC ---
                      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
                      final isTpinCorrect = submittedTpin == _mockCorrectTpin;
                      // --- END MOCK T-PIN VALIDATION LOGIC ---

                      setStateInDialog(() {
                        isVerifying = false;
                      });

                      if (isTpinCorrect) {
                        Navigator.of(context).pop(); // Close the dialog
                        _finalizeRequest(); // Proceed to API submission
                      } else {
                        // T-PIN is incorrect
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('❌ Authorization failed: Incorrect T-PIN.'),
                          backgroundColor: kErrorRed,
                          duration: Duration(seconds: 3),
                        ));
                        // Clear all fields for security and retry
                        for (var controller in tpinControllers) {
                          controller.clear();
                        }
                        FocusScope.of(context).requestFocus(focusNodes.first);
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Please enter all 6 digits of your T-PIN.'),
                        backgroundColor: kWarningYellow,
                        duration: Duration(seconds: 2),
                      ));
                      // Request focus on the first empty field
                      final firstEmptyIndex = tpinControllers.indexWhere((c) => c.text.isEmpty);
                      if (firstEmptyIndex != -1) {
                        FocusScope.of(context).requestFocus(focusNodes[firstEmptyIndex]);
                      }
                    }
                  },
                  child: isVerifying
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: kLightSurface)
                  )
                      : const Text('CONFIRM'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ====================================================================
  // 2. REQUEST SUBMISSION (Includes Navigation Fix)
  // ====================================================================

  void _finalizeRequest() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final refId = await _chequeService.submitChequeBookRequest(
        accountNo: widget.account.accountNo,
        leaves: widget.leaves,
        quantity: widget.quantity,
        deliveryAddress: widget.deliveryAddress,
        reason: widget.reason,
      );

      if (mounted) {
        // Success Feedback
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Cheque Book Request Submitted! Ref ID: $refId.'),
          backgroundColor: kSuccessGreen,
          duration: const Duration(seconds: 4),
        ));

        // Navigation Fix: Navigate back to the Services Management Screen/Dashboard
        // by popping all routes until the first one (the root/dashboard).
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        // Error Feedback
        String errorMessage = e.toString().split(':').last.trim();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Request failed: $errorMessage'),
          backgroundColor: kErrorRed,
          duration: const Duration(seconds: 5),
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ====================================================================
  // 3. WIDGET BUILDERS (Unchanged helpers)
  // ====================================================================

  // Helper for displaying a single detail row
  Widget _buildDetailRow(String label, String value, ColorScheme colorScheme, TextTheme textTheme, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kPaddingSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: kLabelColumnWidth,
            child: Text(
              label,
              style: textTheme.bodyMedium!.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: kPaddingMedium),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.titleSmall!.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom attractive Fee Summary Card
  Widget _buildFeeSummary(ColorScheme colorScheme, TextTheme textTheme) {
    final bool isFree = _isFirstRequestFree;
    final double feeBeforeGst = isFree ? 0.0 : widget.totalFee / 1.18;
    final double gstAmount = isFree ? 0.0 : widget.totalFee - feeBeforeGst;

    return Card(
      elevation: kCardElevation * 2,
      color: isFree ? kSuccessGreen.withOpacity(0.1) : colorScheme.error.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kRadiusSmall),
        side: BorderSide(color: isFree ? kSuccessGreen : kErrorRed.withOpacity(0.7), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Debit Details',
                style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)
            ),
            const Divider(height: kPaddingMedium),

            if (isFree)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                child: Center(
                  child: Text(
                    'NO CHARGE: First Book is FREE!',
                    style: textTheme.headlineMedium!.copyWith(color: kSuccessGreen, fontWeight: FontWeight.w900, fontSize: 24),
                  ),
                ),
              )
            else ...[
              _buildDetailRow('Book Charge (${widget.leaves} leaves x ${widget.quantity})', '₹${feeBeforeGst.toStringAsFixed(2)}', colorScheme, textTheme),
              _buildDetailRow('GST (18% Mock)', '₹${gstAmount.toStringAsFixed(2)}', colorScheme, textTheme),
              const Divider(height: kPaddingMedium),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Total amount debited',
                    style: textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold)
                ),
                Text(
                  isFree ? '₹0.00' : '₹${widget.totalFee.toStringAsFixed(2)}',
                  style: textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isFree ? kSuccessGreen : kErrorRed,
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================================
  // 4. MAIN BUILD METHOD
  // ====================================================================

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        title: Text('Review Cheque Request', style: textTheme.titleLarge!.copyWith(color: colorScheme.onPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Text('Please review all details and confirm the fee before proceeding.', style: textTheme.bodyLarge),
                  const SizedBox(height: kPaddingLarge),

                  // 1. Transaction Details Card
                  Card(
                    elevation: kCardElevation,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                    child: Padding(
                      padding: const EdgeInsets.all(kPaddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                              'Account to Debit',
                              '${widget.account.accountName} (...${widget.account.accountNo.substring(widget.account.accountNo.length - 4)})',
                              colorScheme,
                              textTheme,
                              valueColor: colorScheme.secondary
                          ),
                          const Divider(height: kPaddingSmall, color: kLightDivider),
                          _buildDetailRow('Cheque Leaves', '${widget.leaves}', colorScheme, textTheme),
                          _buildDetailRow('Quantity', '${widget.quantity}', colorScheme, textTheme),
                          const Divider(height: kPaddingSmall, color: kLightDivider),

                          // Delivery Method Detail Block
                          _buildDetailRow('Delivery Method', widget.deliveryAddress.split(':').first, colorScheme, textTheme),

                          // Sub-text for full address (Crucial for user verification)
                          Padding(
                            padding: const EdgeInsets.only(left: kPaddingMedium, bottom: kPaddingSmall, top: kPaddingSmall),
                            child: Text(
                              'Full Address: ${widget.deliveryAddress.split(':').last.trim()}',
                              style: textTheme.bodySmall!.copyWith(color: colorScheme.onSurface.withOpacity(0.5), fontStyle: FontStyle.italic),
                              textAlign: TextAlign.left,
                            ),
                          ),

                          if (widget.reason != null && widget.reason!.isNotEmpty)
                            _buildDetailRow('Reason', widget.reason!, colorScheme, textTheme),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: kPaddingLarge),

                  // 2. Fee Summary (Prominent Block)
                  _buildFeeSummary(colorScheme, textTheme),
                  const SizedBox(height: kPaddingLarge),
                ],
              ),
            ),

            // 3. Confirm Button (Calls the T-PIN dialog first)
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _showTpinDialog, // <-- CALLS DIALOG
                child: _isSubmitting
                    ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3, color: kLightSurface)
                )
                    : const Text(
                  'Confirm & Submit (Requires T-PIN)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: kPaddingMedium),
          ],
        ),
      ),
    );
  }
}