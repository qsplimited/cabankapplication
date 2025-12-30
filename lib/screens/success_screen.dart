import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import 'deposit_opening_screen.dart'; // Ensure this is imported

class SuccessScreen extends StatelessWidget {
  final String title;
  final String message;

  const SuccessScreen({super.key, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // We use WillPopScope to disable the hardware back button
      // This forces the user to use our UI buttons for a safer flow
      body: WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(kPaddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🌟 Success Animation/Icon
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E7D32), // Emerald Green
                  size: 100,
                ),
                const SizedBox(height: kSpacingExtraLarge),

                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A237E), // Professional Navy
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kPaddingMedium),

                Text(
                  message,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // 1. PRIMARY BUTTON: BACK TO DEPOSIT OPENING
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigates to Deposit Opening and clears the "Success" screen
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const DepositOpeningScreen()),
                            (route) => route.isFirst,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A237E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text(
                      'OPEN ANOTHER DEPOSIT',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: kPaddingMedium),

                // 2. SECONDARY BUTTON: GO TO HOME
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: () {
                      // Clears everything and goes to Dashboard
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1A237E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text(
                      'GO TO DASHBOARD',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}