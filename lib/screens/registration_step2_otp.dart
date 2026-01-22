import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import 'registration_step3_mpin.dart';
import 'forgot_mpin_step2_new_mpin.dart';
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

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Rebuild UI as user types to fill boxes
    _otpController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _canResend = false;
      _secondsRemaining = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() => _canResend = true);
        timer.cancel();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _handleResend() {
    if (_canResend) {
      _otpController.clear();
      _startTimer();

      // Trigger API
      ref.read(registrationProvider.notifier).resendOtp();

      // IMPORTANT: Request focus AFTER a frame is drawn to ensure keyboard pops up
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("A new OTP has been sent.")),
      );
    }
  }

  void _handleVerify() {
    if (_otpController.text.length == 6) {
      ref.read(registrationProvider.notifier).verifyOtp(_otpController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registrationProvider);

    // Navigation Listener
    ref.listen(registrationProvider, (previous, next) {
      if (next.currentStep == 2 && previous?.currentStep != 2) {
        if (next.isResetFlow) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ForgotMpinStep2NewMpin()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RegistrationStep3Mpin()));
        }
      }
      if (next.status == RegistrationStatus.failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage ?? "Invalid OTP"), backgroundColor: Colors.red),
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
            const Text("Code sent to your mobile number", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 50),

            // FIXED INPUT AREA
            GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              behavior: HitTestBehavior.opaque,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Hidden TextField
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
                  // Visual Boxes - IgnorePointer ensures taps go TO the TextField
                  IgnorePointer(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) => _buildOtpBox(index)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Resend Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive code? "),
                TextButton(
                  onPressed: _canResend ? _handleResend : null,
                  child: Text(
                    _canResend ? "Resend OTP" : "Resend in ${_secondsRemaining}s",
                    style: TextStyle(
                        color: _canResend ? kAccentOrange : Colors.grey,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ],
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
    // Box is highlighted if it's the current active index
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