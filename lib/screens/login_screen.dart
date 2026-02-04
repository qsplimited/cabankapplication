import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/registration_provider.dart';
import 'forgot_mpin_identity.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final FocusNode _mpinFocusNode = FocusNode();
  final TextEditingController _mpinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch the saved ID from storage as soon as the app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(registrationProvider.notifier).loadSavedId();
      _mpinFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _mpinController.dispose();
    _mpinFocusNode.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_mpinController.text.length == 6) {
      // This calls the GET /customer/login/bympin endpoint in your RealDeviceService
      ref.read(registrationProvider.notifier).login(_mpinController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(registrationProvider);

    // Navigation and Error Listener
    ref.listen(registrationProvider, (previous, next) {
      if (next.status == RegistrationStatus.success) {
        // Successful login! Send to Dashboard
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else if (next.status == RegistrationStatus.failure) {
        // Show error from backend (e.g., "Invalid MPIN")
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? 'Invalid MPIN'),
            backgroundColor: Colors.redAccent,
          ),
        );
        _mpinController.clear();
        _mpinFocusNode.requestFocus();
      }
    });

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kAccentOrange,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(kPaddingLarge),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.security, size: 80, color: kAccentOrange),
              const SizedBox(height: 24),
              const Text(
                "Enter 6-Digit MPIN",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Secure Login for your device", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 50),

              // Visual PIN Boxes
              GestureDetector(
                onTap: () => _mpinFocusNode.requestFocus(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) => _buildPinBox(index)),
                    ),
                    // Hidden input field
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _mpinController,
                        focusNode: _mpinFocusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          setState(() {});
                          if (value.length == 6) _handleLogin();
                        },
                        decoration: const InputDecoration(counterText: ""),
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
                  onPressed: (authState.status == RegistrationStatus.loading || _mpinController.text.length < 6)
                      ? null
                      : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentOrange,
                    disabledBackgroundColor: kAccentOrange.withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSmall)),
                  ),
                  child: authState.status == RegistrationStatus.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                      "LOGIN",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),

              const SizedBox(height: 20),

// Inside LoginScreen
              TextButton(
                onPressed: () {
                  final savedId = ref.read(registrationProvider).customerId;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotMpinIdentity(autoCustomerId: savedId),
                    ),
                  );
                },
                child: const Text("Forgot MPIN?"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinBox(int index) {
    bool isFilled = _mpinController.text.length > index;
    bool isFocused = _mpinController.text.length == index && _mpinFocusNode.hasFocus;
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
            ? const Icon(Icons.circle, size: 16, color: Colors.black87)
            : null,
      ),
    );
  }
}