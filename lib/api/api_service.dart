import 'package:dio/dio.dart';
import 'i_device_service.dart';
import '../models/registration_models.dart';
import 'api_constants.dart';

class ApiService implements IDeviceService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {'Accept': '*/*'},
    connectTimeout: const Duration(seconds: 10),
  ));

  @override
  Future<AuthResponse> verifyCredentials(AuthRequest request) async {
    try {
      final response = await _dio.post('/customer/login', queryParameters: {
        'customerId': request.customerId,
        'password': request.password,
      });
      final bool isOk = response.data['value'] == true;
      return AuthResponse(
        success: isOk,
        message: response.data['message'] ?? (isOk ? "Success" : "Invalid Credentials"),
      );
    } catch (e) {
      return AuthResponse(success: false, message: "Connection Error");
    }
  }

  // IMPLEMENTATION FOR FORGOT MPIN
  @override
  Future<AuthResponse> sendOtpByCustomerId(String customerId) async {
    try {
      // Hits: /customer/sendotp/by/customer/id?customerId=...
      final response = await _dio.post('/customer/sendotp/by/customer/id', queryParameters: {
        'customerId': customerId,
      });
      final bool isOk = response.data['value'] == true;
      return AuthResponse(
        success: isOk,
        message: response.data['message'] ?? (isOk ? "OTP Sent Successfully" : "Failed to send OTP"),
      );
    } catch (e) {
      return AuthResponse(success: false, message: "Network Error: OTP not sent");
    }
  }

  @override
  Future<bool> verifyOtp({required String otp, required String customerId, required String deviceId}) async {
    try {
      final response = await _dio.get('/customer/otp/validate', queryParameters: {
        'customerId': customerId,
        'otp': otp,
        'deviceId': deviceId,
      });
      return response.data['value'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> finalizeRegistration({
    required String mpin,
    required String deviceId,
    required String customerId,
  }) async {
    try {
      final response = await _dio.post('/customer/set/mpin', queryParameters: {
        'customerId': customerId,
        'mpin': mpin,
      });
      return {
        'success': response.data['value'] == true,
        'message': response.data['message'] ?? "Success"
      };
    } catch (e) {
      return {'success': false, 'message': "Network Error during setup"};
    }
  }

  @override
  Future<AuthResponse> loginWithMpin({required String mpin, required String deviceId}) async {
    try {
      final response = await _dio.get('/customer/login/bympin', queryParameters: {
        'deviceId': deviceId,
        'mpin': mpin,
      });
      final bool isOk = response.data['value'] == true;
      return AuthResponse(
        success: isOk,
        message: response.data['message'] ?? (isOk ? "Login Successful" : "Invalid PIN"),
      );
    } catch (e) {
      return AuthResponse(success: false, message: "Network Error");
    }
  }

  @override
  Future<bool> checkDeviceBinding(String deviceId) async {
    try {
      final response = await _dio.get('/customer/check-binding', queryParameters: {'deviceId': deviceId});
      return response.data['value'] == true;
    } catch (e) {
      return false;
    }
  }
}