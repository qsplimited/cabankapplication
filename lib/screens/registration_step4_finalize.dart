import 'package:flutter/material.dart';
import '../main.dart';
import '../utils/device_id_util.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class RegistrationStep4Finalize extends StatefulWidget {
  final String mpin;
  final String? sessionId;

  const RegistrationStep4Finalize({super.key, required this.mpin, this.sessionId});

  @override
  State<RegistrationStep4Finalize> createState() => _RegistrationStep4FinalizeState();
}

class _RegistrationStep4FinalizeState extends State<RegistrationStep4Finalize> {
  String _statusMessage = "Securing your account...";
  bool _isSuccess = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  void _bind() async {
    final deviceId = await getUniqueDeviceId();

    final result = await globalDeviceService.finalizeRegistration(
      mpin: widget.mpin,
      deviceId: deviceId,
      sessionId: widget.sessionId,
    );

    if (mounted) {
      if (result['success']) {
        setState(() {
          _isSuccess = true;
          _statusMessage = "Device Successfully Bound!";
        });

        // Small delay so the user can see the success state
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          // Navigates to root (AppRouter will now show Login because binding is true)
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } else {
        setState(() {
          _hasError = true;
          _statusMessage = "Binding failed. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(kPaddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Animated Icon Section ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: _hasError
                    ? Colors.red.withOpacity(0.1)
                    : (_isSuccess ? Colors.green.withOpacity(0.1) : kAccentOrange.withOpacity(0.1)),
                shape: BoxShape.circle,
              ),
              child: _hasError
                  ? const Icon(Icons.error_outline, size: 80, color: Colors.red)
                  : (_isSuccess
                  ? const Icon(Icons.check_circle_outline, size: 80, color: Colors.green)
                  : const CircularProgressIndicator(
                strokeWidth: 5,
                color: kAccentOrange,
              )),
            ),
            const SizedBox(height: 40),

            // --- Status Text ---
            Text(
              _isSuccess ? "Registration Complete" : (_hasError ? "Verification Failed" : "Finalizing..."),
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // --- Subtitle Text ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
            ),

            if (_hasError) ...[
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kAccentOrange),
                    foregroundColor: kAccentOrange,
                  ),
                  child: const Text("GO BACK"),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}