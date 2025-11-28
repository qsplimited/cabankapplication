// File: lib/screens/login_screen.dart (Refactored)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Assuming these files exist in your project structure
import '../main.dart';
import 'dashboard_screen.dart';
import 'forgot_mpin_step1_identity.dart';

// 💡 IMPORTANT: Import centralized design files
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FocusNode _mpinFocusNode = FocusNode();
  final TextEditingController _mpinController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mpinController.addListener(_updatePinDisplay);

    // Automatically focus the input field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_mpinFocusNode);
    });
  }

  void _updatePinDisplay() {
    setState(() {});
  }

  @override
  void dispose() {
    _mpinController.removeListener(_updatePinDisplay);
    _mpinController.dispose();
    _mpinFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final colorScheme = Theme.of(context).colorScheme;

    if (_mpinController.text.length != 6) {
      // Refactored SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter the complete 6-digit M-PIN.'),
          backgroundColor: Colors.orange.shade700, // Use a themed warning color if available
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String mpin = _mpinController.text.trim();

    // Simulating login API call
    final bool success = await globalDeviceService.loginWithMpin(mpin: mpin);

    if (mounted) {
      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        _mpinController.clear();
        FocusScope.of(context).requestFocus(_mpinFocusNode);
        // Refactored SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid M-PIN. Please try again.'),
            backgroundColor: colorScheme.error,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ForgotMpinStep1Identity(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure Device Login'),
        // Refactored hardcoded colors with theme
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        // Refactored hardcoded 24.0 and 40.0 with constants
        padding: const EdgeInsets.symmetric(horizontal: kPaddingLarge, vertical: kPaddingXXL),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: _buildLoginCard(context, colorScheme, textTheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    final bool isPinComplete = _mpinController.text.length == 6;

    return Card(
      // Refactored hardcoded 10 to kCardElevation (which is 4.0, a standard elevation)
      elevation: kCardElevation * 2.5, // Using a slightly higher elevation for prominence
      // Refactored hardcoded 20 to kRadiusLarge
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusLarge)),
      // Card color defaults to theme surface color
      child: Padding(
        // Refactored hardcoded 30.0 to kPaddingExtraLarge
        padding: const EdgeInsets.all(kPaddingExtraLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(
              Icons.lock_rounded,
              // Refactored hardcoded 70 to a theme-appropriate size
              size: 70.0,
              // Refactored hardcoded _primaryNavyBlue to colorScheme.primary
              color: colorScheme.primary,
            ),
            // Refactored hardcoded 20 to kIconSizeSmall
            const SizedBox(height: kIconSizeSmall),
            Text(
              'Welcome Back!',
              // Refactored hardcoded style with theme
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            // Refactored hardcoded 10 to kPaddingTen
            const SizedBox(height: kPaddingTen),
            Text(
              'Please enter your 6-digit M-PIN to continue.',
              // Refactored hardcoded style with theme and opacity for grey effect
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            // Refactored hardcoded 40 to kPaddingXXL
            const SizedBox(height: kPaddingXXL),
            GestureDetector(
              onTap: () => FocusScope.of(context).requestFocus(_mpinFocusNode),
              child: _PinCodeDisplay(
                pinLength: 6,
                currentPin: _mpinController.text,
                colorScheme: colorScheme, // Pass theme for custom widget
              ),
            ),
            // Refactored hardcoded 20 to kIconSizeSmall
            const SizedBox(height: kIconSizeSmall),
            // Hidden TextFormField for input control
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                height: 1,
                child: TextFormField(
                  focusNode: _mpinFocusNode,
                  controller: _mpinController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  obscureText: true,
                  validator: (value) {
                    return (value != null && value.length == 6) ? null : ' ';
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    if (value.length == 6) {
                      _handleLogin();
                    }
                  },
                ),
              ),
            ),
            // Refactored hardcoded 40 to kPaddingXXL
            const SizedBox(height: kPaddingXXL),
            _isLoading
                ? Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            )
                : ElevatedButton(
              onPressed: (isPinComplete && !_isLoading)
                  ? _handleLogin
                  : null,
              style: ElevatedButton.styleFrom(
                // Refactored hardcoded colors and style
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                // Refactored hardcoded 16 to kPaddingMedium
                padding: const EdgeInsets.symmetric(vertical: kPaddingMedium),
                // Refactored hardcoded 12 to kRadiusMedium
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kRadiusMedium),
                ),
                disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
              ),
              child: Text(
                'LOG IN',
                // Refactored hardcoded style with theme
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
            // Refactored hardcoded 20 to kIconSizeSmall
            const SizedBox(height: kIconSizeSmall),
            TextButton(
              onPressed: _navigateToForgotPassword,
              child: Text(
                'Forgot M-PIN?',
                // Refactored hardcoded style with theme
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Custom Pin Code Display Widget (Refactored) ---
class _PinCodeDisplay extends StatelessWidget {
  final int pinLength;
  final String currentPin;
  final ColorScheme colorScheme; // Pass ColorScheme to avoid reliance on context.

  const _PinCodeDisplay({
    required this.pinLength,
    required this.currentPin,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate box size dynamically, maintaining separation constants
        // Assuming 10 is kPaddingTen
        final double spacing = kPaddingTen;
        final double boxSize = (constraints.maxWidth - (spacing * (pinLength - 1))) / pinLength;
        const double boxHeight = 55;

        List<Widget> pinBoxes = List.generate(pinLength, (index) {
          bool isFilled = index < currentPin.length;
          bool isFocused = index == currentPin.length;

          return Container(
            width: boxSize > 50 ? 50 : boxSize,
            height: boxHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Refactored Colors.white to colorScheme.surface
              color: colorScheme.surface,
              // Refactored hardcoded 10 to kRadiusTen
              borderRadius: BorderRadius.circular(kPaddingTen),
              border: Border.all(
                // Refactored hardcoded colors
                color: isFocused ? colorScheme.primary : colorScheme.outline.withOpacity(0.5),
                width: isFocused ? 3 : 2,
              ),
              boxShadow: isFocused
                  ? [
                BoxShadow(
                  // Refactored hardcoded color
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                )
              ]
                  : null,
            ),
            child: isFilled
                ? Padding(
              // Refactored hardcoded 2.0
              padding: const EdgeInsets.only(bottom: kPaddingExtraSmall / 2),
              child: Icon(
                Icons.circle,
                size: 14,
                // Refactored hardcoded Colors.black87 to colorScheme.onSurface
                color: colorScheme.onSurface,
              ),
            )
                : Container(),
          );
        });

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: pinBoxes,
        );
      },
    );
  }
}