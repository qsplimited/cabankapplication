import '../models/registration_models.dart';

abstract class IDeviceService {
  Future<bool> checkDeviceBinding(String deviceId);

  // Step 1: Customer ID & Password
  Future<AuthResponse> verifyCredentials(AuthRequest request);

  // Step 2: OTP
  Future<bool> verifyOtp({required String otp, String? sessionId});

  // Step 4: Finalize & Bind
  Future<Map<String, dynamic>> finalizeRegistration({
    required String mpin,
    required String deviceId,
    String? sessionId,
  });

  Future<AuthResponse> loginWithMpin({required String mpin});

  Future<AuthResponse> verifyIdentityForReset(AuthRequest request);

  // NEW: Finalize the new MPIN
  Future<Map<String, dynamic>> resetMpin({
    required String newMpin,
    String? sessionId
  });

}