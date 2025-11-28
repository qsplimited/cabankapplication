// File: lib/screens/forgot_mpin_step1_identity.dart (Refactored)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'forgot_mpin_step2_new_mpin.dart';
import 'registration_step2_otp.dart';

// 💡 IMPORTANT: Import centralized design files
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';


String formatDate(DateTime date) {
  // NOTE: This utility function is fine as is, using standard Dart formatting.
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class ForgotMpinStep1Identity extends StatefulWidget {
  const ForgotMpinStep1Identity({super.key});

  @override
  State<ForgotMpinStep1Identity> createState() => _ForgotMpinStep1IdentityState();
}

class _ForgotMpinStep1IdentityState extends State<ForgotMpinStep1Identity> {
  final _formKey = GlobalKey<FormState>();
  // Pre-populating with mock data for easy testing:
  final _accountController = TextEditingController(text: '123456');
  final _mobileController = TextEditingController(text: '9999999999');
  final _dobController = TextEditingController(text: '01/01/1980');
  bool _isLoading = false;

  @override
  void dispose() {
    _accountController.dispose();
    _mobileController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    // Set initial date to a reasonable birth date for faster selection
    DateTime initialDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    if (_dobController.text.isNotEmpty) {
      try {
        final parts = _dobController.text.split('/');
        // Note: Date parts are DD/MM/YYYY
        initialDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } catch (_) {
        // Use default initialDate if parsing fails
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Birth',
      // CRITICAL: Apply Theme for Date Picker Dialog
      builder: (context, child) {
        final colorScheme = Theme.of(context).colorScheme;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme.copyWith(
              primary: colorScheme.primary, // Use primary color for header/buttons
              onPrimary: colorScheme.onPrimary, // Text on primary
              surface: colorScheme.surface, // Background of calendar
              onSurface: colorScheme.onSurface, // Text on surface
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dobController.text = formatDate(picked);
      });
    }
  }

  Future<void> _verifyIdentity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String accountNumber = _accountController.text.trim();
    final String mobileNumber = _mobileController.text.trim();
    final String dateOfBirth = _dobController.text.trim();

    // Get theme colors for SnackBar
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    try {
      final result = await globalDeviceService.verifyIdentity(
        accountNumber: accountNumber,
        mobileNumber: mobileNumber,
        dateOfBirth: dateOfBirth,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          final String otpCode = result['otp_code'] as String;
          final String verifiedMobile = result['mobile_number'] as String;

          // Show Mock OTP (for demonstration purposes only)
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              // Refactored Border Radius
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
              title: Text(
                'MOCK: OTP Generated',
                // Refactored color to theme error color
                style: textTheme.titleMedium?.copyWith(color: colorScheme.error),
              ),
              content: Text(
                'For testing, please use this OTP: $otpCode. \n\n'
                    'In the real world, this is sent securely to $verifiedMobile.',
                // Uses default text style, which is theme-compliant
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Navigate to the reusable OTP validation screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RegistrationStep2Otp(
                          mobileNumber: verifiedMobile,
                          otpCode: otpCode,
                          // CRITICAL: Success screen is the MPIN Reset Step 2
                          successRoute: ForgotMpinStep2NewMpin(),
                        ),
                      ),
                    );
                  },
                  // Uses default TextButton style, which is theme-compliant
                  child: const Text('OK, Proceed'),
                ),
              ],
            ),
          );
        } else {
          // Refactored SnackBar background color to theme error color
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] as String), backgroundColor: colorScheme.error),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Refactored SnackBar background color to theme error color
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Network error or unexpected issue occurred.'), backgroundColor: colorScheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        // AppBar title will inherit theme styles from the main app theme.
        title: const Text('Forgot MPIN - Step 1'),
      ),
      body: SingleChildScrollView(
        // Replaced hardcoded 16.0 with kPaddingMedium
        padding: const EdgeInsets.all(kPaddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Verify your identity to reset your M-PIN.',
                // Replaced hardcoded style with theme text style
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              // Replaced hardcoded 24.0 with kPaddingLarge
              const SizedBox(height: kPaddingLarge),

              // Account Number Field
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  hintText: 'Test: 123456',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(),
                  // The colors of the border and icon will now respect the theme
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Account Number.';
                  }
                  return null;
                },
              ),
              // Replaced hardcoded 16.0 with kPaddingMedium
              const SizedBox(height: kPaddingMedium),

              // Mobile Number Field
              TextFormField(
                controller: _mobileController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Registered Mobile Number',
                  hintText: 'Test: 9999999999',
                  prefixIcon: Icon(Icons.phone_android),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.length != 10) {
                    return 'Mobile Number must be 10 digits.';
                  }
                  return null;
                },
              ),
              // Replaced hardcoded 16.0 with kPaddingMedium
              const SizedBox(height: kPaddingMedium),

              // Date of Birth Field
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _isLoading ? null : () => _selectDateOfBirth(context),
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (DD/MM/YYYY)',
                  hintText: 'Test: 01/01/1980',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your Date of Birth.';
                  }
                  return null;
                },
              ),
              // Replaced hardcoded 40.0 with kPaddingXXL
              const SizedBox(height: kPaddingXXL),

              _isLoading
              // CircularProgressIndicator color defaults to colorScheme.primary
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _verifyIdentity,
                // ElevatedButton uses primary color by default, which is theme-compliant
                child: Text(
                  'VERIFY & GET OTP',
                  // Using theme style for consistency
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}