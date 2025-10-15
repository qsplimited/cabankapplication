import 'package:flutter/material.dart';
import '../main.dart'; // Needed to access globalDeviceService
import 'registration_step2_otp.dart'; // IMPORTANT: New Import for Step 2

class RegistrationStep1Identity extends StatefulWidget {
  const RegistrationStep1Identity({super.key});

  @override
  State<RegistrationStep1Identity> createState() => _RegistrationStep1IdentityState();
}

class _RegistrationStep1IdentityState extends State<RegistrationStep1Identity> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _accountController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // --- Handle Verification Logic ---
  void _handleVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String accountNumber = _accountController.text.trim();
      final String mobileNumber = _mobileController.text.trim();
      final String dateOfBirth = _dobController.text.trim();

      // Call the Mock API service
      final response = await globalDeviceService.verifyIdentity(
        accountNumber: accountNumber,
        mobileNumber: mobileNumber,
        dateOfBirth: dateOfBirth,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response['success'] == true) {
          // ----------------------------------------------------
          // SUCCESS PATH: Identity Matched! Proceed to Step 2 (OTP)
          // ----------------------------------------------------

          // Show the fixed OTP in a dialogue for DEVELOPMENT/TESTING only,
          // then navigate to the next screen.
          _showOtpSentDialog(
            response['message'] as String,
            mobileNumber, // Pass mobile number for navigation
          );

        } else {
          // FAILURE PATH: Identity mismatch
          setState(() {
            _errorMessage = response['message'] as String;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'A network error occurred. Please check your connection.';
        });
      }
    }
  }

  // Helper function to display the Mock OTP code to the developer
  void _showOtpSentDialog(String message, String mobileNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('OTP Sent (Dev Mode)', style: TextStyle(color: Colors.green)),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK, Proceed'),
              onPressed: () {
                // 1. Dismiss the dialog
                Navigator.of(context).pop();

                // 2. Navigate to the OTP verification screen, passing the mobile number
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RegistrationStep2Otp(mobileNumber: mobileNumber),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Function to open the Date Picker for DOB input
  Future<void> _selectDate() async {
    // Current date minus 18 years as the maximum initial date for registration
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );
    if (picked != null) {
      // Format the date as DD/MM/YYYY to match the mock service format
      String formattedDate = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      setState(() {
        _dobController.text = formattedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('1/4: Identity Verification'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Enter details registered with the bank for verification.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 30),

              // 1. Account Number Field
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  hintText: 'Enter your 10-15 digit Account Number',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || value.length < 6) {
                    return 'Please enter a valid Account Number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. Mobile Number Field
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  labelText: 'Registered Mobile Number',
                  hintText: 'e.g., 9999999999 (Test: 9999999999)',
                  prefixIcon: Icon(Icons.phone_android),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.length != 10) {
                    return 'Mobile Number must be 10 digits.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 3. Date of Birth Field
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date of Birth (DD/MM/YYYY)',
                  hintText: 'Select your registered Date of Birth (Test: 01/01/1980)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down, color: theme.primaryColor),
                ),
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your Date of Birth.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Error Message Display
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
                onPressed: _isLoading ? null : _handleVerification,
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
                    : const Text('VERIFY IDENTITY', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
