import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import 'forgot_mpin_step1_identity.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure keyboard opens and focus is set on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mpinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _mpinController.dispose();
    _mpinFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_mpinController.text.length < 6) return;

    setState(() => _isLoading = true);

    // Using your global service for login
    bool success = await globalDeviceService.loginWithMpin(mpin: _mpinController.text);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid MPIN. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        _mpinController.clear();
        _mpinFocusNode.requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange, // Brand Orange AppBar
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Icon(Icons.security, size: 80, color: kAccentOrange),
              const SizedBox(height: 24),
              const Text(
                "Enter 6-Digit MPIN",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // PIN INPUT AREA
              GestureDetector(
                onTap: () => _mpinFocusNode.requestFocus(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Visual Boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) => _buildPinBox(index)),
                    ),
                    // Invisible TextField that captures input
                    Opacity(
                      opacity: 0,
                      child: SizedBox(
                        width: double.infinity,
                        child: TextField(
                          controller: _mpinController,
                          focusNode: _mpinFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          autofocus: true,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (value) {
                            setState(() {}); // Updates the dots
                            if (value.length == 6) {
                              _handleLogin(); // Auto-login on 6th digit
                            }
                          },
                          decoration: const InputDecoration(counterText: ""),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 60),

              // LOGIN BUTTON
              SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: ElevatedButton(
                  onPressed: (_isLoading || _mpinController.text.length < 6)
                      ? null
                      : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange, // Brand Orange Button
                    disabledBackgroundColor: kAccentOrange.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                      "LOGIN",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // FORGOT MPIN
              TextButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ForgotMpinStep1Identity())
                ),
                child: const Text(
                  "Forgot MPIN?",
                  style: TextStyle(color: kAccentOrange, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinBox(int index) {
    bool isFilled = _mpinController.text.length > index;
    bool isFocused = _mpinController.text.length == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 48,
      height: 58,
      decoration: BoxDecoration(
        color: isFocused ? kAccentOrange.withOpacity(0.05) : colorScheme.surface,
        borderRadius: BorderRadius.circular(kRadiusSmall),
        border: Border.all(
          color: isFocused ? kAccentOrange : colorScheme.outline.withOpacity(0.3),
          width: isFocused ? 2.5 : 1.5,
        ),
      ),
      child: Center(
        child: isFilled
            ? const Icon(Icons.circle, size: 16, color: Colors.black87) // Clearly visible dots
            : isFocused
            ? Container(width: 2, height: 24, color: kAccentOrange) // Blinking cursor effect
            : null,
      ),
    );
  }
}