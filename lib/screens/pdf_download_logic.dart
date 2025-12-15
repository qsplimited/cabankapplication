import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Critical imports for native file handling
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

// PDF generation and core model imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:cabankapplication/models/data_models.dart';

// --- Global PDF Styles ---
const PdfColor _primaryNavyBlue = PdfColor.fromInt(0xFF003366);
const PdfColor _lightGrey = PdfColor.fromInt(0xFFF0F0F0);
const PdfColor _successGreen = PdfColor.fromInt(0xFF008000); // Standard green for credits
const PdfColor _errorRed = PdfColor.fromInt(0xFFB00020);   // Standard red for debits

// --- 1. Native Environment Save Function (For Physical Mobile Device) ---
Future<bool> _saveFileNative(Uint8List data, String fileName) async {
  try {
    // A. Request Permission
    PermissionStatus status;

    if (Platform.isAndroid) {
      status = await Permission.storage.request();
      if (!status.isGranted) {
        status = await Permission.mediaLibrary.request();
      }
    } else if (Platform.isIOS) {
      status = await Permission.photos.request();
    } else {
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      if (kDebugMode) print('CRITICAL: Permission denied. Cannot save file. Status: $status');
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
      return false;
    }

    // B. Determine Save Directory
    final directory = (Platform.isAndroid
        ? await getExternalStorageDirectory() // Often safer for downloads
        : await getApplicationDocumentsDirectory());

    if (directory == null) {
      if (kDebugMode) print("CRITICAL: Could not find a valid directory to save the file.");
      return false;
    }

    final filePath = '${directory.path}/$fileName';

    // C. Write the file
    final file = File(filePath);
    await file.writeAsBytes(data, flush: true);
    if (kDebugMode) print('File saved successfully to: $filePath');

    // D. Open the file
    final result = await OpenFilex.open(filePath);

    return result.type == ResultType.done;
  } catch (e) {
    if (kDebugMode) print('CRITICAL: Native file save error: $e');
    return false;
  }
}

// --- 2. Single Transaction Receipt Generator ---

/// Generates a PDF receipt for a single transaction and saves it.
Future<bool> generateAndSaveReceiptPdf(
    Transaction transaction,
    Account account, // Needed for account context
    ) async {
  final pdf = pw.Document();

  // Define styling
  final pw.TextStyle titleStyle = pw.TextStyle(
    fontSize: 20,
    fontWeight: pw.FontWeight.bold,
    color: _primaryNavyBlue,
  );
  final pw.TextStyle labelStyle = pw.TextStyle(
    fontWeight: pw.FontWeight.bold,
    color: _primaryNavyBlue,
  );

  final String transactionType = transaction.type == TransactionType.credit ? 'Credit' : 'Debit';
  final String sign = transaction.type == TransactionType.credit ? '+' : '-';
  final PdfColor amountColor = transaction.type == TransactionType.credit ? _successGreen : _errorRed;
  // Use a unique ID based on the transaction date/time if no real ID is available
  final String transactionId = 'T${transaction.date.microsecondsSinceEpoch}';

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5, // Smaller format for a receipt
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(25),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _primaryNavyBlue, width: 2),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            width: double.infinity,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Center(child: pw.Text('CA BANK', style: titleStyle.copyWith(fontSize: 24))),
                pw.Center(child: pw.Text('Transaction Receipt', style: titleStyle)),
                pw.SizedBox(height: 20),

                _buildReceiptRow('Transaction ID:', transactionId, labelStyle: labelStyle),
                _buildReceiptRow('Date & Time:', DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date)),
                _buildReceiptRow('Account Number:', account.accountNumber),
                pw.Divider(thickness: 1, color: _primaryNavyBlue.shade(0.3)),

                _buildReceiptRow('Transaction Type:', transactionType, labelStyle: labelStyle),
                _buildReceiptRow('Description:', transaction.description),
                pw.SizedBox(height: 10),

                // Amount Row (Highlighted)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                  decoration: pw.BoxDecoration(color: amountColor.shade(0.1)),
                  child: _buildReceiptRow(
                    'Amount:',
                    '$sign ₹${transaction.amount.toStringAsFixed(2)}',
                    valueStyle: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Center(
                  child: pw.Text(
                    'Thank you for banking with CA Bank.',
                    style: pw.TextStyle(fontSize: 10, color: _primaryNavyBlue),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'E. & O.E.',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  // --- File Saving (Native Mobile Only) ---
  try {
    final Uint8List pdfBytes = await pdf.save();
    final String fileName = 'Receipt_${transactionId}.pdf';
    return await _saveFileNative(pdfBytes, fileName);
  } catch (e) {
    if (kDebugMode) print('Receipt Save/Open Failed: $e');
    return false;
  }
}

// --- Helper for consistent receipt row layout ---
pw.Widget _buildReceiptRow(
    String label,
    String value, {
      pw.TextStyle? labelStyle,
      pw.TextStyle? valueStyle,
    }) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: labelStyle ?? const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          value,
          style: valueStyle ?? const pw.TextStyle(fontSize: 12),
        ),
      ],
    ),
  );
}


