import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/registration_bloc.dart';
import '../event/registration_event.dart';
import '../state/registration_state.dart';
import 'registration_step3_mpin.dart';
import 'forgot_mpin_step2_new_mpin.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class RegistrationStep2Otp extends StatefulWidget {
  const RegistrationStep2Otp({super.key});

  @override
  State<RegistrationStep2Otp> createState() => _RegistrationStep2OtpState();
}

class _RegistrationStep2OtpState extends State<RegistrationStep2Otp> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() => setState(() {}));
  }

  void _verifyOtp() {
    if (_otpController.text.length == 6) {
      context.read<RegistrationBloc>().add(OtpVerified(_otpController.text.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<RegistrationBloc, RegistrationState>(
      listener: (context, state) {
        if (state.currentStep == 2) {
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => state.isResetFlow
                  ? const ForgotMpinStep2NewMpin()
                  : const RegistrationStep3Mpin()
          ));
        } else if (state.status == RegistrationStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? "Invalid OTP"))
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('OTP Verification'),
          backgroundColor: kAccentOrange,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Verify your Identity",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Enter the 6-digit code sent to your device",
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 40),

              // RESTORED DESIGN: Stack to prevent overlapping
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(counterText: ""),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (index) => _buildOtpBox(index)),
                  ),
                ],
              ),

              const Spacer(),

              BlocBuilder<RegistrationBloc, RegistrationState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    height: kButtonHeight,
                    child: ElevatedButton(
                      onPressed: state.status == RegistrationStatus.loading ? null : _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                      ),
                      child: state.status == RegistrationStatus.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "VERIFY OTP",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isFilled = _otpController.text.length > index;
    bool isFocused = _otpController.text.length == index;
    String char = isFilled ? _otpController.text[index] : "";

    return Container(
      width: 48,
      height: 58,
      decoration: BoxDecoration(
        color: isFocused ? kAccentOrange.withOpacity(0.05) : colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFocused ? kAccentOrange : colorScheme.outline.withOpacity(0.2),
          width: isFocused ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}