import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart'; // Access to globalDeviceService

// CRITICAL FIX: The successRoute must be of type Widget to accept any screen.
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
  final TextEditingController _otpController = TextEditingController();

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('2/4: OTP Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Enter the 6-digit OTP sent to your mobile number:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Text(
                widget.mobileNumber,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
              ),
              const SizedBox(height: 30),

              // 1. OTP Input Field
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: theme.textTheme.headlineMedium,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Enter OTP',
                  hintText: '• • • • • •',
                  counterText: '',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Please enter the 6-digit OTP.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),


              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    _errorMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Submission Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('VERIFY OTP', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 20),
              TextButton(
                onPressed: _isLoading ? null : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock: New OTP sent! (Still 123456)')),
                  );
                },
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
