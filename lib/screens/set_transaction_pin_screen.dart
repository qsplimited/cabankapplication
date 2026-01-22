import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tpin_provider.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

class SetTransactionPinScreen extends ConsumerStatefulWidget {
  const SetTransactionPinScreen({super.key});

  @override
  ConsumerState<SetTransactionPinScreen> createState() => _SetTransactionPinScreenState();
}

class _SetTransactionPinScreenState extends ConsumerState<SetTransactionPinScreen> {
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  // logic to handle the submission
  Future<void> _setPin() async {
    if (!_formKey.currentState!.validate()) return;

    // Based on banking_service.dart:
    // This calls updateTransactionPin(newPin, oldPin)
    // The oldPin MUST match '456789' to succeed.
    await ref.read(tpinProvider.notifier).submitNewPin(
      newPin: _newPinController.text,
      oldPin: _oldPinController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(tpinProvider);
    final bool isLoading = state.status == TpinStateStatus.loading;

    // Listen for state changes to handle navigation and snackbars
    ref.listen<TpinProcessState>(tpinProvider, (previous, next) {
      if (next.status == TpinStateStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message ?? 'PIN Updated Successfully'),
            backgroundColor: kSuccessGreen,
          ),
        );
        Navigator.pop(context);
        ref.read(tpinProvider.notifier).resetStatus();
      } else if (next.status == TpinStateStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error ?? 'Current T-PIN is incorrect'),
            backgroundColor: kErrorRed,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change T-PIN'), // Title as per standard design
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Current T-PIN Field (Must be 456789)
              _buildPinInputField(
                controller: _oldPinController,
                label: 'Current T-PIN',
                isLoading: isLoading,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter current T-PIN';
                  if (value.length < 6) return 'Must be 6 digits';
                  return null;
                },
              ),

              const SizedBox(height: kPaddingMedium),

              // 2. New T-PIN Field
              _buildPinInputField(
                controller: _newPinController,
                label: 'New T-PIN',
                isLoading: isLoading,
                isNewPin: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter new T-PIN';
                  if (value.length < 6) return 'Must be 6 digits';
                  if (value == _oldPinController.text) return 'New PIN cannot be same as old';
                  return null;
                },
              ),

              const SizedBox(height: kPaddingMedium),

              // 3. Confirm New T-PIN Field
              _buildPinInputField(
                controller: _confirmPinController,
                label: 'Confirm New T-PIN',
                isLoading: isLoading,
                validator: (value) {
                  if (value != _newPinController.text) {
                    return 'T-PINs do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: kPaddingXXL),

              // Updated button with proper design and loading logic
              ElevatedButton(
                onPressed: isLoading ? null : _setPin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text(
                  'Update PIN',
                  style: textTheme.labelLarge?.copyWith(
                    fontSize: 18,
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

  // Helper method preserved exactly as per your old design
  Widget _buildPinInputField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    required bool isLoading,
    bool isNewPin = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kPaddingTen),
      child: TextFormField(
        controller: controller,
        obscureText: true,
        maxLength: 6,
        enabled: !isLoading,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (val) {
          // This ensures the form re-validates as you type
          if (val.length == 6) {
            _formKey.currentState!.validate();
          }
          setState(() {}); // Keep UI synced
        },
        decoration: InputDecoration(
          labelText: label,
          counterText: "",
          prefixIcon: const Icon(Icons.lock_outline),
          helperText: isNewPin ? "Choose a secure 6-digit number" : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kRadiusMedium),
          ),
        ),
        validator: validator,
      ),
    );
  }
}