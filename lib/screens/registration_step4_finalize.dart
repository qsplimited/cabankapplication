import 'package:flutter/material.dart';
import '../api/i_device_service.dart';
import '../main.dart'; // To access globalDeviceService and AppRouter

// Placeholder for the device ID utility (in a real app, this would use device_info_plus)
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

          // CRUCIAL: After success, navigate to the AppRouter
          // This call triggers the router to re-check device status, 
          // which now returns TRUE (as set in MockService), redirecting to Dashboard.
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              // Clear the entire registration stack and go to the root route ('/')
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('4/4: Finalizing Setup'),
        automaticallyImplyLeading: false, // Prevent navigation during binding
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Status Icon / Spinner
              if (!_isBindingComplete)
                const CircularProgressIndicator(strokeWidth: 4)
              else if (_isSuccess)
                Icon(Icons.check_circle, color: Colors.green, size: 80)
              else
                Icon(Icons.error, color: Colors.red, size: 80),

              const SizedBox(height: 40),

              // Status Message
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _isBindingComplete ? (_isSuccess ? Colors.green.shade800 : Colors.red.shade800) : theme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                _isSuccess
                    ? 'Redirecting to your secured Dashboard...'
                    : 'Please contact customer support if the issue persists.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),

              if (_isBindingComplete && !_isSuccess)
                Padding(
                  padding: const EdgeInsets.only(top: 40.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Restart the entire registration flow
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                    child: const Text('RETRY REGISTRATION'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
