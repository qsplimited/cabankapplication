import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import '../theme/app_colors.dart';

class RegistrationStep4Finalize extends ConsumerWidget {
  const RegistrationStep4Finalize({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the state to react to success/failure/loading
    final state = ref.watch(registrationProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. LOADING STATE
                if (state.status == RegistrationStatus.loading) ...[
                  const CircularProgressIndicator(color: kAccentOrange),
                  const SizedBox(height: 20),
                  const Text("Securing your account...",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],

                // 2. SUCCESS STATE (Matching value: true from Swagger)
                if (state.status == RegistrationStatus.success) ...[
                  const Icon(Icons.phonelink_lock, color: Colors.green, size: 100),
                  const SizedBox(height: 24),
                  const Text(
                    "Device Linked Successfully!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Your MPIN is set. Please login to verify your device binding.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(registrationProvider.notifier).reset();
                        // Go to Login to perform the final GET bympin check
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                      child: const Text("PROCEED TO LOGIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],

                // 3. FAILURE STATE
                if (state.status == RegistrationStatus.failure) ...[
                  const Icon(Icons.error_outline, color: Colors.red, size: 80),
                  const SizedBox(height: 16),
                  const Text("Finalization Failed",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? "An unexpected error occurred",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("TRY AGAIN",
                        style: TextStyle(color: kAccentOrange, fontWeight: FontWeight.bold)),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}