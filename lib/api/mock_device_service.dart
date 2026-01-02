// lib/api/mock_device_service.dart

import 'dart:async';
import 'i_device_service.dart';
import '../models/registration_models.dart';

class MockDeviceService implements IDeviceService {


  static const Duration _delay = Duration(seconds: 1);

  // MOCK DATA - Credentials for Step 1
  static const String _validCustId = "A0001";
  static const String _validPass = "pass123";
  static const String _mockOtp = "123456";

  // --- PERSISTENCE ---
  // Set _isBound to TRUE by default so the app skips registration and goes to LOGIN
  static bool _isBound = false;

  // Set the DEFAULT PIN to 112233 so it works every time you start the app
  static String _storedMpin = "112233";

  @override
  Future<AuthResponse> verifyCredentials(AuthRequest request) async {
    await Future.delayed(_delay);
    if (request.customerId == _validCustId && request.password == _validPass) {
      return AuthResponse(success: true, otpCode: _mockOtp, sessionId: "MOCK_SESSION_999");
    }
    return AuthResponse(success: false, message: "Invalid Customer ID or Password");
  }

  @override
  Future<bool> verifyOtp({required String otp, String? sessionId}) async {
    await Future.delayed(_delay);
    return otp == _mockOtp;
  }

  @override
  Future<Map<String, dynamic>> finalizeRegistration({
    required String mpin,
    required String deviceId,
    String? sessionId,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    // Update the stored PIN with what the user typed in Step 3
    _storedMpin = mpin;
    _isBound = true;

    print('--- MOCK API BINDING SUCCESSFUL ---');
    print('Device: $deviceId');
    print('New Active MPIN: $_storedMpin');

    return {'success': true, 'message': 'Device Bound Successfully'};
  }

  @override
  Future<bool> checkDeviceBinding(String deviceId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // 2. REMOVE "return true;" and use the variable
    return _isBound;
  }

  @override
  Future<bool> loginWithMpin({required String mpin}) async {
    await Future.delayed(_delay);

    // LOGIC: Accept the user-set pin OR the master test pin (112233)
    bool isValid = (mpin == _storedMpin || mpin == "112233");

    print('--- LOGIN ATTEMPT ---');
    print('Entered PIN: $mpin');
    print('Stored PIN: $_storedMpin');
    print('Master PIN: 112233');
    print('Result: ${isValid ? "SUCCESS - GOING TO DASHBOARD" : "FAILED"}');

    return isValid;
  }

  @override
  Future<AuthResponse> verifyIdentityForReset(AuthRequest request) async {
    await Future.delayed(_delay);
    if (request.customerId == _validCustId) {
      return AuthResponse(success: true, otpCode: _mockOtp, sessionId: "RESET_001");
    }
    return AuthResponse(success: false, message: "Identity not found");
  }

  @override
  Future<Map<String, dynamic>> resetMpin({required String newMpin, String? sessionId}) async {
    await Future.delayed(_delay);
    _storedMpin = newMpin;
    print('--- MPIN RESET SUCCESSFUL ---');
    print('New MPIN set to: $_storedMpin');
    return {'success': true};
  }
}