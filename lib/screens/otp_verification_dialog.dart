import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/mock_otp_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../providers/otp_provider.dart';

class OtpVerificationDialog extends ConsumerStatefulWidget {
  final OtpService otpService;
  final String mobileNumber;
  final String screenId;

  const OtpVerificationDialog({
    super.key,
    required this.otpService,
    required this.mobileNumber,
    this.screenId = "GENERIC_OTP",
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(otpProvider(widget.screenId).notifier).startTimer();
    });
  }

  String get _currentOtp => _otpControllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpProvider(widget.screenId));
    final otpNotifier = ref.read(otpProvider(widget.screenId).notifier);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
      content: SizedBox(
        width: double.maxFinite,
        // FIX: ScrollView prevents the RenderFlex error when keyboard appears
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.security, size: 48, color: kAccentOrange),
              const SizedBox(height: kPaddingMedium),
              const Text('OTP Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: kPaddingSmall),
              Text('Sent to ****${widget.mobileNumber.substring(widget.mobileNumber.length > 4 ? widget.mobileNumber.length - 4 : 0)}',
                  textAlign: TextAlign.center),
              const SizedBox(height: kPaddingLarge),

              // OTP BOXES ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) => _buildOtpBox(index)),
              ),

              if (otpState.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(otpState.errorMessage!, style: const TextStyle(color: kErrorRed, fontSize: 12)),
                ),

              const SizedBox(height: kPaddingMedium),

              otpState.resendSeconds > 0
                  ? Text('Resend in ${otpState.resendSeconds}s', style: const TextStyle(color: Colors.grey))
                  : TextButton(onPressed: otpNotifier.startTimer, child: const Text('RESEND OTP')),

              const SizedBox(height: kPaddingLarge),

              // VERIFY BUTTON
              SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                  onPressed: otpState.isVerifying ? null : () async {
                    bool success = await otpNotifier.verify(widget.mobileNumber, _currentOtp);
                    if (success && mounted) {
                      Navigator.of(context).pop(_currentOtp);
                    }
                  },
                  child: otpState.isVerifying
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('VERIFY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('CANCEL', style: TextStyle(color: kErrorRed))
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    // Flexible handles the "6.7 pixel" horizontal overflow by resizing based on screen width
    return Flexible(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 50,
        child: TextFormField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          maxLength: 1,
          decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.grey[200],
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(kRadiusSmall), borderSide: BorderSide.none)
          ),
          onChanged: (value) {
            if (value.length == 1 && index < 5) _focusNodes[index + 1].requestFocus();
            if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();
          },
        ),
      ),
    );
  }
}