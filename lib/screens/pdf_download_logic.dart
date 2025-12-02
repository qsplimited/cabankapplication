import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Critical imports for native file handling
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart'; // REQUIRED for device storage

// PDF generation and core model imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:cabankapplication/models/data_models.dart';

// Removed conditional imports and kIsWeb dependency since this code is only targeting
// native (iOS and Android) environments.

// --- Native Environment Save Function (For Physical Mobile Device) ---
Future<bool> _saveFileNative(Uint8List data, String fileName) async {
  try {
    // A. Request Permission
    PermissionStatus status;

    if (Platform.isAndroid) {
      // For Android, check if we need to request the new media permission or use the old storage one.
      status = await Permission.storage.request();

      // If storage is denied, try the modern Media Library permission (might be needed for scoped storage).
      if (!status.isGranted) {
        status = await Permission.mediaLibrary.request();
      }
    } else if (Platform.isIOS) {
      // For iOS, the Photo Library permission is the standard way to save documents.
      status = await Permission.photos.request();
    } else {
      // Default to Storage for other platforms if needed.
      status = await Permission.storage.request();
    }

    if (!status.isGranted) {
      print('CRITICAL: Permission denied. Cannot save file. Status: $status');
      // If permission is permanently denied, direct user to settings
      if (status.isPermanentlyDenied) {
        openAppSettings();
      }
      return false;
    }

    final directory = (Platform.isAndroid
        ? await getExternalStorageDirectory()
        : await getApplicationDocumentsDirectory());

    if (directory == null) {
      print("CRITICAL: Could not find a valid directory to save the file.");
      return false;
    }

    final filePath = '${directory.path}/$fileName';

    // C. Write the file
    final file = File(filePath);
    await file.writeAsBytes(data, flush: true);
    print('File saved successfully to: $filePath');

    // D. Open the file
    final result = await OpenFilex.open(filePath);

    return result.type == ResultType.done;
  } catch (e) {
    print('CRITICAL: Native file save error: $e');
    return false;
  }
}

// --- Main PDF Generator and Saver ---
Future<bool> generateAndSavePdf(
    List<Transaction> transactions,
    Account account,
    String startDate,
    String endDate,
    ) async {
  final pdf = pw.Document();

  // --- PDF GENERATION LOGIC ---
  transactions.sort((a, b) => a.date.compareTo(b.date));

  final List<Map<String, dynamic>> transactionData = [];

  double netEffect = 0;
  for (var t in transactions) {
    netEffect += (t.type == TransactionType.credit) ? t.amount : -t.amount;
  }

  // Calculate the balance *before* the filtered transactions began
  double openingBalance = account.balance - netEffect;
  double runningBalance = openingBalance;

  // The transactions are sorted chronologically (oldest first)
  for (var t in transactions) {
    final isCredit = t.type == TransactionType.credit;
    runningBalance += (isCredit ? t.amount : -t.amount);

    transactionData.add({
      'date': DateFormat('dd MMM yyyy').format(t.date),
      'description': t.description,
      'debit': isCredit ? '' : t.amount.toStringAsFixed(2),
      'credit': isCredit ? t.amount.toStringAsFixed(2) : '',
      'balance': runningBalance.toStringAsFixed(2),
    });
  }

  const PdfColor primaryNavyBlue = PdfColor.fromInt(0xFF003366);
  const PdfColor lightGrey = PdfColor.fromInt(0xFFF0F0F0);

  final headerStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryNavyBlue);
  final tableHeaderStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: primaryNavyBlue);
  final tableRowStyle = const pw.TextStyle(fontSize: 9);

  // We reverse the transaction data array before rendering the table
  // so the latest transactions (with the current balance) show at the top
  final reversedTransactionData = transactionData.reversed.toList();

  // Recalculate opening/closing balance for the statement based on the filtered data
  double statementOpeningBalance = 0;
  double statementClosingBalance = 0;

  if (transactions.isNotEmpty) {
    // Opening balance is the running balance of the first (oldest) transaction *before* it happened.
    // The runningBalance array above contains the balance *after* the transaction.
    statementOpeningBalance = runningBalance;

    // Closing balance is the running balance of the last (newest) transaction *after* it happened.
    statementClosingBalance = account.balance;
  }


  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Account Transaction Statement',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: primaryNavyBlue),
            ),
            pw.SizedBox(height: 15),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: primaryNavyBlue, width: 1),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Account Holder: Client Name', style: headerStyle),
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

            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Opening Balance (Statement Period): ₹${statementOpeningBalance.toStringAsFixed(2)}', style: headerStyle),
                  pw.Text('Closing Balance (Today): ₹${statementClosingBalance.toStringAsFixed(2)}', style: headerStyle),
                ]
            ),
            pw.Divider(thickness: 1),
            pw.SizedBox(height: 10),

            pw.Table.fromTextArray(
              headers: ['Date', 'Description', 'Debit (₹)', 'Credit (₹)', 'Running Balance (₹)'],
              // Use the reversed list here
              data: reversedTransactionData.map((e) => [
                e['date'],
                e['description'],
                e['debit'],
                e['credit'],
                e['balance'],
              ]).toList(),
              headerStyle: tableHeaderStyle,
              cellStyle: tableRowStyle,
              headerDecoration: pw.BoxDecoration(color: lightGrey),
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

            pw.Spacer(),

            pw.Center(
              child: pw.Text(
                'This is an electronically generated statement. E. & O.E.',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),
          ],
        );
      },
    ),
  );

  // --- File Saving (Native Mobile Only) ---
  try {
    final Uint8List pdfBytes = await pdf.save();
    final String fileName = 'Statement_${account.accountNumber}_${endDate.replaceAll('-', '')}.pdf';

    // Use the native file system mechanism for mobile devices (iOS/Android)
    return await _saveFileNative(pdfBytes, fileName);

  } catch (e) {
    print('PDF Save/Open Failed: $e');
    return false;
  }
}
