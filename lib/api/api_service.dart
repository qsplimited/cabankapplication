import 'package:dio/dio.dart';
import 'i_device_service.dart';
import '../models/registration_models.dart';
import 'api_constants.dart';

class ApiService implements IDeviceService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    // Removed strict connectTimeout to allow stable connections on local Wi-Fi
    headers: {'Accept': '*/*'},
  ));

  @override
  Future<AuthResponse> verifyCredentials(AuthRequest request) async {
    try {
      final response = await _dio.post('/customer/login', queryParameters: request.toJson());

      // Use 'value' key from Spring Boot
      final bool isOk = response.data['value'] == true;

      return AuthResponse(
        success: isOk,
        message: response.data['message'] ?? (isOk ? "Success" : "Invalid Credentials"),
      );
    } catch (e) {
      return AuthResponse(success: false, message: "Connection Error: Check Server IP");
    }
  }

  @override
  Future<bool> verifyOtp({required String otp, String? customerId, String? deviceId}) async {
    try {
      final response = await _dio.get('/customer/otp/validate', queryParameters: {
        'customerId': customerId,
        'otp': otp,
        'deviceId': deviceId,
      });
      // Backend uses 'value' for true/false
      return response.data['value'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> finalizeRegistration({
    required String mpin,
    required String deviceId,
    String? customerId,
  }) async {
    try {
      final response = await _dio.post('/customer/set/mpin', queryParameters: {
        'customerId': customerId,
        'mpin': mpin,
        'deviceId': deviceId,
      });
      return {
        'success': response.data['value'] == true,
        'message': response.data['message'] ?? "MPIN Set Successfully"
      };
    } catch (e) {
      return {'success': false, 'message': "Network Error during MPIN setup"};
    }
  }

  @override
  Future<AuthResponse> loginWithMpin({required String mpin, String? deviceId}) async {
    try {
      // Step: GET /customer/login/bympin
      final response = await _dio.get('/customer/login/bympin', queryParameters: {
        'deviceId': deviceId,
        'mpin': mpin,
      });

      // CRITICAL FIX: Direct check for 'value' key
      final bool isOk = response.data['value'] == true;
      final String msg = response.data['message'] ?? (isOk ? "Login Successful" : "Invalid PIN");

      return AuthResponse(
        success: isOk,
        message: msg,
      );
    } catch (e) {
      print("Login Error: $e");
      return AuthResponse(
          success: false,
          message: "Network Error: Cannot reach server at ${ApiConstants.baseUrl}"
      );
    }
  }

  // --- Placeholder methods to satisfy IDeviceService interface ---

  @override
  Future<bool> checkDeviceBinding(String deviceId) async {
    try {
      final response = await _dio.get('/customer/check/binding', queryParameters: {'deviceId': deviceId});
      return response.data['value'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AuthResponse> verifyIdentityForReset(AuthRequest request) async {
    // Basic implementation for interface compliance
    return verifyCredentials(request);
  }

  @override
  Future<Map<String, dynamic>> resetMpin({required String newMpin, String? customerId}) async {
    return {'success': false, 'message': 'Reset not implemented'};
  }
}