import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import '../theme/app_colors.dart';

class RegistrationStep4Finalize extends ConsumerWidget {
  const RegistrationStep4Finalize({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(registrationProvider);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.status == RegistrationStatus.loading) ...[
                const CircularProgressIndicator(color: kAccentOrange),
                const SizedBox(height: 20),
                const Text("Finalizing Device Binding..."),
              ],
              if (state.status == RegistrationStatus.success) ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 100),
                const SizedBox(height: 20),
                const Text("Device Bound Successfully!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(registrationProvider.notifier).reset(); // Clear state for next test
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                    child: const Text("GO TO LANDING PAGE", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
              if (state.status == RegistrationStatus.failure) ...[
                const Icon(Icons.error, color: Colors.red, size: 80),
                Text(state.errorMessage ?? "Error occurred"),
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("TRY AGAIN")),
              ]
            ],
          ),
        ),
      ),
    );
  }
}