import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/mock_otp_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../providers/otp_provider.dart';

class OtpVerificationDialog extends ConsumerStatefulWidget {
  final OtpService otpService; // RESTORED: Existing screens need this
  final String mobileNumber;
  final String screenId; // ADDED: For Riverpod state separation

  const OtpVerificationDialog({
    super.key,
    required this.otpService, // Keeps RD/FD screens happy
    required this.mobileNumber,
    this.screenId = "GENERIC_OTP", // Default value so it's not required
  });

  @override
  ConsumerState<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends ConsumerState<OtpVerificationDialog> {
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Use the provider's timer instead of local timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otpProvider(widget.screenId).notifier).startTimer();
    });
  }

  String get _currentOtp => _otpControllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpProvider(widget.screenId));
    final otpNotifier = ref.read(otpProvider(widget.screenId).notifier);
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('OTP Verification Required', style: textTheme.titleLarge?.copyWith(color: kBrandNavy)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Sent to ****${widget.mobileNumber.substring(widget.mobileNumber.length - 4)}'),
          const SizedBox(height: kPaddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) => _buildOtpBox(index)),
          ),
          if (otpState.errorMessage != null)
            Text(otpState.errorMessage!, style: const TextStyle(color: kErrorRed, fontSize: 12)),
          const SizedBox(height: kPaddingSmall),
          otpState.resendSeconds > 0
              ? Text('Resend in ${otpState.resendSeconds}s')
              : TextButton(onPressed: otpNotifier.startTimer, child: const Text('RESEND OTP')),
          const SizedBox(height: kPaddingLarge),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
              onPressed: otpState.isVerifying ? null : () async {
                bool success = await otpNotifier.verify(widget.mobileNumber, _currentOtp);
                if (success && mounted) {
                  Navigator.of(context).pop(_currentOtp);
                }
              },
              child: otpState.isVerifying ? const CircularProgressIndicator(color: Colors.white) : const Text('VERIFY', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('CANCEL', style: TextStyle(color: kErrorRed))),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 38, height: 45,
      child: TextFormField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: InputDecoration(counterText: '', filled: true, fillColor: kInputBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSmall))),
        onChanged: (value) {
          if (value.length == 1 && index < 5) _focusNodes[index + 1].requestFocus();
          if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
        },
      ),
    );
  }
}