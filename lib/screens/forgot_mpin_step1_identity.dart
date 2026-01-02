// lib/screens/forgot_mpin_step1_identity.dart
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/registration_models.dart';
import 'registration_step2_otp.dart';
import 'forgot_mpin_step2_new_mpin.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

class ForgotMpinStep1Identity extends StatefulWidget {
  const ForgotMpinStep1Identity({super.key});

  @override
  State<ForgotMpinStep1Identity> createState() => _ForgotMpinStep1IdentityState();
}

class _ForgotMpinStep1IdentityState extends State<ForgotMpinStep1Identity> {
  final _formKey = GlobalKey<FormState>();
  final _custIdController = TextEditingController();
  final _passController = TextEditingController();
  bool _isLoading = false;

  void _verifyIdentity() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final req = AuthRequest(
      customerId: _custIdController.text.trim(), // Now supports alphabets
      password: _passController.text.trim(),
    );

    final res = await globalDeviceService.verifyIdentityForReset(req);
    setState(() => _isLoading = false);

    if (res.success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RegistrationStep2Otp(
            otpCode: res.otpCode!,
            sessionId: res.sessionId,
            nextScreen: ForgotMpinStep2NewMpin(sessionId: res.sessionId),
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res.message ?? "Verification Failed"), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Reset MPIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Verify Identity', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Enter your credentials to reset your secure PIN.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(height: 40),

              TextFormField(
                controller: _custIdController,
                decoration: const InputDecoration(
                  labelText: 'Customer ID',
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: 'e.g. USER123',
                ),
                validator: (v) => v!.isEmpty ? 'Enter Customer ID' : null,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (v) => v!.isEmpty ? 'Enter Password' : null,
              ),
              const SizedBox(height: 60),

              SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyIdentity,
                  style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('VERIFY & SEND OTP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}