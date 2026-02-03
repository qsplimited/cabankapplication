import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import 'registration_step3_mpin.dart';
// import 'forgot_mpin_step2_new_mpin.dart'; // PAUSED: Not needed for registration flow
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class RegistrationStep2Otp extends ConsumerStatefulWidget {
  const RegistrationStep2Otp({super.key});

  @override
  ConsumerState<RegistrationStep2Otp> createState() => _RegistrationStep2OtpState();
}

class _RegistrationStep2OtpState extends ConsumerState<RegistrationStep2Otp> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- RESEND LOGIC COMMENTED OUT AS REQUESTED ---
  /*
  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  ... (timer methods)
  */

  void _handleVerify() {
    final otp = _otpController.text.trim();
    if (otp.length == 6) {
      // Calls: GET /customer/otp/validate
      ref.read(registrationProvider.notifier).verifyOtp(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);

    // NAVIGATION LISTENER
    ref.listen(registrationProvider, (previous, next) {
      if (next.currentStep == 2 && previous?.currentStep != 2) {

        // --- FORGOT FLOW NAVIGATION COMMENTED OUT ---
        /*
        if (next.isResetFlow) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ForgotMpinStep2NewMpin())
          );
        } else { ... }
        */

        // ALWAYS move to Step 3 for now to keep the flow simple
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RegistrationStep3Mpin())
        );
      }

      if (next.status == RegistrationStatus.failure && previous?.status != RegistrationStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(next.errorMessage ?? "Invalid OTP"),
              backgroundColor: Colors.red
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification', style: TextStyle(color: Colors.white)),
        backgroundColor: kAccentOrange,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.lock_reset_rounded, size: 80, color: kAccentOrange),
            const SizedBox(height: 20),
            const Text("Enter 6-Digit OTP", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("A code has been sent to your mobile", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),

            // OTP INPUT BOXES
            GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 58,
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        autofocus: true,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (val) {
                          if (val.length == 6) _handleVerify();
                        },
                      ),
                    ),
                  ),
                  IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) => _buildOtpBox(index)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: (regState.status == RegistrationStatus.loading || _otpController.text.length < 6)
                    ? null
                    : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentOrange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                ),
                child: regState.status == RegistrationStatus.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("VERIFY OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    bool isFilled = _otpController.text.length > index;
    bool isFocused = _focusNode.hasFocus && _otpController.text.length == index;

    return Container(
      width: 48,
      height: 58,
      decoration: BoxDecoration(
        color: isFocused ? kAccentOrange.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFocused ? kAccentOrange : Colors.grey.shade300,
          width: isFocused ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: Text(
          isFilled ? _otpController.text[index] : "",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}