/*
// lib/screens/forgot_mpin_step1_identity.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import 'registration_step2_otp.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class ForgotMpinStep1Identity extends ConsumerStatefulWidget {
  const ForgotMpinStep1Identity({super.key});
  @override
  ConsumerState<ForgotMpinStep1Identity> createState() => _ForgotMpinStep1IdentityState();
}

class _ForgotMpinStep1IdentityState extends ConsumerState<ForgotMpinStep1Identity> {
  final _custId = TextEditingController();
  final _pass = TextEditingController();

  @override
  Widget build(BuildContext context) {
    ref.listen(registrationProvider, (prev, next) {
      if (next.currentStep == 1 && prev?.currentStep == 0) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationStep2Otp()));
      }
    });

    final state = ref.watch(registrationProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Verify Identity"), backgroundColor: kAccentOrange),
      body: Padding(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          children: [
            TextField(controller: _custId, decoration: const InputDecoration(labelText: "Customer ID")),
            const SizedBox(height: 20),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: state.status == RegistrationStatus.loading ? null : () =>
                    ref.read(registrationProvider.notifier).submitResetIdentity(_custId.text, _pass.text),
                style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                child: state.status == RegistrationStatus.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("VERIFY & SEND OTP", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}*/
