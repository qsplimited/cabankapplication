import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../api/mock_otp_service.dart';

class CommonOtpScreen extends StatefulWidget {
  final String transactionTitle;
  final String subDetails;
  final String mobileNumber;
  final VoidCallback onSuccess;

  const CommonOtpScreen({
    Key? key,
    required this.transactionTitle,
    required this.subDetails,
    required this.mobileNumber,
    required this.onSuccess,
  }) : super(key: key);

  @override
  _CommonOtpScreenState createState() => _CommonOtpScreenState();
}

class _CommonOtpScreenState extends State<CommonOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (i) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (i) => FocusNode());
  final MockOtpService _otpService = MockOtpService();

  bool _isLoading = false;
  int _timerSeconds = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto focus the first box when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startTimer() {
    _timerSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) controller.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }

  void _handleVerify() async {
    String enteredOtp = _controllers.map((e) => e.text).join();

    if (enteredOtp.length < 6) {
      _showSnackBar("Please enter the full 6-digit code", Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      bool isValid = await _otpService.verifyOtp(widget.mobileNumber, enteredOtp);
      setState(() => _isLoading = false);

      if (isValid) {
        widget.onSuccess();
      } else {
        _showSnackBar("Incorrect OTP. Hint: Use $mockValidOtp", Colors.red);
        _clearOtpFields();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("An error occurred. Please try again.", Colors.red);
    }
  }

  void _clearOtpFields() {
    for (var controller in _controllers) controller.clear();
    _focusNodes[0].requestFocus();
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final double screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Close keyboard on tap outside
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : kLightBackground,
        appBar: AppBar(
          title: Text(widget.transactionTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: kAccentOrange,
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(kPaddingMedium),
                  child: Column(
                    children: [
                      const SizedBox(height: kSpacingExtraLarge),
                      _buildInfoArea(isDark),
                      const SizedBox(height: kSpacingExtraLarge),

                      // The 6 OTP Boxes
                      _buildOtpInputRow(screenWidth, isDark),

                      const SizedBox(height: kSpacingLarge),
                      _buildTimerText(),
                    ],
                  ),
                ),
              ),
              _buildFooterButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoArea(bool isDark) {
    return Column(
      children: [
        const CircleAvatar(
          backgroundColor: kAccentOrange,
          radius: 30,
          child: Icon(Icons.security_rounded, color: Colors.white, size: 35),
        ),
        const SizedBox(height: 16),
        const Text("Security Verification", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(widget.subDetails, textAlign: TextAlign.center, style: const TextStyle(color: kLightTextSecondary)),
      ],
    );
  }

  Widget _buildOtpInputRow(double screenWidth, bool isDark) {
    // Calculate box size dynamically for responsiveness
    double boxSize = (screenWidth - (kPaddingMedium * 2) - 40) / 6;
    if (boxSize > 55) boxSize = 55;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: boxSize,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : kBrandNavy),
            decoration: InputDecoration(
              counterText: "",
              filled: true,
              fillColor: isDark ? Colors.white10 : Colors.white,
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: kDividerColor),
                borderRadius: BorderRadius.circular(kRadiusSmall),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: kAccentOrange, width: 2),
                borderRadius: BorderRadius.circular(kRadiusSmall),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildTimerText() {
    return _timerSeconds > 0
        ? Text("Resend code in 00:$_timerSeconds", style: const TextStyle(color: kLightTextSecondary))
        : TextButton(
      onPressed: _startTimer,
      child: const Text("Resend OTP", style: TextStyle(color: kAccentOrange, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildFooterButton() {
    return Padding(
      padding: const EdgeInsets.all(kPaddingMedium),
      child: SizedBox(
        width: double.infinity,
        height: kButtonHeight,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kBrandNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
          ),
          onPressed: _isLoading ? null : _handleVerify,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text("VERIFY & CONFIRM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}