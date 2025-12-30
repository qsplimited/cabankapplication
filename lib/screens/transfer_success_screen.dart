import 'package:flutter/material.dart';

class TransferSuccessScreen extends StatelessWidget {
  final String transactionId;
  final double amount;
  final String fromAccount;
  final String toAccount;

  const TransferSuccessScreen({
    super.key,
    required this.transactionId,
    required this.amount,
    required this.fromAccount,
    required this.toAccount,
  });

  // Helper method for navigation to avoid code duplication
  void _navigateToDashboard(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/dashboard',
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevents hardware/gesture back from going to payment form
      onPopInvoked: (didPop) {
        if (didPop) return;
        _navigateToDashboard(context);
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Transfer Status"),
          centerTitle: true,
          // Custom Back Button in AppBar
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _navigateToDashboard(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Spacer(),
                const Icon(Icons.check_circle, color: Colors.green, size: 100),
                const SizedBox(height: 24),
                const Text(
                    "Success!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                Text(
                  "Transfer of ₹${amount.toStringAsFixed(2)} Successful",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Receipt Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _row("Transaction ID", transactionId),
                      const Divider(height: 30),
                      _row("From Account", fromAccount),
                      _row("To Account", toAccount),
                    ],
                  ),
                ),
                const Spacer(),

                // Final Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                      ),
                    ),
                    onPressed: () => _navigateToDashboard(context),
                    child: const Text(
                        "GO TO DASHBOARD",
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}