import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../models/registration_models.dart';
import 'registration_step2_otp.dart';
import 'registration_step3_mpin.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

class RegistrationStep1Identity extends StatefulWidget {
  const RegistrationStep1Identity({super.key});

  @override
  State<RegistrationStep1Identity> createState() => _RegistrationStep1IdentityState();
}

class _RegistrationStep1IdentityState extends State<RegistrationStep1Identity> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for both ID and Password
  final _custIdController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoading = false;

  void _onVerify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final req = AuthRequest(
      customerId: _custIdController.text.trim(),
      password: _passController.text.trim(),
    );

    final res = await globalDeviceService.verifyCredentials(req);

    if (mounted) {
      setState(() => _isLoading = false);

      if (res.success) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegistrationStep2Otp(
              otpCode: res.otpCode ?? "123456",
              sessionId: res.sessionId,
              nextScreen: RegistrationStep3Mpin(sessionId: res.sessionId),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message ?? "Authentication Failed"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Identity Verification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kAccentOrange,
        centerTitle: false, // Left aligned title as requested
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(kPaddingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        "Registration",
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter your credentials to link your device.",
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 40),

                      // --- Customer ID (Supports Alphanumeric A0001) ---
                      const Text("Customer ID", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _custIdController,
                        keyboardType: TextInputType.text, // Changed to text for Alphanumeric
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'e.g. A0001',
                          prefixIcon: Icon(Icons.person_outline, color: kAccentOrange),
                          filled: true,
                          fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSmall),
                            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Please enter your Customer ID' : null,
                      ),

                      const SizedBox(height: 24),

                      // --- Password Field ---
                      const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passController,
                        obscureText: true,
                        style: TextStyle(color: colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: Icon(Icons.lock_outline, color: kAccentOrange),
                          filled: true,
                          fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(kRadiusSmall),
                            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Please enter your password' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Fixed Bottom Button Section for better visibility ---
            Padding(
              padding: const EdgeInsets.all(kPaddingLarge),
              child: SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: kAccentOrange.withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kRadiusSmall),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                      'VERIFY IDENTITY',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}