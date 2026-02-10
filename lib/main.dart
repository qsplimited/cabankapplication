import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:shared_preferences/shared_preferences.dart';

// Import the real service we just fixed
import 'package:cabankapplication/api/real_device_service.dart';
import 'package:cabankapplication/api/i_device_service.dart';

// Existing imports
import 'api/fd_api_service.dart';
import 'api/mock_fd_api_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/fd_td_input_screen.dart';

import 'screens/login_screen.dart';
// 1. Fixed FD API Provider
final fdApiServiceProvider = Provider<FdApiService>((ref) {
  return MockFdApiService();
});

// 2. IMPORTANT: Switch to RealDeviceService for your Registration Flow
// This ensures your registration/login uses the real API we fixed.
final IDeviceService globalDeviceService = RealDeviceService();

final deviceServiceProvider = Provider<IDeviceService>((ref) {
  return globalDeviceService;
});




Future<void> main() async {


  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // 3. Check if a user is already registered
  final bool isRegistered = prefs.getBool('is_registered') ?? false;
  final String? savedId = prefs.getString('saved_customer_id');


  try {
    // Attempt to load env, but don't crash if missing
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Dotenv load failed: $e");
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CABANK Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // --- Navigation Management ---
// inside MyApp class in main.dart
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/dashboard':
            return MaterialPageRoute(builder: (_) => const DashboardScreen());
          case '/fd_input':
            final apiService = ref.read(fdApiServiceProvider);
            return MaterialPageRoute(
              builder: (_) => FdTdInputScreen(apiService: apiService),
            );
          default:
            return null;
        }
      },
      // Splash screen will decide if we go to Registration or Login
      home: const SplashScreen(),
    );
  }
}