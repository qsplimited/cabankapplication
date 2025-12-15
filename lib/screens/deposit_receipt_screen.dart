import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

import '../api/fd_api_service.dart';
import '../api/rd_api_service.dart';
import '../models/receipt_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart'; // Source of all constants

// Helper function for currency formatting
String _formatCurrency(double amount) => '₹${NumberFormat('#,##0.00').format(amount)}';

// Helper for PDF colors
PdfColor _toPdfColor(Color color) => PdfColor.fromInt(color.value);


// -----------------------------------------------------------------------------
// DepositReceiptScreen Widget
// -----------------------------------------------------------------------------
class DepositReceiptScreen extends StatefulWidget {
  final String transactionId;
  final String depositType;
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
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
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
      padding: const EdgeInsets.symmetric(vertical: kPaddingExtraSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(color: kLightTextSecondary),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: isHighlight
                  ? textTheme.titleSmall?.copyWith(color: valueColor, fontWeight: FontWeight.bold)
                  : textTheme.bodyMedium?.copyWith(color: valueColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build a clean title and value row in PDF format
  pw.Widget _buildPdfDetailRow(String label, String value, {bool highlight = false, PdfColor? customColor}) {
    final PdfColor pdfBrandNavy = _toPdfColor(kBrandNavy);
    final PdfColor pdfSuccessGreen = _toPdfColor(kSuccessGreen);

    final PdfColor finalColor = customColor ?? (highlight ? pdfSuccessGreen : pdfBrandNavy);

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: highlight ? 12 : 10,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: finalColor,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------------
  // CORE PDF GENERATION LOGIC (omitted for brevity)
  // ----------------------------------------------------------------------
  pw.Widget _buildPdfContent(DepositReceipt receipt) {
    final String depositType = widget.depositType;
    final String amountLabel = depositType == 'FD' ? 'Fixed Deposit Amount' : 'Monthly Installment';
    final String dateFormatted = DateFormat('dd MMM yyyy | hh:mm a').format(receipt.depositDate);

    final PdfColor pdfBrandNavy = _toPdfColor(kBrandNavy);
    final PdfColor pdfSuccessGreen = _toPdfColor(kSuccessGreen);

    // Define a darker shade of green for text contrast inside the box
    final PdfColor pdfDarkerSuccessGreen = pdfSuccessGreen.shade(0.5);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // HEADER
        pw.Center(
            child: pw.Text(
                'CA Bank $depositType Deposit Receipt',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: pdfBrandNavy)
            )
        ),
        pw.SizedBox(height: 15),

        // STATUS SECTION (HIGHLIGHTED)
        pw.Text(
            'Transaction Successful',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: pdfSuccessGreen)
        ),
        pw.Divider(thickness: 1, color: pdfSuccessGreen.shade(0.3)),
        _buildPdfDetailRow('Reference ID', receipt.transactionId),
        _buildPdfDetailRow('Deposit Date & Time', dateFormatted),
        _buildPdfDetailRow(amountLabel, _formatCurrency(receipt.amount), highlight: true),

        pw.SizedBox(height: 15),

        // SCHEME DETAILS
        pw.Text(
          'Scheme Details',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: pdfBrandNavy),
        ),
        pw.Divider(thickness: 1, color: PdfColors.grey500),
        _buildPdfDetailRow('Scheme Name', receipt.schemeName),
        _buildPdfDetailRow('Account Number', receipt.newAccountNumber),
        _buildPdfDetailRow('Tenure', receipt.tenureDescription),
        _buildPdfDetailRow('Interest Rate', '${receipt.interestRate}% p.a.'),
        _buildPdfDetailRow('Nominee', receipt.nomineeName),

        pw.SizedBox(height: 15),

        // MATURITY DETAILS (HIGHLIGHTED BOX)
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: pdfSuccessGreen.shade(0.95), // Light background for box
            borderRadius: pw.BorderRadius.circular(5),
            border: pw.Border.all(color: pdfSuccessGreen.shade(0.8), width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Maturity & Returns', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: pdfDarkerSuccessGreen)),
              pw.Divider(height: 5, color: pdfSuccessGreen),
              _buildPdfDetailRow('Maturity Date', receipt.maturityDate, customColor: pdfDarkerSuccessGreen),
              _buildPdfDetailRow('Maturity Amount', _formatCurrency(receipt.maturityAmount), highlight: true, customColor: pdfBrandNavy),
            ],
          ),
        ),

        pw.Spacer(),

        // FOOTER
        pw.Center(
          child: pw.Text(
            'This is an electronically generated receipt and does not require a signature.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Text(
            'CA Bank | E. & O.E. | Generated on ${DateFormat('dd-MMM-yyyy').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------------
  // FILE SAVING LOGIC (Used only for temporary file creation for sharing)
  // ----------------------------------------------------------------------
  Future<String?> _generateAndSavePdfFile(DepositReceipt receipt) async {
    if (!context.mounted || kIsWeb) return null;

    try {
      final pdf = pw.Document();
      final String depositType = widget.depositType;
      final String fileName = '${depositType}_Receipt_${receipt.transactionId}.pdf';

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) => _buildPdfContent(receipt),
        ),
      );

      final pdfBytes = await pdf.save();

      // Use Temporary directory for sharing (always works and is cleaned up)
      final Directory directory = await getTemporaryDirectory();

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      return file.path;

    } catch (e) {
      if(context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF file: $e'), duration: const Duration(seconds: 5), backgroundColor: kErrorRed),
        );
      }
      return null;
    }
  }

  // ----------------------------------------------------------------------
  // 🌟 Handle Share Receipt Action - The reliable public save method
  // ----------------------------------------------------------------------
  void _handleShareReceipt(DepositReceipt receipt) async {
    if (_isProcessing || !context.mounted) return;
    setState(() => _isProcessing = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating PDF...')),
    );

    String? filePath;
    try {
      // Save to TEMPORARY directory
      filePath = await _generateAndSavePdfFile(receipt);

      if (filePath != null && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Clear instruction for the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // **CRITICAL INSTRUCTION FOR THE USER**
            content: Text('Please select "Save to Files" or "Download" from the menu to save the PDF publicly to your device storage.'),
            backgroundColor: kBrandLightBlue, // Info color
            duration: Duration(seconds: 7),
          ),
        );

        // Open the system share sheet (this is what allows public saving)
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Attached is your CA Bank Deposit Receipt.',
          subject: 'CA Bank Deposit Receipt - ${receipt.transactionId}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share/Save operation failed: $e')),
        );
      }
    } finally {
      // Ensure processing state is reset to un-stuck the button
      if (context.mounted) setState(() => _isProcessing = false);
    }
  }

  // ----------------------------------------------------------------------
  // 🌟 Download PDF Action - Rerouted to use the reliable Share method
  // ----------------------------------------------------------------------
  void _handleDownloadPdf(DepositReceipt receipt) {
    // The "Share Receipt" flow is the only reliable way to save publicly on modern devices.
    // Reroute the Download button to the Share handler for a guaranteed save experience.
    _handleShareReceipt(receipt);
  }


  // --- Build Receipt View ---
  Widget _buildReceiptView(BuildContext context, DepositReceipt receipt) {
    final textTheme = Theme.of(context).textTheme;
    const Color statusColor = kSuccessGreen;
    final String amountLabel = widget.depositType == 'FD'
        ? 'Fixed Deposit Amount'
        : 'Monthly Installment';

    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        // 1. SCROLLABLE DETAILS AREA
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
                        Icon(Icons.check_circle_outline, size: kIconSizeXXL, color: statusColor),
                        const SizedBox(height: 8.0),
                        Text('Transaction Successful!', style: textTheme.titleLarge?.copyWith(color: kBrandNavy, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16.0),
                        Text(amountLabel, style: textTheme.bodyMedium?.copyWith(color: kLightTextSecondary)),
                        const SizedBox(height: 4.0),
                        Text(_formatCurrency(receipt.amount), style: textTheme.titleLarge?.copyWith(color: kBrandNavy, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        const Divider(height: 12.0),
                        _buildDetailRow(context, 'Reference ID', receipt.transactionId, valueColor: kBrandNavy),
                        _buildDetailRow(context, 'Deposit Date', DateFormat('dd MMM yyyy | hh:mm a').format(receipt.depositDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),

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
                const SizedBox(height: 16.0),

                // 1C. MATURITY DETAILS CARD
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: kSuccessGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: kSuccessGreen.withOpacity(0.3), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Maturity & Returns', style: textTheme.titleSmall?.copyWith(color: kSuccessGreen, fontWeight: FontWeight.w700)),
                      const Divider(height: 8.0, color: kSuccessGreen),
                      _buildDetailRow(context, 'Maturity Date', receipt.maturityDate, valueColor: kSuccessGreen),
                      _buildDetailRow(context, 'Maturity Amount', _formatCurrency(receipt.maturityAmount), valueColor: kSuccessGreen, isHighlight: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),

        // 2. ACTION BUTTONS (Fixed at the bottom)
        Padding(
          padding: EdgeInsets.fromLTRB(
            kPaddingMedium,
            kPaddingSmall,
            kPaddingMedium,
            kPaddingMedium + bottomSafeArea,
          ),
          child: Row(
            children: [
              // SHARE RECEIPT (Original Share action)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _handleShareReceipt(receipt),
                  icon: _isProcessing
                      ? const SizedBox(width: 20.0, height: 20.0, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.share_outlined, size: 20.0),
                  label: Text(_isProcessing ? 'PREPARING...' : 'SHARE RECEIPT'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kBrandNavy,
                    side: const BorderSide(color: kBrandNavy, width: 1),
                    minimumSize: const Size(double.infinity, 56.0),
                    textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                ),
              ),
              const SizedBox(width: kPaddingMedium),
              // SAVE TO FILES (Rerouted to use the reliable Share action)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : () => _handleDownloadPdf(receipt),
                  icon: _isProcessing
                      ? const SizedBox(width: 20.0, height: 20.0, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(kLightSurface)))
                      : const Icon(Icons.save_alt, size: 20.0), // Changed to save icon
                  label: Text(_isProcessing ? 'PREPARING SAVE...' : 'SAVE TO FILES'), // Changed text for clarity
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange,
                    foregroundColor: kLightSurface,
                    minimumSize: const Size(double.infinity, 56.0),
                    textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleSmall?.copyWith(color: kBrandNavy, fontWeight: FontWeight.w700)),
            const Divider(height: 16.0, color: kLightTextSecondary),
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
        title: Text('${widget.depositType} Deposit Receipt', style: textTheme.titleLarge?.copyWith(color: kLightSurface)),
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
                child: Text('Error fetching receipt: ${snapshot.error}', textAlign: TextAlign.center, style: textTheme.bodyLarge?.copyWith(color: kErrorRed)),
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