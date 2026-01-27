import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/receipt_models.dart';
import '../theme/app_colors.dart';
import '../providers/receipt_provider.dart';

class DepositReceiptScreen extends ConsumerStatefulWidget {
  const DepositReceiptScreen({super.key});

  @override
  ConsumerState<DepositReceiptScreen> createState() => _DepositReceiptScreenState();
}

class _DepositReceiptScreenState extends ConsumerState<DepositReceiptScreen> {
  bool _isProcessing = false;
  final fmt = NumberFormat('#,##0.00');
  final dateFmt = DateFormat('dd-MMM-yyyy');

  // --- PDF & FILE LOGIC RETAINED ---
  Future<void> _handleFileAction({required bool isShare, required DepositReceipt r}) async {
    setState(() => _isProcessing = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => pw.Padding(
          padding: const pw.EdgeInsets.all(30),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("CA BANK - ${r.receiptType.name.toUpperCase()} ADVICE",
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 10),
              _pdfRow("Transaction Ref", r.transactionId),
              _pdfRow("Value Date (Start)", dateFmt.format(r.valueDate ?? r.date)),
              if (r.receiptType == ReceiptType.closure)
                _pdfRow("Closing Date", dateFmt.format(DateTime.now())),
              _pdfRow("Account Number", r.accountNumber),
              if (r.oldAccountNumber != null)
                _pdfRow("Previous Account", r.oldAccountNumber!),
              _pdfRow("Nominee", r.nomineeName),

              pw.SizedBox(height: 25),
              pw.Text("DEPOSIT SUMMARY", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Divider(),
              _pdfRow("Principal Amount", "Rs. ${fmt.format(r.amount)}"),
              _pdfRow("Interest Rate", "${r.interestRate}% p.a."),
              _pdfRow("Tenure", r.tenure),
              _pdfRow("Lien Status", r.lienStatus ?? "Nil"),

              if (r.receiptType != ReceiptType.closure) ...[
                _pdfRow("Maturity Date", r.maturityDate ?? ""),
                _pdfRow("Instruction", r.maturityInstruction ?? "Credit to Account"),
              ],

              if (r.receiptType == ReceiptType.closure) ...[
                _pdfRow("Interest Accrued", "Rs. ${fmt.format(r.accruedInterest ?? 0)}"),
                _pdfRow("Tax Deducted (TDS)", "Rs. ${fmt.format(r.taxDeducted ?? 0)}"),
                _pdfRow("Penalty", "Rs. ${fmt.format(r.penaltyAmount ?? 0)}"),
              ],

              pw.SizedBox(height: 30),
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: _pdfRow(
                  r.receiptType == ReceiptType.closure ? "Final Payout" : "Maturity Value",
                  "Rs. ${fmt.format(r.receiptType == ReceiptType.closure ? r.netPayout : r.maturityAmount)}",
                  isBold: true,
                ),
              ),
              pw.Spacer(),
              pw.Center(
                child: pw.Text("This is a computer-generated advice and does not require a signature.",
                    style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ),
            ],
          ),
        ),
      ));

      final dir = await getTemporaryDirectory();
      final String fileName = "Receipt_${r.transactionId}_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${dir.path}/$fileName");
      await file.writeAsBytes(await pdf.save());

      if (isShare) {
        await Share.shareXFiles([XFile(file.path)], text: 'My CA Bank Deposit Receipt');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("PDF Saved: ${file.path.split('/').last}"),
              backgroundColor: kSuccessGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error processing file: $e"), backgroundColor: kErrorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  pw.Widget _pdfRow(String l, String v, {bool isBold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(l, style: pw.TextStyle(fontSize: 12)),
        pw.Text(v, style: pw.TextStyle(fontSize: 12, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal))
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Watch provider to get current receipt data
    final receiptState = ref.watch(receiptProvider);

    return receiptState.when(
      data: (r) {
        if (r == null) return const Scaffold(body: Center(child: Text("No data")));
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text("Transaction Advice"),
            backgroundColor: kAccentOrange,
            elevation: 0,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(children: [
                    _buildStatusBanner(r),
                    const SizedBox(height: 16),
                    _buildReceiptCard(r),
                  ]),
                ),
              ),
              _buildActionPanel(r),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: kAccentOrange))),
      error: (err, stack) => Scaffold(body: Center(child: Text("Error: $err"))),
    );
  }

  // --- UI BUILDING BLOCKS RETAINED ---
  Widget _buildStatusBanner(DepositReceipt r) {
    bool isNeg = r.receiptType == ReceiptType.closure;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(children: [
        Icon(isNeg ? Icons.cancel_rounded : Icons.check_circle_rounded,
            color: isNeg ? kErrorRed : kSuccessGreen, size: 40),
        const SizedBox(width: 15),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.receiptType.name.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: kBrandNavy)),
          Text("Ref: ${r.transactionId}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ])
      ]),
    );
  }

  Widget _buildReceiptCard(DepositReceipt r) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(children: [
        _section([
          _uiRow("Value Date", dateFmt.format(r.valueDate ?? r.date)),
          if (r.receiptType == ReceiptType.closure)
            _uiRow("Closing Date", dateFmt.format(DateTime.now()), color: kErrorRed),
          _uiRow("Account No.", r.accountNumber),
          _uiRow("Nominee", r.nomineeName),
          _uiRow("Lien Status", r.lienStatus ?? "Nil"),
        ]),
        const Divider(height: 1),
        _section([
          const Text("DEPOSIT SUMMARY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          _uiRow("Principal", "₹${fmt.format(r.amount)}"),
          _uiRow("Scheme", r.schemeName),
          _uiRow("Interest", "${r.interestRate}% p.a."),
          _uiRow("Tenure", r.tenure),
          if (r.receiptType != ReceiptType.closure) ...[
            _uiRow("Maturity Date", r.maturityDate ?? ""),
            _uiRow("Maturity Instruction", r.maturityInstruction ?? "Auto-Credit"),
          ],
          if (r.receiptType == ReceiptType.closure) ...[
            _uiRow("Interest Accrued", "₹${fmt.format(r.accruedInterest ?? 0)}", color: kSuccessGreen),
            _uiRow("Tax (TDS)", "-₹${fmt.format(r.taxDeducted ?? 0)}"),
            _uiRow("Penalty", "-₹${fmt.format(r.penaltyAmount ?? 0)}", color: kErrorRed),
          ],
        ]),
        _totalStrip(r),
      ]),
    );
  }

  Widget _totalStrip(DepositReceipt r) {
    bool isCl = r.receiptType == ReceiptType.closure;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: (isCl ? kErrorRed : kSuccessGreen).withOpacity(0.08),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(isCl ? "Final Payout" : "Maturity Value", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text("₹${fmt.format(isCl ? r.netPayout : r.maturityAmount)}",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isCl ? kErrorRed : kSuccessGreen)),
      ]),
    );
  }

  Widget _section(List<Widget> children) => Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children));

  Widget _uiRow(String l, String v, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      Text(v, style: TextStyle(fontWeight: FontWeight.w600, color: color ?? kBrandNavy, fontSize: 13))
    ]),
  );

  Widget _buildActionPanel(DepositReceipt r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : () => _handleFileAction(isShare: true, r: r),
            icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.share_outlined),
            label: const Text("SHARE"),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), side: const BorderSide(color: kAccentOrange)),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : () => _handleFileAction(isShare: false, r: r),
            icon: const Icon(Icons.file_download_outlined),
            label: const Text("DOWNLOAD"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kAccentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              elevation: 0,
            ),
          ),
        ),
      ]),
    );
  }
}