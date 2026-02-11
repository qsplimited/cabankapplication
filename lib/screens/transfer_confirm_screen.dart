import 'package:cabankapplication/screens/security_pin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Confirm Details"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: kBrandNavy,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          children: [
            // Professional Receipt Card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusLarge),
                side: BorderSide(color: kBrandNavy.withOpacity(0.1)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(kPaddingLarge),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 48, color: kBrandNavy),
                    const SizedBox(height: kPaddingMedium),
                    const Text("You are transferring",
                        style: TextStyle(color: kLightTextSecondary, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      "₹ ${amount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: kBrandNavy,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: kPaddingMedium),
                      child: Divider(),
                    ),
                    _buildConfirmRow("From Account", fromAccount),
                    _buildConfirmRow("Recipient Name", recipientName),
                    _buildConfirmRow("Recipient Account", toAccount),
                    _buildConfirmRow("Transfer Type", "Intra-Bank Transfer"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: kSpacingExtraLarge),

            // Proceed Button
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusMedium),
                  ),
                  elevation: 2,
                ),
                onPressed: () {
                  // FIX: Added the missing 'recipientName' parameter here
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SecurityPinScreen(
                        fromAccount: fromAccount,
                        toAccount: toAccount,
                        amount: amount,
                        recipientName: recipientName, // Added this line
                      ),
                    ),
                  );
                },
                child: const Text(
                  "PROCEED TO PAY",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: kPaddingMedium),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 14, color: kLightTextSecondary),
                SizedBox(width: 4),
                Text(
                  "Verified & Secure Transaction",
                  style: TextStyle(color: kLightTextSecondary, fontSize: 12),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kLightTextSecondary, fontSize: 13)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: kBrandNavy,
            ),
          ),
        ],
      ),
    );
  }
}