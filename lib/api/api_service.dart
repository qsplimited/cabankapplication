import 'package:dio/dio.dart';
import 'i_device_service.dart';
import '../models/registration_models.dart';

class ApiService implements IDeviceService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: "http://192.168.0.102:8088",
    connectTimeout: const Duration(seconds: 5),
  ));

  @override
  Future<AuthResponse> verifyCredentials(AuthRequest request) async {
    final response = await _dio.post('/customer/login', queryParameters: request.toJson());
    return AuthResponse.fromJson(response.data);
  }

  @override
  Future<bool> verifyOtp({required String otp, String? customerId, String? deviceId}) async {
    final response = await _dio.get('/customer/otp/validate', queryParameters: {
      'customerId': customerId,
      'otp': otp,
      'deviceId': deviceId,
    });
    return response.data['success'] == true;
  }

  @override
  Future<Map<String, dynamic>> finalizeRegistration({
    required String mpin,
    required String deviceId,
    String? customerId,
  }) async {
    final response = await _dio.post('/customer/set/mpin', queryParameters: {
      'customerId': customerId,
      'mpin': mpin,
      'deviceId': deviceId,
    });
    return response.data;
  }

  @override
  Future<AuthResponse> loginWithMpin({required String mpin, String? deviceId}) async {
    // Step 4: Uses GET /customer/login/bympin
    final response = await _dio.get('/customer/login/bympin', queryParameters: {
      'deviceId': deviceId,
      'mpin': mpin,
    });
    return AuthResponse.fromJson(response.data);
  }

  // Placeholder methods to satisfy the interface
  @override
  Future<bool> checkDeviceBinding(String deviceId) async => false;
  @override
  Future<AuthResponse> verifyIdentityForReset(AuthRequest request) async => throw UnimplementedError();
  @override
  Future<Map<String, dynamic>> resetMpin({required String newMpin, String? customerId}) async => {};
}