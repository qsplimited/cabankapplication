import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import '../utils/validators.dart';
import 'registration_step2_otp.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

class RegistrationStep1Identity extends ConsumerStatefulWidget {
  const RegistrationStep1Identity({super.key});
  @override
  ConsumerState<RegistrationStep1Identity> createState() => _RegistrationStep1IdentityState();
}

class _RegistrationStep1IdentityState extends ConsumerState<RegistrationStep1Identity> {
  final _formKey = GlobalKey<FormState>();
  final _custIdController = TextEditingController();
  final _passController = TextEditingController();

  void _onVerify() {
    if (_formKey.currentState!.validate()) {
      // Stripping spaces before sending to API
      final cleanId = _custIdController.text.trim().replaceAll(' ', '');
      ref.read(registrationProvider.notifier).submitIdentity(cleanId, _passController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(registrationProvider, (prev, next) {
      if (next.currentStep == 1 && prev?.currentStep == 0) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationStep2Otp()));
      }
    });

    final regState = ref.watch(registrationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange,
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: kPaddingLarge),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        const Icon(Icons.verified_user_outlined, size: 80, color: kAccentOrange),
                        const SizedBox(height: 24),
                        const Text("Verify your credentials to register", style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 40),

                        TextFormField(
                          controller: _custIdController,
                          validator: AppValidators.validateCustomerId,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(5),
                            FilteringTextInputFormatter.deny(RegExp(r'\s')), // Block spaces
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Customer ID (e.g. A0001)',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _passController,
                          obscureText: true,
                          validator: AppValidators.validatePassword,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),

                        const Spacer(), // Pushes button down, but allows scroll if space is tight

                        SizedBox(
                          width: double.infinity,
                          height: kButtonHeight,
                          child: ElevatedButton(
                            onPressed: regState.status == RegistrationStatus.loading ? null : _onVerify,
                            style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                            child: regState.status == RegistrationStatus.loading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('VERIFY IDENTITY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 30), // Professional bottom spacing
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}