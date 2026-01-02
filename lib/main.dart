import 'package:flutter/material.dart';


import 'package:cabankapplication/api/i_device_service.dart';
import 'package:cabankapplication/api/mock_device_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';



final IDeviceService globalDeviceService = MockDeviceService();

Future<void> main() async {
  // This line is already here, but it's essential for the await below to work
  WidgetsFlutterBinding.ensureInitialized();

  // 3. THIS WILL NOW WORK WITHOUT ERRORS
  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded!");
  } catch (e) {
    print("Warning: Could not load .env file. Check if it exists in root. $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CABANK Mobile',
      debugShowCheckedModeBanner: false,


      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routes: {

        '/dashboard': (context) => const DashboardScreen(), // <--- THIS FIXES THE ERROR

      },


      home: const SplashScreen(),
    );
  }
}
