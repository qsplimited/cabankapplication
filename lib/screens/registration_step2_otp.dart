import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import 'registration_step3_mpin.dart';
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
    // Auto-focus the field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleVerify() {
    final otp = _otpController.text.trim();
    if (otp.length == 6) {
      // Calls: GET /customer/otp/validate in the provider
      ref.read(registrationProvider.notifier).verifyOtp(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);

    // NAVIGATION AND ERROR LISTENER
    ref.listen(registrationProvider, (previous, next) {
      // 1. Success Navigation: If step moves to 2, go to Set MPIN screen
      if (next.status == RegistrationStatus.success && next.currentStep == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RegistrationStep3Mpin()),
        );
      }

      // 2. Error Handling: Show snackbar if OTP is invalid
      if (next.status == RegistrationStatus.failure && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _otpController.clear();
        _focusNode.requestFocus();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: kAccentOrange),
            const SizedBox(height: 24),
            const Text("Verify Your Identity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              "OTP sent for Customer ID: ${regState.customerId ?? 'User'}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 50),

            // OTP INPUT BOXES
            GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Hidden TextField to capture input
                  SizedBox(
                    height: 58,
                    child: Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (val) {
                          setState(() {}); // Rebuild to update visual boxes
                          if (val.length == 6) _handleVerify();
                        },
                      ),
                    ),
                  ),
                  // Visual OTP Boxes
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

            // VERIFY BUTTON
            SizedBox(
              width: double.infinity,
              height: kButtonHeight,
              child: ElevatedButton(
                onPressed: (regState.status == RegistrationStatus.loading || _otpController.text.length < 6)
                    ? null
                    : _handleVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccentOrange,
                  disabledBackgroundColor: kAccentOrange.withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                ),
                child: regState.status == RegistrationStatus.loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("VERIFY OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
        color: isFocused ? kAccentOrange.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(
          color: isFocused ? kAccentOrange : Colors.grey.shade300,
          width: isFocused ? 2.5 : 1.5,
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