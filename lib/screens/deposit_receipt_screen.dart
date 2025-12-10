import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api/fd_api_service.dart';
import '../api/rd_api_service.dart';
import '../models/receipt_models.dart'; // REQUIRED: DepositReceipt model
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

// Helper function for currency formatting
String _formatCurrency(double amount) => '₹${NumberFormat('#,##0.00').format(amount)}';

// Using the user's preferred tighter spacing constants
const double kSpacingSmall = 8.0;
const double kSpacingMedium = 12.0;

// -----------------------------------------------------------------------------
// Main Widget
// -----------------------------------------------------------------------------

class DepositReceiptScreen extends StatefulWidget {
  final String transactionId;
  final String depositType; // 'FD' or 'RD'
  final FdApiService fdApiService;
  final RdApiService rdApiService;

  const DepositReceiptScreen({
    super.key,
    required this.transactionId,
    required this.depositType,
    required this.fdApiService,
    required this.rdApiService,
  });

  @override
  State<DepositReceiptScreen> createState() => _DepositReceiptScreenState();
}

class _DepositReceiptScreenState extends State<DepositReceiptScreen> {
  late Future<DepositReceipt> _receiptFuture;

  @override
  void initState() {
    super.initState();
    // Fetch receipt based on deposit type
    _receiptFuture = widget.depositType == 'FD'
        ? widget.fdApiService.fetchDepositReceipt(widget.transactionId)
        : widget.rdApiService.fetchDepositReceipt(widget.transactionId);
  }

