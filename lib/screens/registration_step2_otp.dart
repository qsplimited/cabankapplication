import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart'; // Access to globalDeviceService
// Import the necessary dimension constants
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';


// CRITICAL FIX: The successRoute must be of type Widget to accept any screen.
// This is already correct in the user's code, but redefining for clarity.
typedef SuccessRouteBuilder = Widget;

class RegistrationStep2Otp extends StatefulWidget {
  final String mobileNumber;
  // REQUIRED: The actual OTP code expected for verification (used in the mock service)
  final String otpCode;
  // REQUIRED: The widget (screen) to navigate to after successful OTP verification
  final SuccessRouteBuilder successRoute;

  const RegistrationStep2Otp({
    super.key,
    required this.mobileNumber,
    required this.otpCode,
    required this.successRoute,
  });

  @override
  State<RegistrationStep2Otp> createState() => _RegistrationStep2OtpState();
}

class _RegistrationStep2OtpState extends State<RegistrationStep2Otp> {
  final _formKey = GlobalKey<FormState>();
  // Pre-populating with mock data for easy testing:
  final TextEditingController _otpController = TextEditingController(text: '123456');

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  // --- Handle OTP Verification Logic ---
  void _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String enteredOtp = _otpController.text.trim();

      // Logic preserved.
      final bool success = await globalDeviceService.verifyOtp(
        mobileNumber: widget.mobileNumber,
        otp: enteredOtp,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          // SUCCESS PATH: Navigate to the designated success route
          Navigator.of(context).push(
            MaterialPageRoute(
              // Use the provided successRouteBuilder to build the next screen
              builder: (context) => widget.successRoute,
            ),
          );
        } else {
          // FAILURE PATH: OTP mismatch
          setState(() {
            _errorMessage = 'Invalid OTP. Please check the code and try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'A network error occurred during OTP verification.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('2/4: OTP Verification'),
      ),
      body: SingleChildScrollView(
        // Replace hardcoded 24.0 with kPaddingLarge
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Enter the 6-digit OTP sent to your mobile number:',
                style: textTheme.titleMedium,
              ),
              // Replace hardcoded 10 with kPaddingTen
              const SizedBox(height: kPaddingTen),
              Text(
                widget.mobileNumber,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  // Use primary color for the highlighted mobile number
                  color: colorScheme.primary,
                ),
              ),
              // Replace hardcoded 30 with kSpacingLarge
              const SizedBox(height: kSpacingLarge),

              // 1. OTP Input Field
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                // Use a large headline style for the OTP digits
                style: textTheme.headlineMedium,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // InputDecoration uses InputDecorationTheme from app_theme.dart
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  hintText: '• • • • • •',
                  counterText: '', // Keep as specific design choice
                  // Explicit OutlineInputBorder is redundant if defined in theme,
                  // but kept for specific OTP field styling if needed.
                  // Removing it to rely on the centralized theme.
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Please enter the 6-digit OTP.';
                  }
                  return null;
                },
              ),
              // Replace hardcoded 20 with kPaddingLarge - 4
              const SizedBox(height: 20),


              if (_errorMessage.isNotEmpty)
                Padding(
                  // Replace hardcoded 20.0 with kPaddingLarge - 4
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    _errorMessage,
                    // Use error color from the colorScheme
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Submission Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                // Rely on centralized ElevatedButtonThemeData (app_theme.dart)
                child: _isLoading
                    ? SizedBox(
                  // Replace hardcoded 20 with kIconSizeSmall
                  width: kIconSizeSmall,
                  height: kIconSizeSmall,
                  child: CircularProgressIndicator(
                    // Progress indicator color should be colorScheme.onPrimary for visibility
                    color: colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'VERIFY OTP',
                  // Text style is handled by the theme (labelLarge with 16pt font)
                  style: textTheme.labelLarge?.copyWith(fontSize: 16),
                ),
              ),

              // Replace hardcoded 20 with kPaddingLarge - 4
              const SizedBox(height: 20),
              TextButton(
                onPressed: _isLoading ? null : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      // Use theme colors for SnackBar background/text
                      backgroundColor: colorScheme.secondary,
                      content: Text(
                        'Mock: New OTP sent! (Still ${widget.otpCode})',
                        style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSecondary // Text color for secondary background
                        ),
                      ),
                    ),
                  );
                },
                // TextButton style is handled by the centralized theme
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}