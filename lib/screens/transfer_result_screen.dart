// File: transfer_result_screen.dart (FINAL ENHANCED DESIGN - V2)

import 'package:flutter/material.dart';

class TransferResultScreen extends StatelessWidget {
  final String message;
  final bool isSuccess;

  const TransferResultScreen({
    super.key,
    required this.message,
    required this.isSuccess,
  });

  // Helper method for navigation logic
  void _handleNavigation(BuildContext context) {
    // Define the route name for the Fund Transfer Start Page (e.g., Payee Selection)
    const String transferStartRoute = '/transferFunds';
    // Define the route name for the Dashboard/Home Page (e.g., the root screen)
    const String dashboardRoute = '/dashboard';

    // For success, generally navigate back to the main transfer screen or dashboard.
    // We'll use popUntil to ensure we clear all intermediary screens (like amount entry, confirmation).

    // Check if the transferStartRoute exists in the history, otherwise go to the root (dashboard).
    Navigator.popUntil(
      context,
          (route) => route.isFirst || route.settings.name == transferStartRoute || route.settings.name == dashboardRoute,
    );

    // If you always want to pop all the way back to the main home/dashboard:
    // Navigator.popUntil(context, (route) => route.isFirst); 
  }

  @override
  Widget build(BuildContext context) {
    // --- Theme Colors ---
    final Color primaryColor = const Color(0xFF003366); // Dark Blue
    final Color successColor = Colors.green.shade600;
    final Color failureColor = Colors.red.shade600;

    final Color accentColor = isSuccess ? successColor : failureColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSuccess ? 'Transaction Successful' : 'Transaction Failed',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height - MediaQuery.of(context).padding.top,
          ),
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Visual Status Indicator Card ---
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  color: accentColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                    child: Column(
                      children: [
                        // Status Icon
                        Icon(
                          isSuccess ? Icons.check_circle_outline : Icons.sentiment_very_dissatisfied_outlined,
                          size: 90,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),

                        // Status Title
                        Text(
                          isSuccess ? 'Transfer Complete!' : 'Transfer Failed!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),

                        if (!isSuccess)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Please review the error details below.',
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- Transaction Message/Details Box (More attractive for failure) ---
                Text(
                  isSuccess ? 'Transaction Summary' : 'Reason for Failure',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 10),

                // ATTRACTIVE DESIGN FOR MESSAGE BOX
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    // Adding a subtle shadow/outline for a cleaner, more focused look (like a slip)
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(color: accentColor.withOpacity(0.5), width: 1),
                  ),
                  // Using a smaller, more contained box for the message
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isSuccess ? primaryColor : failureColor.shade900,
                          fontWeight: isSuccess ? FontWeight.normal : FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // --- Action Button: Go Back ---
                ElevatedButton(
                  onPressed: () => _handleNavigation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Return to Fund Transfer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

extension on Color {
  get shade900 => null;
}