import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../utils/app_formatters.dart';
import 'deposit_opening_screen.dart';

class SuccessReceiptScreen extends StatelessWidget {
  final String transactionId;
  final double amount;
  final String accountNumber;
  final String actionName;

  const SuccessReceiptScreen({
    Key? key,
    required this.transactionId,
    required this.amount,
    required this.accountNumber,
    required this.actionName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : kLightBackground,
      // Using WillPopScope to prevent users from going back to the OTP screen
      body: PopScope(
        canPop: false,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(kPaddingMedium),
                  child: Column(
                    children: [
                      const SizedBox(height: 60),
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: kSuccessGreen,
                        child: Icon(Icons.check_rounded, color: Colors.white, size: 50),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Instruction Submitted",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Your request for A/C $accountNumber has been processed.",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: kLightTextSecondary),
                      ),
                      const SizedBox(height: 40),
                      _buildInfoCard(isDark),
                    ],
                  ),
                ),
              ),
              _buildDoneButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(kPaddingLarge),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(kRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Added opacity to prevent reflex error
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _row("Instruction", actionName),
          _row("Amount", AppFormatters.formatCurrency(amount)),
          _row("Ref Number", transactionId),
          _row("Status", "Successful", color: kSuccessGreen),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: kLightTextSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? (color == null ? null : color), // Safe color check
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kPaddingMedium),
      child: SizedBox(
        width: double.infinity,
        height: kButtonHeight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadiusSmall),
            ),
          ),
          onPressed: () {
            // Clears all previous screens (OTP, Review, etc.)
            // and makes DepositOpeningScreen the new home.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const DepositOpeningScreen(),
              ),
                  (route) => false, // This condition removes all previous routes
            );
          },
          child: const Text(
            "BACK TO HOME",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}