  // Helper widget to build a clean, minimalist detail row
  Widget _buildDetailRow(
      BuildContext context,
      String label,
      String value, {
        Color valueColor = kBrandNavy,
        bool isHighlight = false,
      }) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      // Reduced vertical padding for tighter alignment
      padding: const EdgeInsets.symmetric(vertical: kPaddingExtraSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Label (Forced to single line, bodyMedium size)
          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 1, // Force single line
              softWrap: false,
              overflow: TextOverflow.ellipsis, // Truncate long text
              style: textTheme.bodyMedium?.copyWith(
                color: kLightTextSecondary,
              ),
            ),
          ),
          // Right side: Value (Aligned right, forced to single line)
          Expanded(
            flex: 5,
            child: Text(
              value,
              maxLines: 1, // Force single line
              softWrap: false,
              overflow: TextOverflow.ellipsis, // Truncate long text
              textAlign: TextAlign.right,
              style: isHighlight
                  ? textTheme.titleSmall?.copyWith( // Smaller text size
                color: valueColor,
                fontWeight: FontWeight.bold,
              )
                  : textTheme.bodyMedium?.copyWith( // Smaller text size
                color: valueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Placeholder actions (remain the same)
  void _handleShareReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing receipt... (Mock action)')),
    );
  }

  void _handleDownloadPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Downloading receipt as PDF... (Mock action)')),
    );
  }

  // --- Build Receipt View ---
  Widget _buildReceiptView(BuildContext context, DepositReceipt receipt) {
    final textTheme = Theme.of(context).textTheme;
    const Color statusColor = kSuccessGreen;
    final String amountLabel = widget.depositType == 'FD'
        ? 'Fixed Deposit Amount'
        : 'Monthly Installment';

    // Get the device's safe area padding for the bottom of the screen
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // 1. SCROLLABLE DETAILS AREA (The main content area)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kPaddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1A. TRANSACTION STATUS & AMOUNT CARD
                Card(
                  elevation: kCardElevation,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                  child: Padding(
                    padding: const EdgeInsets.all(kPaddingLarge),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: kIconSizeLarge, color: statusColor),
                        const SizedBox(height: kSpacingSmall),
                        Text(
                          'Transaction Successful!',
                          style: textTheme.titleLarge?.copyWith(color: kBrandNavy, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: kPaddingMedium),

                        // Amount Details (Size reduced to headlineSmall)
                        Text(
                          amountLabel,
                          style: textTheme.bodyMedium?.copyWith(color: kLightTextSecondary),
                        ),
                        const SizedBox(height: kPaddingExtraSmall),
                        Text(
                          _formatCurrency(receipt.amount),
                          style: textTheme.headlineSmall?.copyWith( // Small amount text size
                            color: kBrandNavy,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),

                        // Separator and Transaction ID
                        const Divider(height: kSpacingMedium),
                        _buildDetailRow(
                          context,
                          'Reference ID',
                          receipt.transactionId,
                          valueColor: kBrandNavy,
                        ),
                        _buildDetailRow(
                          context,
                          'Deposit Date',
                          DateFormat('dd MMM yyyy | hh:mm a').format(receipt.depositDate),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tighter space between cards
                const SizedBox(height: kPaddingMedium),

                // 1B. SCHEME DETAILS CARD
                _buildSectionCard(
                  context,
                  title: 'Scheme Details',
                  children: [
                    _buildDetailRow(context, 'Scheme Name', receipt.schemeName),
                    _buildDetailRow(context, 'Account Number', receipt.newAccountNumber),
                    _buildDetailRow(context, 'Interest Rate', '${receipt.interestRate}% p.a.'),
                    _buildDetailRow(context, 'Tenure', receipt.tenureDescription),
                    _buildDetailRow(context, 'Nominee', receipt.nomineeName),
                  ],
                ),
                // Tighter space between cards
                const SizedBox(height: kPaddingMedium),

                // 1C. MATURITY DETAILS CARD (Visually distinct)
                Container(
                  padding: const EdgeInsets.all(kPaddingMedium),
                  decoration: BoxDecoration(
                    color: kSuccessGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(kRadiusMedium),
                    border: Border.all(color: kSuccessGreen.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maturity & Returns',
                        style: textTheme.titleSmall?.copyWith(color: kSuccessGreen, fontWeight: FontWeight.w700),
                      ),
                      const Divider(height: kSpacingSmall, color: kSuccessGreen),
                      _buildDetailRow(
                        context,
                        'Maturity Date',
                        receipt.maturityDate,
                        valueColor: kSuccessGreen,
                      ),
                      _buildDetailRow(
                        context,
                        'Maturity Amount',
                        _formatCurrency(receipt.maturityAmount),
                        valueColor: kSuccessGreen,
                        isHighlight: true,
                      ),
                    ],
                  ),
                ),
                // Space above buttons
                const SizedBox(height: kPaddingLarge),
              ],
            ),
          ),
        ),

        // 2. ACTION BUTTONS (Fixed at the bottom)
        Padding(
          // FIX: Added bottomSafeArea to the bottom padding to push buttons above the system bar
          padding: EdgeInsets.fromLTRB(
            kPaddingMedium,
            kPaddingSmall,
            kPaddingMedium,
            kPaddingMedium + bottomSafeArea, // Dynamically add safe area space
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleShareReceipt,
                  icon: const Icon(Icons.share_outlined, size: kIconSizeSmall),
                  label: const Text('SHARE RECEIPT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBrandNavy,
                    side: const BorderSide(color: kBrandNavy, width: 1),
                    minimumSize: const Size(double.infinity, kButtonHeight),
                    textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                  ),
                ),
              ),
              const SizedBox(width: kPaddingMedium),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _handleDownloadPdf,
                  icon: const Icon(Icons.download, size: kIconSizeSmall),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange,
                    foregroundColor: kLightSurface,
                    minimumSize: const Size(double.infinity, kButtonHeight),
                    textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    elevation: kCardElevation,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper to build a detail section card
  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: kCardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(color: kBrandNavy, fontWeight: FontWeight.w700), // Reduced size
            ),
            // Tighter divider spacing
            const Divider(height: kSpacingMedium, color: kLightTextSecondary),
            ...children,
          ],
        ),
      ),
    );
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.depositType} Deposit Receipt',
          style: textTheme.titleLarge?.copyWith(color: kLightSurface),
        ),
        // AppBar color set to kAccentOrange
        backgroundColor: kAccentOrange,
        iconTheme: const IconThemeData(color: kLightSurface),
      ),
      body: FutureBuilder<DepositReceipt>(
        future: _receiptFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(kPaddingMedium),
                child: Text(
                  'Error fetching receipt: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: kErrorRed),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            return _buildReceiptView(context, snapshot.data!);
          }
          return const Center(child: Text('No receipt data found.'));
        },
      ),
    );
  }
}