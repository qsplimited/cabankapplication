import '../models/registration_models.dart';

abstract class IDeviceService {
  Future<bool> checkDeviceBinding(String deviceId);
  Future<AuthResponse> verifyCredentials(AuthRequest request);

  // ADD THIS LINE: This allows the Provider to call this method
  Future<AuthResponse> sendOtpByCustomerId(String customerId);

  Future<bool> verifyOtp({
    required String otp,
    required String customerId,
    required String deviceId
  });

  Future<Map<String, dynamic>> finalizeRegistration({
    required String mpin,
    required String deviceId,
    required String customerId,
  });

  Future<AuthResponse> loginWithMpin({
    required String mpin,
    required String deviceId
  });
}