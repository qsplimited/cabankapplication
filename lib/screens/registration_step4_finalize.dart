import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/registration_bloc.dart';
import '../state/registration_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

class RegistrationStep4Finalize extends StatelessWidget {
  const RegistrationStep4Finalize({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocConsumer<RegistrationBloc, RegistrationState>(
      listener: (context, state) {
        // FLOW LOGIC: When success is emitted, wait 2 seconds then go to login/landing
        if (state.status == RegistrationStatus.success) {
          Future.delayed(const Duration(seconds: 2), () {
            // This takes the user back to the beginning (Landing/Login)
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          });
        }
      },
      builder: (context, state) {
        // UI Logic based on State
        bool isSuccess = state.status == RegistrationStatus.success;
        bool hasError = state.status == RegistrationStatus.failure;

        String statusMessage = "Securing your account...";
        if (isSuccess) statusMessage = "Device Successfully Bound!";
        if (hasError) statusMessage = state.errorMessage ?? "Finalization Failed";

        return Scaffold(
          body: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(kPaddingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- DESIGN: Animated Icon Section ---
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: isSuccess
                      ? const Icon(Icons.check_circle_outline,
                      key: ValueKey('success'), size: 100, color: Colors.green)
                      : hasError
                      ? const Icon(Icons.error_outline,
                      key: ValueKey('error'), size: 100, color: Colors.red)
                      : const SizedBox(
                    height: 100, width: 100,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      valueColor: AlwaysStoppedAnimation<Color>(kAccentOrange),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // --- DESIGN: Status Title ---
                Text(
                  isSuccess ? "Registration Complete" : (hasError ? "Verification Failed" : "Finalizing..."),
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                // --- DESIGN: Subtitle Text ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                ),

                // --- FLOW: Error Action ---
                if (hasError) ...[
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
      },
    );
  }
}