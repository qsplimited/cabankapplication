import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'dashboard_screen.dart';
import 'forgot_mpin_step1_identity.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mpinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String mpin = _mpinController.text.trim();

    // Authenticates against the stored (mocked) MPIN
    final bool success = await globalDeviceService.loginWithMpin(mpin: mpin);

    if (mounted) {
      if (success) {
        // Success: Navigate to the Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        // Failure: Show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Invalid M-PIN. Please try again.')),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToForgotPassword() {
    // Navigates to the start of the Forgot MPIN flow (Identity Re-verification)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotMpinStep1Identity(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('M-PIN Access'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 50),
              Center(
                child: Icon(Icons.lock_open, size: 80, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 40),
              const Text(
                'Enter your M-PIN',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _mpinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                // Ensures 6-digit MPIN consistency
                maxLength: 6,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: const InputDecoration(
                  labelText: 'M-PIN',
                  hintText: 'e.g., 112233',
                  border: OutlineInputBorder(),
                  counterText: '', // Hides the character counter
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'M-PIN must be exactly 6 digits.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              _isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : ElevatedButton(
                onPressed: _handleLogin,
                child: const Text('LOG IN'),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: _navigateToForgotPassword,
                child: const Text(
                  'Forgot M-PIN?',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
