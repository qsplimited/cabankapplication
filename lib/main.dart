
import 'package:flutter/material.dart';
// Light & Dark Themes imported
import 'package:cabankapplication/api/i_device_service.dart';
import 'package:cabankapplication/api/mock_device_service.dart';

import 'screens/splash_screen.dart';

final IDeviceService globalDeviceService = MockDeviceService();


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CABANK Mobile',
      debugShowCheckedModeBanner: false,



      home: const SplashScreen(),
    );
  }
}