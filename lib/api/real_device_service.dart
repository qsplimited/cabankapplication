import 'package:dio/dio.dart';
import 'i_device_service.dart';
import 'api_constants.dart';
import '../models/registration_models.dart';

class RealDeviceService implements IDeviceService {
  final Dio _dio = Dio(BaseOptions(
    // 2. CHANGE THIS: Use the Constant instead of hardcoding
    baseUrl: ApiConstants.baseUrl,
    headers: {'Accept': '*/*'},
    connectTimeout: const Duration(seconds: 10), // Add a timeout
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
// real_device_service.dart
  @override
  Future<AuthResponse> sendOtpByCustomerId(String customerId) async {
    try {
      // POST request to the specific endpoint for Forgot MPIN
      final res = await _dio.post(
          '/customer/sendotp/by/customer/id',
          queryParameters: {'customerId': customerId}
      );

      return AuthResponse(
        success: res.data['value'] == true,
        message: res.data['message'] ?? 'OTP Sent Successfully',
      );
    } catch (e) {
      print("Send OTP Error: $e");
      return AuthResponse(success: false, message: "Failed to send OTP. Please try again.");
    }
  }
// real_device_service.dart

  @override
  Future<AuthResponse> loginWithMpin({required String mpin, required String deviceId}) async {
    try {
      // DEBUG: Check if deviceId is empty before sending
      print("LOGIN ATTEMPT - DeviceID: '$deviceId', PIN: '$mpin'");

      final res = await _dio.get('/customer/login/bympin', queryParameters: {
        'deviceId': deviceId,
        'mpin': mpin,
      });

      return AuthResponse(
        success: res.data['value'] == true, // Explicitly check the backend's boolean
        message: res.data['message'] ?? '',
      );
    } catch (e) {
      print("Network Error: $e");
      return AuthResponse(success: false, message: "Server connection failed");
    }
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