import 'package:cabankapplication/screens/fd_td_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cabankapplication/api/i_device_service.dart';
import 'package:cabankapplication/api/mock_device_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Import your actual API implementation
import 'api/fd_api_service.dart'; // Ensure this contains the Mock class

import 'api/mock_fd_api_service.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';

// 1. API PROVIDER FIX
// If FdApiService is abstract, return your Mock version here
final fdApiServiceProvider = Provider<FdApiService>((ref) {
  return MockFdApiService(); // Change this to your concrete class name
});

final IDeviceService globalDeviceService = MockDeviceService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
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

      // onGenerateRoute handles the 'apiService' injection safely
      onGenerateRoute: (settings) {
        switch (settings.name) {
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
      home: const SplashScreen(),
    );
  }
}