import 'package:flutter/material.dart';
import '../main.dart'; // Needed to access globalDeviceService
import 'registration_step2_otp.dart'; // IMPORTANT: New Import for Step 2
import 'registration_step3_mpin.dart'; // Needed for the successRoute
// Import the necessary dimension and color constants
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

class RegistrationStep1Identity extends StatefulWidget {
  const RegistrationStep1Identity({super.key});

  @override
  State<RegistrationStep1Identity> createState() => _RegistrationStep1IdentityState();
}

class _RegistrationStep1IdentityState extends State<RegistrationStep1Identity> {
  final _formKey = GlobalKey<FormState>();
  // Pre-populating with mock data for easy testing:
  final TextEditingController _accountController = TextEditingController(text: '123456');
  final TextEditingController _mobileController = TextEditingController(text: '9999999999');
  final TextEditingController _dobController = TextEditingController(text: '01/01/1980');

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
      // Assuming globalDeviceService is accessible via the main import path
      // Logic preserved.
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
          final String otpCode = response['otp_code'] as String;
          final String verifiedMobile = response['mobile_number'] as String;

          // Show the fixed OTP in a dialogue for DEVELOPMENT/TESTING only,
          // then navigate to the next screen.
          _showOtpSentDialog(
            response['message'] as String,
            otpCode, // Pass OTP code
            verifiedMobile, // Pass mobile number
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
  void _showOtpSentDialog(String message, String otpCode, String mobileNumber) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          // Use theme radius constant
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
          title: Text(
            'OTP Sent (Dev Mode)',
            // Replace hardcoded color with semantic kSuccessGreen or colorScheme.secondary
            style: textTheme.titleLarge?.copyWith(color: kSuccessGreen),
          ),
          content: Text(message, style: textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK, Proceed',
                // Use primary color for action button text
                style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
              ),
              onPressed: () {
                // 1. Dismiss the dialog
                Navigator.of(context).pop();

                // 2. Navigate to the OTP verification screen, passing all REQUIRED parameters
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => RegistrationStep2Otp(
                      mobileNumber: mobileNumber,
                      otpCode: otpCode,
                      // The success route for registration is Step 3: Set MPIN
                      successRoute: RegistrationStep3Mpin(mobileNumber: mobileNumber),
                    ),
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
      // Customising DatePicker theme to match app theme
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary, // Primary color for header/buttons
              onPrimary: Theme.of(context).colorScheme.onPrimary, // Text color on primary
              surface: Theme.of(context).colorScheme.surface, // Background color
              onSurface: Theme.of(context).colorScheme.onSurface, // Text/icon color
            ),
            textTheme: Theme.of(context).textTheme,
          ),
          child: child!,
        );
      },
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
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('1/4: Identity Verification'),
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
                'Enter details registered with the bank for verification.',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.8), // Slightly less dominant than primary text
                ),
              ),
              // Replace hardcoded 30 with kSpacingLarge
              const SizedBox(height: kSpacingLarge),

              // 1. Account Number Field
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.number,
                // InputDecoration uses InputDecorationTheme from app_theme.dart
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
              // Replace hardcoded 20 with kPaddingLarge - 4
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
                  // 'counterText: '' ' is okay to keep as a specific design choice
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.length != 10) {
                    return 'Mobile Number must be 10 digits.';
                  }
                  return null;
                },
              ),
              // Replace hardcoded 20 with kPaddingLarge - 4
              const SizedBox(height: 20),

              // 3. Date of Birth Field
              TextFormField(
                controller: _dobController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Date of Birth (DD/MM/YYYY)',
                  hintText: 'Select your registered Date of Birth (Test: 01/01/1980)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  // Use primary color for the suffix icon
                  suffixIcon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                ),
                onTap: _selectDate,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your Date of Birth.';
                  }
                  return null;
                },
              ),
              // Replace hardcoded 30 with kSpacingLarge
              const SizedBox(height: kSpacingLarge),

              // Error Message Display
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
                onPressed: _isLoading ? null : _handleVerification,
                // Style is largely managed by ElevatedButtonThemeData in app_theme.dart
                style: ElevatedButton.styleFrom(
                  // Remove hardcoded padding and shape as they are defined in app_theme.dart
                  // The existing style overrides are:
                  // padding: const EdgeInsets.symmetric(vertical: 16), // Use kButtonHeight if necessary, but theme handles it
                  // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Theme uses kRadiusSmall (8.0)
                  // Removing the override to use the centralized theme's style
                ),
                child: _isLoading
                    ? SizedBox(
                  // Replace hardcoded 20 with kIconSizeSmall
                  width: kIconSizeSmall,
                  height: kIconSizeSmall,
                  child: CircularProgressIndicator(
                    // Progress indicator color should be colorScheme.onPrimary for visibility on the primary button
                    color: colorScheme.onPrimary,
                    // Hardcoded strokeWidth is fine, but can be replaced if a constant exists
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'VERIFY IDENTITY',
                  // Text style is handled by the theme (labelLarge with 16pt font)
                  style: textTheme.labelLarge?.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}