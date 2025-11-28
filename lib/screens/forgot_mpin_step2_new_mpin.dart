// File: lib/screens/forgot_mpin_step2_new_mpin.dart (Refactored)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart'; // For globalDeviceService access
import 'login_screen.dart'; // Navigation destination after successful MPIN reset

// 💡 IMPORTANT: Import centralized design files
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          // Refactored hardcoded 15 to kRadiusLarge (16.0)
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
          title: Text(
            'Success!',
            // Refactored hardcoded Colors.green to kSuccessGreen from app_colors.dart
            style: textTheme.titleLarge?.copyWith(color: kSuccessGreen),
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              // TextButton color automatically uses colorScheme.primary
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot MPIN - Step 2'),
        // AppBar uses theme colors automatically
      ),
      body: SingleChildScrollView(
        // Refactored hardcoded 24.0 to kPaddingLarge
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Create a new 6-digit MPIN for secure mobile banking access.',
                style: textTheme.titleMedium,
              ),
              // Refactored hardcoded 30 to kPaddingExtraLarge (32.0 is close)
              const SizedBox(height: kPaddingExtraLarge),

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
              // Refactored hardcoded 20 to kIconSizeSmall
              const SizedBox(height: kIconSizeSmall),

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
                    return 'MPINs do not match.';
                  }
                  return null;
                },
              ),
              // Refactored hardcoded 30 to kPaddingExtraLarge (32.0 is close)
              const SizedBox(height: kPaddingExtraLarge),

              // Error Message Display
              if (_errorMessage.isNotEmpty)
                Padding(
                  // Refactored hardcoded 20.0 to kIconSizeSmall
                  padding: const EdgeInsets.only(bottom: kIconSizeSmall),
                  child: Text(
                    _errorMessage,
                    // Error color correctly uses theme.
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Submission Button
              ElevatedButton(
                onPressed: _isLoading ? null : _resetMpin,
                style: ElevatedButton.styleFrom(
                  // Refactored hardcoded 16 to kPaddingMedium
                  padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                  // Refactored hardcoded 12 to kRadiusMedium
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMedium)),
                ),
                child: _isLoading
                    ? SizedBox(
                  // Refactored hardcoded 20 to kIconSizeSmall
                  width: kIconSizeSmall,
                  height: kIconSizeSmall,
                  child: CircularProgressIndicator(
                    // Refactored hardcoded Colors.white to colorScheme.onPrimary
                    color: colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'RESET MPIN',
                  // Refactored hardcoded style with theme and colorScheme.onPrimary
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