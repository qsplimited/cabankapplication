import 'package:flutter/material.dart';
import '../main.dart'; // Access globalDeviceService
import '../api/mock_device_service.dart'; // Required for resetBinding()
import 'app_router.dart'; // Required to navigate back to the main router check

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // --- ESSENTIAL LOGOUT FUNCTION ---
  // Resets the mock binding status and returns the user to the startup flow
  void _handleLogout(BuildContext context) {
    // 1. Reset the Mock State (device is now "unbound" and MPIN is cleared)
    (globalDeviceService as MockDeviceService).resetBinding();

    // 2. Navigate back to the AppRouter, clearing all previous routes
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const AppRouter()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard (MPIN Success)'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Logout and Reset',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            Text(
              'Login Successful!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your 6-digit MPIN has been verified.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 40),
            const Text(
              'This is the simple dashboard placeholder.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}
