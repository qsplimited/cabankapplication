import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart'; // For globalDeviceService access
import 'login_screen.dart'; // Navigation destination after successful MPIN reset

class ForgotMpinStep2NewMpin extends StatefulWidget {
  // This screen does not require any parameters as the identity verification
  // and temporary session are handled by the mock service state.
  const ForgotMpinStep2NewMpin({super.key});

  @override
  State<ForgotMpinStep2NewMpin> createState() => _ForgotMpinStep2NewMpinState();
}

class _ForgotMpinStep2NewMpinState extends State<ForgotMpinStep2NewMpin> {
  final _formKey = GlobalKey<FormState>();
  final _newMpinController = TextEditingController();
  final _confirmMpinController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _newMpinController.dispose();
    _confirmMpinController.dispose();
    super.dispose();
  }

  // --- MPIN Reset Logic ---
  void _resetMpin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional check for MPIN match
    if (_newMpinController.text != _confirmMpinController.text) {
      setState(() {
        _errorMessage = 'The New MPIN and Confirm MPIN must match.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String newMpin = _newMpinController.text;

      // Call the Mock API service to reset the MPIN
      final response = await globalDeviceService.resetMpin(newMpin: newMpin);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (response['success'] == true) {
          // Success: MPIN updated. Navigate to the Login Screen.
          _showSuccessDialog(response['message'] as String);
        } else {
          // Failure: Display API error message
          setState(() {
            _errorMessage = response['message'] as String;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred during MPIN reset.';
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Success!', style: TextStyle(color: Colors.green)),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Go to Login'),
              onPressed: () {
                // Pop the dialog, then push Login Screen, replacing all routes
                // to prevent navigating back to the registration/forgot flow.
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot MPIN - Step 2'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Create a new 6-digit MPIN for secure mobile banking access.',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 30),

              // 1. New MPIN Field
              TextFormField(
                controller: _newMpinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'New 6-Digit MPIN',
                  hintText: 'Enter 6 digits',
                  prefixIcon: Icon(Icons.lock_outline),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'MPIN must be exactly 6 digits.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 2. Confirm MPIN Field
              TextFormField(
                controller: _confirmMpinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Confirm New MPIN',
                  hintText: 'Re-enter 6 digits',
                  prefixIcon: Icon(Icons.lock),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'MPIN must be exactly 6 digits.';
                  }
                  if (value != _newMpinController.text) {
                    // This is redundant with the pre-submission check but good practice
                    return 'MPINs do not match.';
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
                onPressed: _isLoading ? null : _resetMpin,
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
                    : const Text('RESET MPIN', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
