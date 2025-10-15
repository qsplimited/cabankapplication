import 'package:flutter/material.dart';
import '../main.dart'; // Required to access globalDeviceService
import '../api/mock_device_service.dart'; // To use the resetBinding for Forgot MPIN
import 'dashboard_screen.dart';
import 'registration_landing_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mpinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _mpinController.dispose();
    super.dispose();
  }

  // Handles the 6-digit MPIN authentication
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String mpin = _mpinController.text.trim();


      final bool success = await globalDeviceService.loginWithMpin(mpin: mpin);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {

          setState(() {
            _errorMessage = 'Invalid M-PIN. Please check and try again.';
          });
          _mpinController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'A network error occurred. Please try again later.';
        });
      }
    }
  }

  // Placeholder for the Forgot M-PIN navigation (simulates a flow reset)
  void _navigateToForgotPassword() {

    (globalDeviceService as MockDeviceService).resetBinding();


    setState(() {
      _errorMessage = '';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starting device re-registration flow.')),
    );


    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const RegistrationLandingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure M-PIN Access'),
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
                child: Icon(Icons.lock_open, size: 80, color: theme.primaryColor),
              ),
              const SizedBox(height: 40),
              Text(
                'Enter your 6-Digit M-PIN to Log In',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Error Message Display
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    _errorMessage,
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              // M-PIN Input Field
              TextFormField(
                controller: _mpinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6, // **6 DIGITS REQUIRED**
                decoration: const InputDecoration(
                  labelText: 'M-PIN',
                  hintText: 'Your 6-digit MPIN',
                  border: OutlineInputBorder(),
                  counterText: '',
                  prefixIcon: Icon(Icons.pin),
                ),
                validator: (value) {
                  if (value == null || value.length != 6 || int.tryParse(value) == null) {
                    return 'M-PIN must be exactly 6 digits.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),


              // Submission Button
              _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        theme.primaryColor)),
              )
                  : ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('LOG IN', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),


              // Forgot M-PIN Button
              TextButton(
                onPressed: _navigateToForgotPassword,
                child: Text(
                  'Forgot M-PIN?',
                  style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
