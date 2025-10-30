import 'package:flutter/material.dart';
import '../api/banking_service.dart'; // Import the service

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
  final Color _primaryNavyBlue = const Color(0xFF003366);
  final Color _accentGreen = const Color(0xFF4CAF50);

  // --- Core Logic: Set T-PIN ---
  Future<void> _setPin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final oldPin = _oldPinController.text;
    final newPin = _newPinController.text;

    try {
      // Call the service method
      await widget.bankingService.setTransactionPin(oldPin: oldPin, newPin: newPin);

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction PIN updated successfully!'),
            backgroundColor: _accentGreen,
          ),
        );
        Navigator.pop(context); // Go back to dashboard
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to set PIN: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 6, // 6-digit PIN
        decoration: InputDecoration(
          labelText: label,
          counterText: '', // Hide the 0/6 counter
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _primaryNavyBlue, width: 2),
          ),
          prefixIcon: const Icon(Icons.vpn_key_outlined),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Transaction PIN', style: TextStyle(color: Colors.white)),
        backgroundColor: _primaryNavyBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Update your secure 6-digit Transaction PIN. This is required for all fund transfers.',
                style: TextStyle(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

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

              const SizedBox(height: 10),
              const Divider(),
              const SizedBox(height: 10),

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

              const SizedBox(height: 40),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _setPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryNavyBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : const Text(
                  'Update PIN',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
