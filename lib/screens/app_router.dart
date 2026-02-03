// lib/screens/app_router.dart
import 'package:flutter/material.dart';
import '../utils/device_id_util.dart'; // Ensure this utility is imported
import '../main.dart';
import 'login_screen.dart';
import 'registration_landing_screen.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});
  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  // Set to FALSE when you want to test the actual logic from the database
  static const bool _forceRegistrationDemo = false;

  bool? _isDeviceBound;

  @override
  void initState() {
    super.initState();
    _checkBindingStatus();
  }

  Future<void> _checkBindingStatus() async {
    try {
      // FIX: Get the ACTUAL device ID, not the mock one
      final String deviceId = await getUniqueDeviceId();
      print('Router: Real Device ID: $deviceId');

      // This calls your RealDeviceService via globalDeviceService
      final bool isBound = await globalDeviceService.checkDeviceBinding(deviceId);

      if (mounted) {
        setState(() {
          _isDeviceBound = isBound;
        });
      }
    } catch (e) {
      debugPrint('Router Error: $e');
      if (mounted) {
        setState(() { _isDeviceBound = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeviceBound == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Toggle this based on your testing needs
    if (_forceRegistrationDemo) {
      return const RegistrationLandingScreen();
    }

    return _isDeviceBound! ? const LoginScreen() : const RegistrationLandingScreen();
  }
}