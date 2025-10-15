import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'registration_step4_finalize.dart'; // To navigate to the final step

class RegistrationStep3Mpin extends StatefulWidget {
  final String mobileNumber;

  const RegistrationStep3Mpin({super.key, required this.mobileNumber});

  @override
  State<RegistrationStep3Mpin> createState() => _RegistrationStep3MpinState();
}

class _RegistrationStep3MpinState extends State<RegistrationStep3Mpin> {
  final _mpinController = TextEditingController();
  final _confirmMpinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isMpinVisible = false;
  bool _isConfirmMpinVisible = false;

  @override
  void dispose() {
    _mpinController.dispose();
    _confirmMpinController.dispose();
    super.dispose();
  }

  void _handleMpinSetup() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final mpin = _mpinController.text;

    // In a real app, we would hash this MPIN locally before sending it to the server in the final step.

    // Simulating successful MPIN setup locally
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MPIN set successfully! Proceeding to Device Binding.'),
            backgroundColor: Colors.blue,
          ),
        );

        // --- NAVIGATION TO STEP 4 (Finalize) ---
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => RegistrationStep4Finalize(
              mobileNumber: widget.mobileNumber,
              mpin: mpin,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('3/4: Set MPIN'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Set your secure 6-digit Mobile PIN (MPIN). This will be used for all future logins.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 30),

              // 1. Set MPIN Field
              TextFormField(
                controller: _mpinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: !_isMpinVisible,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium!.copyWith(letterSpacing: 8),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'New MPIN',
                  hintText: '• • • • • •',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isMpinVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isMpinVisible = !_isMpinVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'MPIN must be exactly 6 digits.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),

              // 2. Confirm MPIN Field
              TextFormField(
                controller: _confirmMpinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: !_isConfirmMpinVisible,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium!.copyWith(letterSpacing: 8),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Confirm MPIN',
                  hintText: '• • • • • •',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmMpinVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmMpinVisible = !_isConfirmMpinVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value != _mpinController.text) {
                    return 'MPINs do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 50),

              // Set MPIN Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleMpinSetup,
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text('SET MPIN & CONTINUE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
