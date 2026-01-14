import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/registration_bloc.dart';
import '../event/registration_event.dart';
import '../state/registration_state.dart';
import 'registration_step2_otp.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

class RegistrationStep1Identity extends StatefulWidget {
  const RegistrationStep1Identity({super.key});

  @override
  State<RegistrationStep1Identity> createState() => _RegistrationStep1IdentityState();
}

class _RegistrationStep1IdentityState extends State<RegistrationStep1Identity> {
  final _formKey = GlobalKey<FormState>();
  final _custIdController = TextEditingController();
  final _passController = TextEditingController();

  void _onVerify() {
    if (_formKey.currentState!.validate()) {
      context.read<RegistrationBloc>().add(
        IdentitySubmitted(_custIdController.text.trim(), _passController.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<RegistrationBloc, RegistrationState>(
      listener: (context, state) {
        if (state.currentStep == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegistrationStep2Otp()));
        }
        if (state.status == RegistrationStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage ?? "Error"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Device Binding', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: kAccentOrange,
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(
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
                      // --- NEW HEADER SECTION ---
                      const Center(
                        child: Icon(Icons.phonelink_lock, size: 64, color: kAccentOrange),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Registration",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter your credentials to link your device with your banking account.",
                        style: TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
                      ),
                      const SizedBox(height: 40),

                      // --- FORM FIELDS ---
                      TextFormField(
                        controller: _custIdController,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          labelText: 'Customer ID',
                          prefixIcon: Icon(Icons.person_outline, color: kAccentOrange),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Please enter Customer ID' : null,
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _passController,
                        obscureText: true,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, color: kAccentOrange),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Please enter Password' : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- ACTION BUTTON ---
            Padding(
              padding: const EdgeInsets.all(kPaddingLarge),
              child: SizedBox(
                width: double.infinity,
                height: kButtonHeight,
                child: BlocBuilder<RegistrationBloc, RegistrationState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == RegistrationStatus.loading ? null : _onVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentOrange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                        elevation: 2,
                      ),
                      child: state.status == RegistrationStatus.loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                          'VERIFY IDENTITY',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}