// --- 3. Full Account Statement Generator ---

Future<bool> generateAndSavePdf(
    List<Transaction> transactions,
    Account account,
    String startDate,
    String endDate,
    ) async {
  final pdf = pw.Document();

  // --- PDF GENERATION LOGIC ---
  transactions.sort((a, b) => a.date.compareTo(b.date)); // Oldest first

  final List<Map<String, dynamic>> transactionData = [];

  // 1. Calculate the initial/opening balance for the statement period
  // This is derived from the *current* balance minus the net effect of the *filtered* transactions.
  double netEffect = 0;
  for (var t in transactions) {
    netEffect += (t.type == TransactionType.credit) ? t.amount : -t.amount;
  }
  double statementOpeningBalance = account.balance - netEffect;
  double runningBalance = statementOpeningBalance;
  double statementClosingBalance = statementOpeningBalance; // Initialize closing balance

  // 2. Iterate and calculate running balance for the display data
  for (var t in transactions) {
    final isCredit = t.type == TransactionType.credit;
    runningBalance += (isCredit ? t.amount : -t.amount);
    statementClosingBalance = runningBalance; // Update closing balance after each transaction

    transactionData.add({
      'date': DateFormat('dd MMM yyyy').format(t.date),
      'description': t.description,
      'debit': isCredit ? '' : t.amount.toStringAsFixed(2),
      'credit': isCredit ? t.amount.toStringAsFixed(2) : '',
      'balance': runningBalance.toStringAsFixed(2),
    });
  }

  final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, color: _primaryNavyBlue);
  final tableHeaderStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: _primaryNavyBlue);
  final tableRowStyle = const pw.TextStyle(fontSize: 9);

  // We reverse the transaction data array before rendering the table
  // so the latest transactions show at the top (standard for statements)
  final reversedTransactionData = transactionData.reversed.toList();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Account Transaction Statement',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _primaryNavyBlue),
              ),
              pw.SizedBox(height: 15),

              // Account Details Box
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _primaryNavyBlue, width: 1),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Account Holder: ${account.nickname}', style: headerStyle),
                        pw.Text('Statement Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: headerStyle),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Account Number: ${account.accountNumber}', style: tableRowStyle),
                    pw.Text('Account Type: ${account.accountType}', style: tableRowStyle),
                    pw.Text('Statement Period: $startDate to $endDate', style: tableRowStyle),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Balances
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Opening Balance: ₹${statementOpeningBalance.toStringAsFixed(2)}', style: headerStyle),
                    pw.Text('Closing Balance: ₹${statementClosingBalance.toStringAsFixed(2)}', style: headerStyle),
                  ]
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              // Transactions Table
              pw.Table.fromTextArray(
                headers: ['Date', 'Description', 'Debit (₹)', 'Credit (₹)', 'Running Balance (₹)'],
                data: reversedTransactionData.map((e) => [
                  e['date'],
                  e['description'],
                  e['debit'],
                  e['credit'],
                  e['balance'],
                ]).toList(),
                headerStyle: tableHeaderStyle,
                cellStyle: tableRowStyle,
                headerDecoration: pw.BoxDecoration(color: _lightGrey),
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                  4: const pw.FlexColumnWidth(2.5),
                },
                cellPadding: const pw.EdgeInsets.all(6),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
              ),

              pw.SizedBox(height: 20),

              pw.Center(
                child: pw.Text(
                  'This is an electronically generated statement. E. & O.E.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ),
            ],
          ),
        ];
      },
    ),
  );

  // --- File Saving (Native Mobile Only) ---
  try {
    final Uint8List pdfBytes = await pdf.save();
    final String fileName = 'Statement_${account.accountNumber}_${endDate.replaceAll('-', '')}.pdf';
    return await _saveFileNative(pdfBytes, fileName);
  } catch (e) {
    if (kDebugMode) print('PDF Save/Open Failed: $e');
    return false;
  }
}