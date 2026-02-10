import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/transaction_service.dart';
import '../widgets/tpin_input_sheet.dart';

final transServiceProvider = Provider((ref) => TransactionService());

class TransferConfirmScreen extends ConsumerWidget {
  final String fromAccount;
  final String toAccount;
  final String recipientName;
  final double amount;

  const TransferConfirmScreen({
    super.key,
    required this.fromAccount,
    required this.toAccount,
    required this.recipientName,
    required this.amount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Confirm Details"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // The Receipt Slip
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.blue, size: 50),
                  const SizedBox(height: 16),
                  const Text("Transaction Summary", style: TextStyle(fontSize: 16, color: Colors.grey)),
                  Text("₹ ${amount.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                  const Divider(height: 40),
                  _buildDetailRow("From Account", fromAccount),
                  _buildDetailRow("To Account", toAccount),
                  _buildDetailRow("Recipient", recipientName),
                  const Divider(height: 40),
                  _buildDetailRow("Bank Charges", "₹ 0.00"),
                  _buildDetailRow("Total Payable", "₹ ${amount.toStringAsFixed(2)}", isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 50),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _openPinSheet(context, ref),
                child: const Text("CONFIRM & PAY", style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPinSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => TpinInputSheet(
        onConfirm: (pin) {
          Navigator.pop(context); // Close sheet
          _handleTransfer(context, ref, pin);
        },
      ),
    );
  }

  void _handleTransfer(BuildContext context, WidgetRef ref, String pin) async {
    // Show loading
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

    try {
      final res = await ref.read(transServiceProvider).transferFunds(
        fromAcc: fromAccount,
        toAcc: toAccount,
        amount: amount,
        mpin: pin,
      );

      Navigator.pop(context); // Close loading
      _showStatusDialog(context, true, res.transactionRefNo);
    } catch (e) {
      Navigator.pop(context); // Close loading
      _showStatusDialog(context, false, e.toString());
    }
  }

  void _showStatusDialog(BuildContext context, bool isSuccess, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSuccess ? Icons.verified : Icons.error, color: isSuccess ? Colors.green : Colors.red, size: 70),
            const SizedBox(height: 20),
            Text(isSuccess ? "Success!" : "Failed", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(isSuccess ? "Ref: $message" : message, textAlign: TextAlign.center),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("GO TO DASHBOARD"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}