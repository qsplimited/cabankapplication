import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../api/banking_service.dart'; // Import the service
// Import theme constants
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

class SetTransactionPinScreen extends StatefulWidget {
  // 1. Required Banking Service instance
  final BankingService bankingService;

  const SetTransactionPinScreen({super.key, required this.bankingService});

  @override
  State<SetTransactionPinScreen> createState() => _SetTransactionPinScreenState();
}

class _SetTransactionPinScreenState extends State<SetTransactionPinScreen> {
  // Controllers for input fields
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = false;
  // Hardcoded color variables removed

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // --- Core Logic: Set T-PIN ---
  Future<void> _setPin() async {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final oldPin = _oldPinController.text;
    final newPin = _newPinController.text;

    try {
      // Logic preserved
      await widget.bankingService.setTransactionPin(oldPin: oldPin, newPin: newPin);

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Transaction PIN updated successfully!',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSecondary), // Text color on secondary/success background
            ),
            // Replaced _accentGreen with colorScheme.secondary for themed success feedback
            backgroundColor: colorScheme.secondary,
          ),
        );
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to set PIN: ${e.toString()}',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onError), // Text color on error background
            ),
            // Replaced Colors.red.shade700 with colorScheme.error
            backgroundColor: colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Pin Input Field Widget ---
  Widget _buildPinInputField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    bool isNewPin = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      // Replaced hardcoded 10.0 vertical padding with kPaddingTen
      padding: const EdgeInsets.symmetric(vertical: kPaddingTen),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 6, // 6-digit PIN
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        // Relying on InputDecorationTheme from app_theme.dart for most styling
        decoration: InputDecoration(
          labelText: label,
          counterText: '', // Hide the 0/6 counter (preserved design choice)
          // Removed explicit border definitions as they are defined in InputDecorationTheme
          // but explicitly setting the prefixIconColor here for theme awareness.
          prefixIcon: Icon(
            Icons.vpn_key_outlined,
            color: colorScheme.onSurface.withOpacity(0.6), // Use theme color
          ),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        // Removed hardcoded style/color/iconTheme to rely on AppBarTheme
        title: const Text('Set Transaction PIN'),
        // Removed elevation 0 to rely on AppBarTheme
      ),
      body: SingleChildScrollView(
        // Replaced hardcoded 24.0 with kPaddingLarge
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Update your secure 6-digit Transaction PIN. This is required for all fund transfers.',
                textAlign: TextAlign.center,
                // Replaced hardcoded style/color with textTheme.bodyMedium and theme color
                style: textTheme.bodyMedium?.copyWith(
                  // Use secondary text color for explanatory text
                  color: colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
              // Replaced hardcoded 30 with kPaddingExtraLarge
              const SizedBox(height: kPaddingExtraLarge),

              // Old PIN
              _buildPinInputField(
                controller: _oldPinController,
                label: 'Current PIN',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current PIN (Default: 123456)';
                  }
                  if (value.length != 6 || int.tryParse(value) == null) {
                    return 'PIN must be 6 numeric digits';
                  }
                  return null;
                },
              ),

              // Replaced hardcoded 10 with kPaddingTen
              const SizedBox(height: kPaddingTen),
              // Use theme-aware Divider
              Divider(color: colorScheme.onSurface.withOpacity(0.2)),
              // Replaced hardcoded 10 with kPaddingTen
              const SizedBox(height: kPaddingTen),

              // New PIN
              _buildPinInputField(
                controller: _newPinController,
                label: 'New PIN',
                isNewPin: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your new 6-digit PIN';
                  }
                  if (value.length != 6 || int.tryParse(value) == null) {
                    return 'New PIN must be 6 numeric digits';
                  }
                  if (value == _oldPinController.text) {
                    return 'New PIN cannot be the same as the current PIN';
                  }
                  return null;
                },
              ),

              // Confirm New PIN
              _buildPinInputField(
                controller: _confirmPinController,
                label: 'Confirm New PIN',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your new PIN';
                  }
                  if (value != _newPinController.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),

              // Replaced hardcoded 40 with kPaddingXXL
              const SizedBox(height: kPaddingXXL),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _setPin,
                // Removed explicit styleFrom to rely on centralized ElevatedButtonThemeData
                child: _isLoading
                    ? SizedBox(
                  // Replaced hardcoded 24 size with kIconSize
                  height: kIconSize,
                  width: kIconSize,
                  child: CircularProgressIndicator(
                    // Replaced hardcoded Colors.white with colorScheme.onPrimary
                    color: colorScheme.onPrimary,
                    // Kept strokeWidth 3.0 as a specific design choice
                    strokeWidth: 3,
                  ),
                )
                    : Text(
                  'Update PIN',
                  // Replaced hardcoded style with textTheme.labelLarge override
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 18, // Preserved larger font size intent
                    fontWeight: FontWeight.bold,
                    // Color is handled by the theme's button theme (onPrimary)
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