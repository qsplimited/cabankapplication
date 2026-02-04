import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import 'registration_step2_otp.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class ForgotMpinIdentity extends ConsumerStatefulWidget {
  final String? autoCustomerId;
  const ForgotMpinIdentity({super.key, this.autoCustomerId});

  @override
  ConsumerState<ForgotMpinIdentity> createState() => _ForgotMpinIdentityState();
}

class _ForgotMpinIdentityState extends ConsumerState<ForgotMpinIdentity> {
  final _passController = TextEditingController();
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);
    final displayId = regState.customerId ?? widget.autoCustomerId;

    ref.listen(registrationProvider, (prev, next) {
      if (next.status == RegistrationStatus.success && next.currentStep == 1) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationStep2Otp()));
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text("Verify Account"), backgroundColor: kAccentOrange),
      body: Padding(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Customer ID", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: Text(displayId ?? "Loading...", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            const Text("Security Password", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: _passController,
              obscureText: _isObscured,
              decoration: InputDecoration(
                hintText: "Enter password to receive OTP",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: (displayId == null || regState.status == RegistrationStatus.loading)
                    ? null
                    : () => ref.read(registrationProvider.notifier).submitIdentity(displayId, _passController.text),
                style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                child: regState.status == RegistrationStatus.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("SEND OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}