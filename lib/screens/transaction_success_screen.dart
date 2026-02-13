import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added Riverpod import
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

import '../models/transaction_response_model.dart';
import '../providers/dashboard_provider.dart';
import '../providers/account_details_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class TransactionSuccessScreen extends ConsumerStatefulWidget {
  final TransactionResponse response;
  final String recipientName;

  const TransactionSuccessScreen({
    super.key,
    required this.response,
    required this.recipientName,
  });

  @override
  ConsumerState<TransactionSuccessScreen> createState() => _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState extends ConsumerState<TransactionSuccessScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();

  String _formatDateTime(String rawDate) {
    try {
      DateTime dt = DateTime.parse(rawDate);
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (e) {
      return rawDate;
    }
  }

  Future<void> _shareFullScreenReceipt() async {
    try {
      final image = await _screenshotController.capture();
      if (image != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = File('${directory.path}/transaction_receipt.png');
        await imagePath.writeAsBytes(image);

        await Share.shareXFiles(
          [XFile(imagePath.path)],
          text: 'Payment to ${widget.recipientName} Successful!',
        );
      }
    } catch (e) {
      debugPrint("Sharing failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 1. Capture Area (Receipt)
          Expanded(
            child: Screenshot(
              controller: _screenshotController,
              child: Container(
                color: Colors.white,
                width: double.infinity,
                child: Column(
                  children: [
                    const SizedBox(height: 80),
                    const Icon(Icons.check_circle, size: 100, color: kSuccessGreen),
                    const SizedBox(height: 20),
                    const Text("Transaction Successful",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kBrandNavy)),
                    const SizedBox(height: 8),
                    Text("₹ ${widget.response.amount.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: kBrandNavy)),
                    const SizedBox(height: 40),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: kPaddingLarge),
                      padding: const EdgeInsets.all(kPaddingLarge),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(kRadiusLarge),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow("To", widget.recipientName, isBold: true),
                          _buildDetailRow("Beneficiary Account", widget.response.toAccount),
                          _buildDetailRow("Reference No", widget.response.transactionRefNo),
                          _buildDetailRow("Date & Time", _formatDateTime(widget.response.transactionDateTime)),
                          _buildDetailRow("Status", "COMPLETED", color: kSuccessGreen),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Control Area (Action Buttons)
          Padding(
            padding: const EdgeInsets.all(kPaddingLarge),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: kButtonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kRadiusMedium),
                      ),
                    ),
                    onPressed: () {
                      // 1. Force Riverpod to throw away the "20000" balance
                      ref.invalidate(dashboardAccountProvider);

                      // 2. Clear navigation and go to Dashboard
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/dashboard',
                            (route) => false,
                      );
                    },
                    child: const Text(
                      "DONE",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _shareFullScreenReceipt,
                  icon: const Icon(Icons.share, color: kBrandNavy),
                  label: const Text("SHARE FULL RECEIPT",
                      style: TextStyle(color: kBrandNavy, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kLightTextSecondary, fontSize: 13)),
          Text(value, style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? kBrandNavy,
              fontSize: 14
          )),
        ],
      ),
    );
  }
}