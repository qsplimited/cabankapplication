import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/registration_bloc.dart';
import '../event/registration_event.dart';
import '../state/registration_state.dart';
import 'registration_step2_otp.dart';
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

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      // Dispatch the reset event
      context.read<RegistrationBloc>().add(
        ResetIdentitySubmitted(_custIdController.text.trim(), _passController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationBloc, RegistrationState>(
      listener: (context, state) {
        if (state.currentStep == 1) {
          // FIX: No parameters passed here anymore
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegistrationStep2Otp()),
          );
        } else if (state.status == RegistrationStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? "Verification Failed"), backgroundColor: Colors.redAccent),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Forgot MPIN'), backgroundColor: kAccentOrange),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text("Verify your identity to reset MPIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _custIdController,
                  decoration: const InputDecoration(labelText: 'Customer ID', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => v!.isEmpty ? 'Enter Customer ID' : null,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                  validator: (v) => v!.isEmpty ? 'Enter Password' : null,
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: kButtonHeight,
                  child: BlocBuilder<RegistrationBloc, RegistrationState>(
                    builder: (context, state) {
                      return ElevatedButton(
                        onPressed: state.status == RegistrationStatus.loading ? null : _onContinue,
                        style: ElevatedButton.styleFrom(backgroundColor: kAccentOrange),
                        child: state.status == RegistrationStatus.loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('VERIFY & SEND OTP', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}