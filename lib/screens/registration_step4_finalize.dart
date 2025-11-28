import 'package:flutter/material.dart';
import '../api/i_device_service.dart';
import '../main.dart'; // To access globalDeviceService and AppRouter
// Import the necessary dimension and color constants
import '../theme/app_dimensions.dart';
import '../theme/app_colors.dart';

String getUniqueDeviceId() {
  return 'MOCK-DEVICE-ID-CA-BANK-12345';
}

class RegistrationStep4Finalize extends StatefulWidget {
  final String mobileNumber;
  final String mpin;

  const RegistrationStep4Finalize({
    super.key,
    required this.mobileNumber,
    required this.mpin
  });

  @override
  State<RegistrationStep4Finalize> createState() => _RegistrationStep4FinalizeState();
}

class _RegistrationStep4FinalizeState extends State<RegistrationStep4Finalize> {
  bool _isBindingComplete = false;
  String _statusMessage = 'Preparing for secure device binding...';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    // Start the binding process immediately when the screen loads
    _finalizeBinding();
  }

  void _finalizeBinding() async {
    final IDeviceService deviceService = globalDeviceService;
    // Obtain a mock device ID
    final deviceId = getUniqueDeviceId();

    setState(() {
      _statusMessage = 'Connecting to server and binding device...';
    });

    try {
      // Call the Mock API to simulate final registration and device binding
      // Logic preserved.
      final response = await deviceService.finalizeRegistration(
        mobileNumber: widget.mobileNumber,
        mpin: widget.mpin,
        deviceId: deviceId,
      );

      if (mounted) {
        if (response['success'] == true) {
          setState(() {
            _isSuccess = true;
            _statusMessage = 'Success! Device bound and registration complete.';
          });


          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              // Clear the entire registration stack and go to the root route ('/')
              // Assumes the AppRouter in main.dart correctly handles '/' as the login/dashboard route.
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            }
          });

        } else {
          setState(() {
            _isSuccess = false;
            _statusMessage = response['message'] ?? 'Binding failed. Please try registration again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSuccess = false;
          _statusMessage = 'Error connecting to the server. Please check your network.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBindingComplete = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determine the icon color and message color based on success/failure state
    final Color statusIconColor = _isSuccess ? kSuccessGreen : kErrorRed;
    final Color statusMessageColor = _isSuccess ? kSuccessGreen : kErrorRed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('4/4: Finalizing Setup'),
        automaticallyImplyLeading: false, // Prevent navigation during binding
      ),
      body: Center(
        child: Padding(
          // Replace hardcoded 32.0 with kPaddingExtraLarge
          padding: const EdgeInsets.all(kPaddingExtraLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Status Icon / Spinner
              if (!_isBindingComplete)
              // Use primary color for the active spinner
                CircularProgressIndicator(
                  color: colorScheme.primary,
                  // Replace hardcoded 4 with kCardElevation or similar small constant if available
                  strokeWidth: kCardElevation,
                )
              else if (_isSuccess)
                Icon(
                  Icons.check_circle,
                  // Use semantic color constant kSuccessGreen
                  color: statusIconColor,
                  // Replace hardcoded 80 with kIconSizeXXL or larger
                  size: kIconSizeXXL * 1.3, // Making it slightly larger than 60.0
                )
              else
                Icon(
                  Icons.error,
                  // Use semantic color constant kErrorRed
                  color: statusIconColor,
                  // Replace hardcoded 80 with kIconSizeXXL or larger
                  size: kIconSizeXXL * 1.3,
                ),

              // Replace hardcoded 40 with kPaddingXXL
              const SizedBox(height: kPaddingXXL),

              // Status Message
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  // Use appropriate semantic color, falling back to primary during loading
                  color: _isBindingComplete ? statusMessageColor : colorScheme.primary,
                ),
              ),
              // Replace hardcoded 20 with kPaddingLarge - 4
              const SizedBox(height: 20),

              Text(
                _isSuccess
                    ? 'Redirecting to your secured Dashboard...'
                    : 'Please contact customer support if the issue persists.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium,
              ),

              if (_isBindingComplete && !_isSuccess)
                Padding(
                  // Replace hardcoded 40.0 with kPaddingXXL
                  padding: const EdgeInsets.only(top: kPaddingXXL),
                  child: ElevatedButton(
                    onPressed: () {
                      // Restart the entire registration flow
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    // Rely on centralized ElevatedButtonThemeData (app_theme.dart)
                    child: Text(
                      'RETRY REGISTRATION',
                      style: textTheme.labelLarge,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}