// File: lib/screens/pan_update_screen.dart (Hypothetical path)

import 'package:flutter/material.dart';
// Import the necessary files from your provided structure
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';
import '../api/pan_api_service.dart'; // Import the mock service

// --- New Reusable Widget for T-PIN Input ---
class TpinInputRow extends StatefulWidget {
  // Use a GlobalKey to access the collected TPIN value from outside
  final GlobalKey<_TpinInputRowState> key;

  const TpinInputRow({required this.key}) : super(key: key);

  // Getter to easily retrieve the TPIN value from the state
  String get tpinValue => key.currentState?.tpinValue ?? '';

  @override
  State<TpinInputRow> createState() => _TpinInputRowState();
}

class _TpinInputRowState extends State<TpinInputRow> {
  final int _pinLength = 6;
  final List<TextEditingController> _controllers = [];
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _pinLength; i++) {
      _controllers.add(TextEditingController());
      _focusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _handlePinChange(String value, int index, BuildContext context) {
    if (value.length == 1 && index < _pinLength - 1) {
      // Auto-shift focus to the next field
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    } else if (value.isEmpty && index > 0) {
      // Auto-shift focus back to the previous field on backspace
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    // Unfocus the keyboard when the last digit is entered
    if (_controllers.every((c) => c.text.length == 1)) {
      _focusNodes.last.unfocus();
    }
  }

  // Public getter to collect all digits
  String get tpinValue => _controllers.map((c) => c.text).join();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_pinLength, (index) {
        return SizedBox(
          width: 40.0, // Fixed width for PIN box
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            obscureText: true,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: Theme.of(context).textTheme.titleLarge, // Use a prominent text style
            decoration: InputDecoration(
              counterText: "", // Hide the length counter
              hintText: '-', // Use a dash as the placeholder
              contentPadding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
              // Use borderRadius from theme for separate boxes
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kRadiusSmall),
              ),
            ),
            onChanged: (value) => _handlePinChange(value, index, context),
          ),
        );
      }),
    );
  }
}

// --- Main Screen Widget ---

class PanUpdateScreen extends StatefulWidget {
  const PanUpdateScreen({super.key});

  @override
  State<PanUpdateScreen> createState() => _PanUpdateScreenState();
}

class _PanUpdateScreenState extends State<PanUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _panApiService = PanApiService();

  // Mock initial state data
  String _oldPan = 'ABCDE0000A';
  String _newPan = '';
  bool _isLoading = false;

  // Reusable PAN validation function
  String? _validatePan(String? value) {
    if (value == null || value.isEmpty) {
      return 'PAN number cannot be empty.';
    }
    // Basic PAN format check (5 letters, 4 numbers, 1 letter)
    final panRegex = RegExp(r"^[A-Z]{5}[0-9]{4}[A-Z]{1}$");
    if (!panRegex.hasMatch(value.toUpperCase())) {
      return 'Invalid PAN format (e.g., ABCDE1234F)';
    }
    return null;
  }

  // --- T-PIN Confirmation Modal (Returns the confirmed TPIN or null) ---
  Future<String?> _showTpinModal(BuildContext context) {
    final theme = Theme.of(context);
    // Key to access the TpinInputRow state and value
    final tpinKey = GlobalKey<_TpinInputRowState>();

    return showDialog<String?>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Confirm PAN Update', style: theme.textTheme.titleMedium),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Please enter your T-PIN to authorize this sensitive change.',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: kSpacingLarge), // Increased spacing

                // --- T-PIN Input Implementation ---
                TpinInputRow(key: tpinKey),
                // ---------------------------------
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(null), // Return null on cancel
            ),
            ElevatedButton(
              onPressed: () {
                final tpin = tpinKey.currentState?.tpinValue;
                if (tpin != null && tpin.length == 6) {
                  // If TPIN is valid, close modal and return the value
                  Navigator.of(dialogContext).pop(tpin);
                } else {
                  // Optional: Show error if TPIN is incomplete
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Please enter all 6 digits of your T-PIN.')),
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  // --- Submission Logic and API Call ---
  void _submitUpdate(String tpin) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _panApiService.updatePan(
        oldPan: _oldPan,
        newPan: _newPan,
        tpin: tpin,
      );

      // Show SnackBar based on API response
      if (response['status'] == 'SUCCESS') {
        // --- CORRECTED: Using kSuccessGreen from app_colors.dart ---
        _showSnackbar('✅ ${response['message']!}', kSuccessGreen);
        setState(() {
          // Update local state with new PAN
          _oldPan = response['data']['newPan'];
          _newPan = ''; // Clear new pan field
        });
        _formKey.currentState?.reset();
      } else {
        // Using kErrorRed defined in app_colors.dart
        _showSnackbar('❌ ${response['message']!}', kErrorRed);
      }
    } catch (e) {
      _showSnackbar('⚠️ An unexpected error occurred: $e', kErrorRed);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper function to show messages
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PAN Update'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_document),
            onPressed: () {
              _showSnackbar('Document editing tools.', kInfoBlue);
            },
          ),
          const SizedBox(width: kPaddingSmall),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Verify your current PAN and enter the new one. All fields are mandatory.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: kSpacingLarge),

              // Current PAN Display (Read-only)
              TextFormField(
                initialValue: _oldPan,
                readOnly: true,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark ? kDarkTextPrimary : kBrandNavy,
                ),
                decoration: InputDecoration(
                  labelText: 'Current PAN Number',
                  prefixIcon: const Icon(Icons.credit_card_sharp),
                  fillColor: isDark ? kDarkSurface : kInputBackgroundColor,
                  filled: true,
                ),
              ),
              const SizedBox(height: kSpacingMedium),

              // New PAN Input
              TextFormField(
                textCapitalization: TextCapitalization.characters,
                maxLength: 10,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  labelText: 'Enter New PAN Number',
                  hintText: 'e.g., ABCDE1234F',
                  prefixIcon: Icon(Icons.edit),
                ),
                validator: _validatePan,
                onSaved: (value) {
                  _newPan = value!;
                },
              ),
              const SizedBox(height: kSpacingLarge),

              // Update Button
              _isLoading
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: kPaddingMedium),
                  child: CircularProgressIndicator(),
                ),
              )
                  : ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final tpin = await _showTpinModal(context);
                    if (tpin != null) {
                      _submitUpdate(tpin);
                    }
                  }
                },
                child: const Text('Request PAN Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}