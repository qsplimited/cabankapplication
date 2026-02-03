import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  final Dio dio;
  final _storage = const FlutterSecureStorage();

  ApiClient(String baseUrl)
      : dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15), // Important for banking apps
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  ) {
    _initializeInterceptors();
  }

  void _initializeInterceptors() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Automatically attach the token if it exists in secure storage
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        print("API REQUEST[${options.method}] => PATH: ${options.path}");
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Global error handling: e.g., if 401, force logout
        print("API ERROR[${e.response?.statusCode}] => MESSAGE: ${e.message}");
        return handler.next(e);
      },
    ));
  }
}