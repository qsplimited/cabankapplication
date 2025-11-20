import 'package:flutter/material.dart';

/// Screen to display the result (success or failure) of a fund transfer.
class TransferResultScreen extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const TransferResultScreen({
    super.key,
    required this.message,
    this.isSuccess = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color(0xFF003366);
    final Color successColor = const Color(0xFF2E7D32);
    final Color errorColor = const Color(0xFFE53935);

    final icon = isSuccess ? Icons.check_circle_outline : Icons.error_outline;
    final color = isSuccess ? successColor : errorColor;
    final title = isSuccess ? 'Transfer Successful' : 'Transfer Failed';

    // Dynamic button label based on success/failure
    final buttonLabel = isSuccess ? 'DONE / NEW TRANSFER' : 'RETRY TRANSFER';

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        automaticallyImplyLeading: false, // Prevents back button on result
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 100, color: color),
              const SizedBox(height: 30),
              Text(
                title,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: color.withOpacity(0.3), width: 1.5)
                ),
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // This pops the current Result screen and returns to the previous screen (TransferAmountEntryScreen)
                    // This works for both success (to start new) and failure (to retry).
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(buttonLabel, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}