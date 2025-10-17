import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'forgot_mpin_step2_new_mpin.dart';
import 'registration_step2_otp.dart';


String formatDate(DateTime date) {
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
          // Identity verified. Proceed to OTP screen.
          final String otpCode = result['otp_code'] as String; // Safe cast
          final String verifiedMobile = result['mobile_number'] as String; // Safe cast

          // Show Mock OTP (for demonstration purposes only)
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Text('MOCK: OTP Generated', style: TextStyle(color: Colors.red)),
              content: Text(
                'For testing, please use this OTP: $otpCode. \n\n'
                    'In the real world, this is sent securely to $verifiedMobile.',
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
                          // Removed 'const' for safer dynamic widget instantiation
                          successRoute: ForgotMpinStep2NewMpin(),
                        ),
                      ),
                    );
                  },
                  child: const Text('OK, Proceed'),
                ),
              ],
            ),
          );
        } else {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] as String), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Network error or unexpected issue occurred.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot MPIN - Step 1'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Verify your identity to reset your M-PIN.',
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24.0),

              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  hintText: 'Test: 123456',
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your Account Number.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),

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
              const SizedBox(height: 16.0),

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
              const SizedBox(height: 40.0),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _verifyIdentity,
                child: const Text('VERIFY & GET OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
