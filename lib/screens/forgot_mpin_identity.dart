import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import 'registration_step2_otp.dart';
import '../theme/app_colors.dart';

class ForgotMpinIdentity extends ConsumerWidget {
  final String? autoCustomerId;
  const ForgotMpinIdentity({super.key, this.autoCustomerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(registrationProvider, (prev, next) {
      if (next.status == RegistrationStatus.success && next.currentStep == 1) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationStep2Otp()));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Forgot MPIN"), backgroundColor: kAccentOrange),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text("Customer ID", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(
                autoCustomerId ?? "Not Found",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (autoCustomerId == null) ? null : () {
                  // Sends ID with empty password to trigger OTP
                  ref.read(registrationProvider.notifier).submitIdentity(autoCustomerId!, "");
                },
                style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                child: const Text("SEND OTP", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}