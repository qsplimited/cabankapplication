import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../utils/app_formatters.dart';
import 'deposit_opening_screen.dart';

class LoanSuccessScreen extends StatelessWidget {
  final double amount;
  final String targetAccount;
  final String collateralId;

  const LoanSuccessScreen({
    Key? key,
    required this.amount,
    required this.targetAccount,
    required this.collateralId,
  }) : super(key: key);

  void _navigateToDepositOpening(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const DepositOpeningScreen()),
          (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String referenceId = "LAD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
    final String loanAccountNumber = "LDT-0099${DateTime.now().second}55";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: kAccentOrange,
        centerTitle: true,
        title: const Text("Success", style: TextStyle(color: Colors.white)),
        // AppBar Back Button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _navigateToDepositOpening(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(kPaddingMedium),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  const Icon(Icons.check_circle, color: kSuccessGreen, size: 90),
                  const SizedBox(height: 16),
                  const Text(
                    "Loan Disbursed",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: kBrandNavy),
                  ),
                  const SizedBox(height: 32),

                  // Financial Breakdown
                  _buildReceiptDetail("Total Loan Amount", AppFormatters.formatCurrency(amount)),
                  const SizedBox(height: 16),

                  Card(
                    elevation: 0,
                    color: kLightBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                    child: Padding(
                      padding: const EdgeInsets.all(kPaddingMedium),
                      child: Column(
                        children: [
                          _receiptRow("Loan Account", loanAccountNumber),
                          _receiptRow("Credited To", targetAccount),
                          _receiptRow("Collateral FD", collateralId),
                          _receiptRow("Transaction ID", referenceId),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BOTTOM SECTION WITH PROPER SPACING ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  kPaddingMedium,
                  kPaddingSmall,
                  kPaddingMedium,
                  kPaddingMedium // This provides the bottom space you need
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50, // Standard height for bank buttons
                child: ElevatedButton(
                  onPressed: () => _navigateToDepositOpening(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                    elevation: 2,
                  ),
                  child: const Text(
                      "DONE",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptDetail(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kBrandNavy)),
      ],
    );
  }

  Widget _receiptRow(String l, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandNavy, fontSize: 13)),
        ],
      ),
    );
  }
}