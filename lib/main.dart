import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Replaced flutter_bloc
import 'package:cabankapplication/api/i_device_service.dart';
import 'package:cabankapplication/api/mock_device_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import your new Riverpod providers
import 'providers/tpin_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';

final IDeviceService globalDeviceService = MockDeviceService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
    print("Environment variables loaded!");
  } catch (e) {
    print("Warning: Could not load .env file. $e");
  }

  runApp(
    // Riverpod's ProviderScope is the "Root".
    // It automatically manages all providers (T-PIN, Registration, etc.)
    const ProviderScope(
      child: MyApp(),
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