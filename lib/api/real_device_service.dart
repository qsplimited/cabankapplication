import 'package:dio/dio.dart';
import 'i_device_service.dart';
import '../models/registration_models.dart';

class RealDeviceService implements IDeviceService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.0.102:8088',
    headers: {'Accept': '*/*'}, // Matches Swagger Header
  ));

  @override
  Future<AuthResponse> verifyCredentials(AuthRequest request) async {
    try {
      // Step 1: Login
      // We use queryParameters because Spring Boot @RequestParam needs them in the URL
      final res = await _dio.post('/customer/login', queryParameters: {
        'customerId': request.customerId,
        'password': request.password,
      });

      return AuthResponse(
        success: res.data['value'] == true,
        message: res.data['message'] ?? 'Success',
      );
    } catch (e) {
      print("Login Error: $e");
      return AuthResponse(success: false, message: "Invalid ID or Password");
    }
  }

  @override
  Future<bool> verifyOtp({
    required String otp,
    required String customerId,
    required String deviceId
  }) async {
    try {
      // Step 2: OTP Validate
      // URL: http://192.168.0.102:8088/customer/otp/validate
      final res = await _dio.get('/customer/otp/validate', queryParameters: {
        'customerId': customerId,
        'otp': otp,
        'deviceId': deviceId,
      });

      // If the API returns {"value": true, "message": "Login successful"}
      return res.data['value'] == true;
    } catch (e) {
      print("OTP API Error: $e");
      return false;
    }
  }
  @override
  Future<Map<String, dynamic>> finalizeRegistration({required String mpin, required String deviceId, required String customerId}) async {
    final res = await _dio.post('/customer/set/mpin', queryParameters: {
      'customerId': customerId,
      'mpin': mpin,
    });
    return {'success': res.data['value'] == true, 'message': res.data['message']};
  }

  @override
  Future<AuthResponse> loginWithMpin({required String mpin, required String deviceId}) async {
    // GET http://localhost:8088/customer/login/bympin?deviceId=...&mpin=...
    final res = await _dio.get('/customer/login/bympin', queryParameters: {
      'deviceId': deviceId,
      'mpin': mpin,
    });
    return AuthResponse(
      success: res.data['value'] == true,
      message: res.data['message'] ?? '',
    );
  }

  @override
  Future<bool> checkDeviceBinding(String deviceId) async {
    try {
      final res = await _dio.get('/customer/check-binding', queryParameters: {'deviceId': deviceId});
      return res.data['value'] == true;
    } catch (e) {
      return false;
    }
  }
}