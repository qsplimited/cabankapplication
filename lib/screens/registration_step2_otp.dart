import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/i_device_service.dart';
import '../main.dart'; // To access globalDeviceService
import 'registration_step3_mpin.dart'; // NEW IMPORT

class RegistrationStep2Otp extends StatefulWidget {
  final String mobileNumber;

  const RegistrationStep2Otp({super.key, required this.mobileNumber});

  @override
  State<RegistrationStep2Otp> createState() => _RegistrationStep2OtpState();
}

class _RegistrationStep2OtpState extends State<RegistrationStep2Otp> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _handleOtpVerification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final otp = _otpController.text;
    final IDeviceService deviceService = globalDeviceService;

    try {
      // Calls the Mock API service (where OTP is checked against '123456')
      final success = await deviceService.verifyOtp(
        mobileNumber: widget.mobileNumber,
        otp: otp,
      );

      if (mounted) {
        if (success) {
          // Success: OTP is correct. Proceed to Step 3 (Set MPIN).
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP Verified successfully! Proceeding to Step 3: Set MPIN.'),
              backgroundColor: Colors.green,
            ),
          );

          // --- NAVIGATION TO STEP 3 ---
          // Use pushReplacement to prevent the user from going back to the OTP screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RegistrationStep3Mpin(mobileNumber: widget.mobileNumber),
            ),
          );

        } else {
          setState(() {
            _errorMessage = 'OTP is incorrect or expired. Please check the code.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred during verification. Please retry.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
                'Enter the 6-digit verification code sent to:',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                // Displays the mobile number with the first 6 digits masked
                'XXXXXX${widget.mobileNumber.substring(6)}',
                style: theme.textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // OTP Input Field
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium!.copyWith(letterSpacing: 10),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '• • • • • •',
                  counterText: '', // Hide length counter
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Please enter the 6-digit OTP.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Error Message Display
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium!.copyWith(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 40),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleOtpVerification,
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('VERIFY CODE'),
              ),
              const SizedBox(height: 20),

              // Resend OTP Link
              TextButton(
                onPressed: _isLoading ? null : () {
                  // In a real app, this would call globalDeviceService.resendOtp(...)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('OTP Resend functionality is currently mocked.'),
                    ),
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
