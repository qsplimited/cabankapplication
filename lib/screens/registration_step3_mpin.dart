import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'registration_step4_finalize.dart'; // To navigate to the final step
// Import the necessary dimension and color constants
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Simulating successful MPIN setup locally
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kAccentCyan,
            // FIX: Removed contentTextStyle and applied style directly to the Text widget.
            content: Text(
              'MPIN set successfully! Proceeding to Device Binding.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.surface, // Use a light color for text on the accent color
              ),
            ),
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
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        // The title style is derived from the theme, using onSurface/onPrimary
        title: Text(
          '3/4: Set MPIN',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary, // Assuming AppBar uses primary color
          ),
        ),
        backgroundColor: colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: SingleChildScrollView(
        // Replace hardcoded 24.0 with kPaddingLarge
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Set your secure 6-digit Mobile PIN (MPIN). This will be used for all future logins.',
                // Use titleMedium for instructional text
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onBackground.withOpacity(0.9),
                ),
              ),
              // Replace hardcoded 30 with kPaddingExtraLarge
              const SizedBox(height: kPaddingExtraLarge),

              // 1. Set MPIN Field
              TextFormField(
                controller: _mpinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: !_isMpinVisible,
                textAlign: TextAlign.center,
                // Use a large headline style and set letter spacing for MPIN input
                style: textTheme.headlineMedium?.copyWith(
                  // Use a spacing constant for letter spacing (24.0)
                  letterSpacing: kPaddingLarge,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // InputDecoration inherits most styling from InputDecorationTheme
                decoration: InputDecoration(
                  labelText: 'New MPIN',
                  hintText: '• • • • • •',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isMpinVisible ? Icons.visibility : Icons.visibility_off,
                      // Use colorScheme.primary for the visibility icon
                      color: colorScheme.primary,
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
              // Replace hardcoded 25 with a relevant dimension (e.g., kPaddingLarge)
              const SizedBox(height: kPaddingLarge),

              // 2. Confirm MPIN Field
              TextFormField(
                controller: _confirmMpinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                obscureText: !_isConfirmMpinVisible,
                textAlign: TextAlign.center,
                // Use a large headline style and set letter spacing for MPIN input
                style: textTheme.headlineMedium?.copyWith(
                  // Use a spacing constant for letter spacing (24.0)
                  letterSpacing: kPaddingLarge,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // InputDecoration inherits most styling from InputDecorationTheme
                decoration: InputDecoration(
                  labelText: 'Confirm MPIN',
                  hintText: '• • • • • •',
                  counterText: '',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmMpinVisible ? Icons.visibility : Icons.visibility_off,
                      // Use colorScheme.primary for the visibility icon
                      color: colorScheme.primary,
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
              // Replace hardcoded 50 with kPaddingXXL
              const SizedBox(height: kPaddingXXL),

              // Set MPIN Button
              SizedBox(
                height: kButtonHeight, // Use button height constant
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleMpinSetup,
                  // Rely on centralized ElevatedButtonThemeData (app_theme.dart)
                  child: _isLoading
                      ? SizedBox(
                    // Replace hardcoded 20 with kIconSizeSmall
                    width: kIconSizeSmall,
                    height: kIconSizeSmall,
                    child: CircularProgressIndicator(
                      // Progress indicator color should be colorScheme.onPrimary for visibility
                      color: colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    'SET MPIN & CONTINUE',
                    // Text style is handled by the theme (labelLarge), override size if needed
                    style: textTheme.labelLarge?.copyWith(fontSize: 16),
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