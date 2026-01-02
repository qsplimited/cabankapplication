
import 'package:flutter/material.dart';
import '../utils/device_id_util.dart';
import '../main.dart';

import 'login_screen.dart';
import 'registration_landing_screen.dart';
import 'dashboard_screen.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  // -------------------------------------------------------------------
  // <<< MODIFICATION 1: ADDED DEBUG TOGGLE FLAG >>>
  // Set to TRUE to force the app to always show the Registration flow for demos.
  static const bool _forceRegistrationDemo = true;
  // -------------------------------------------------------------------

  bool? _isDeviceBound;

  @override
  void initState() {
    super.initState();
    _checkBindingStatus();
  }

  Future<void> _checkBindingStatus() async {
    try {

      const String deviceId = 'mock_unique_device_id_123';
      print('Router: Retrieved Device ID: $deviceId');


      final bool isBound = await globalDeviceService.checkDeviceBinding(deviceId);


      if (mounted) {
        setState(() {
          _isDeviceBound = isBound;
        });
      }
    } catch (e) {
      print('Router Error: Failed to check device status: $e');
      if (mounted) {
        setState(() {
          _isDeviceBound = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDeviceBound == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Since this is TRUE now, Path B is always chosen for testing.
    if (_forceRegistrationDemo) {
      return const RegistrationLandingScreen();
    }

    // (This part will be used only when you are ready to ship with Real API)
    if (_isDeviceBound == true) {
      return const LoginScreen();
    } else {
      return const RegistrationLandingScreen();
    }
  }
}


