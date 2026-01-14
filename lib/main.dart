import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Added for BLoC logic
import 'package:cabankapplication/api/i_device_service.dart';
import 'package:cabankapplication/api/mock_device_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'bloc/registration_bloc.dart'; // Added to access the Bloc class
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';

final IDeviceService globalDeviceService = MockDeviceService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Keep this as is for your future API setup
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded!");
  } catch (e) {
    print("Warning: Could not load .env file. Check if it exists in root. $e");
  }

  runApp(
    // Added BlocProvider here to make it available to all screens
    BlocProvider(
      create: (context) => RegistrationBloc(),
      child: const MyApp(),
    ),
  );
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
        '/dashboard': (context) => const DashboardScreen(),
      },
      home: const SplashScreen(),
    );
  }
}