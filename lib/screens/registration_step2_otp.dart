import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

class RegistrationStep2Otp extends StatefulWidget {
  final String otpCode;
  final String? sessionId;
  final Widget nextScreen;

  const RegistrationStep2Otp({
    super.key,
    required this.otpCode,
    required this.nextScreen,
    this.sessionId,
  });

  @override
  State<RegistrationStep2Otp> createState() => _RegistrationStep2OtpState();
}

class _RegistrationStep2OtpState extends State<RegistrationStep2Otp> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // This rebuilds the UI to show digits in boxes as the user types
    _otpController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    if (_otpController.text.length < 6) return;

    setState(() => _isLoading = true);

    final bool success = await globalDeviceService.verifyOtp(
      otp: _otpController.text.trim(),
      sessionId: widget.sessionId,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => widget.nextScreen),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please check and try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kAccentOrange,
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(kPaddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    // Standard Professional Heading
                    Text(
                      'Verify your Number',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Professional Sub-text
                    Text(
                      'Please enter the 6-digit verification code sent to your registered mobile device.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        height: 1.4, // Improved readability
                      ),
                    ),
                    const SizedBox(height: 50),

                    // --- Attractive Box Design for OTP ---
                    GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(6, (index) => _buildOtpBox(index)),
                          ),
                          // Hidden text field
                          Opacity(
                            opacity: 0,
                            child: TextFormField(
                              controller: _otpController,
                              focusNode: _focusNode,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              autofocus: true,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              onChanged: (value) {
                                if (value.length == 6) _verifyOtp(); // Auto-verify on 6th digit
                              },
                              decoration: const InputDecoration(counterText: ""),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Verify Button ---
            Padding(
              padding: const EdgeInsets.all(kPaddingLarge),
              child: SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: ElevatedButton(
                  onPressed: (_isLoading || _otpController.text.length < 6)
                      ? null
                      : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : const Text(
                    'VERIFY OTP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                  ),
                ),
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(10), // Standard rounded look
        border: Border.all(
          color: isFocused ? kAccentOrange : colorScheme.outline.withOpacity(0.2),
          width: isFocused ? 2 : 1.5,
        ),
      ),
      child: Center(
        child: Text(
          char,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}