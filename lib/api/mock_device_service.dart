import 'dart:async';
import 'i_device_service.dart';

class MockDeviceService implements IDeviceService {
  static const Duration _simulatedNetworkDelay = Duration(seconds: 1);

  // --- MOCK STORAGE & TEST DATA ---
  static const String _testAccount = '123456';
  static const String _testMobile = '9999999999';
  static const String _testDob = '01/01/1980';
  static const String _fixedOtp = '123456';

  static bool _isDeviceBound = false;
  static String _storedMpin = '112233';
  // ---------------------------------

  @override
  Future<bool> checkDeviceBinding(String deviceId) async {
    await Future.delayed(_simulatedNetworkDelay);
    print('MockDeviceService: Checking binding status... bound: $_isDeviceBound');
    return _isDeviceBound;
  }

  @override
  Future<Map<String, dynamic>> verifyIdentity({
    required String accountNumber,
    required String mobileNumber,
    required String dateOfBirth,
  }) async {
    await Future.delayed(_simulatedNetworkDelay);
    if (accountNumber == _testAccount && mobileNumber == _testMobile && dateOfBirth == _testDob) {
      return {
        'success': true,
        'otp_code': _fixedOtp,
        'mobile_number': mobileNumber,
        'message': 'Identity Verified. OTP successfully sent to $mobileNumber (Use: $_fixedOtp)'
      };
    } else {
      return {
        'success': false,
        'message': 'Identity verification failed. Please ensure all details match.',
      };
    }
  }

  @override
  Future<bool> verifyOtp({
    required String mobileNumber,
    required String otp,
    // NOTE: The optional 'mockOtpCheck' parameter must be handled *outside*
    // the contract. For simplicity in this flow, we will assume all verification
    // uses the *fixed* OTP once the identity is verified.
  }) async {
    await Future.delayed(_simulatedNetworkDelay);

    // For this simplified mock, we always check against the fixed OTP.
    // In a real app, this logic would depend on a server-side state lookup.
    final String validationCode = _fixedOtp;

    print('MockService: Verifying OTP. Input: $otp, Required: $validationCode');
    return otp == validationCode;
  }

  @override
  Future<void> setMpin({required String mpin}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _storedMpin = mpin;
    print('MockService: MPIN successfully set during registration: $_storedMpin');
  }

  @override
  Future<Map<String, dynamic>> finalizeRegistration({
    required String mobileNumber,
    required String mpin,
    required String deviceId,
  }) async {
    await Future.delayed(_simulatedNetworkDelay);
    _isDeviceBound = true;
    print('MockService: Device binding successful. Flag set to true.');

    return {
      'success': true,
      'message': 'Device successfully bound and registration complete.',
    };
  }

  @override
  Future<bool> loginWithMpin({required String mpin}) async {
    await Future.delayed(_simulatedNetworkDelay);
    print('MockService: Attempting login with MPIN: $mpin. Stored MPIN: $_storedMpin');

    if (_storedMpin.isEmpty) {
      return false;
    }

    return mpin == _storedMpin;
  }

  @override
  Future<Map<String, dynamic>> resetMpin({required String newMpin}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Set the new MPIN, completing the reset process.
    _storedMpin = newMpin;

    print('MockService: MPIN successfully reset to: $_storedMpin');

    return {
      'success': true,
      'message': 'Your MPIN has been successfully reset. Please login with your new MPIN.',
    };
  }

  // DEBUG/RESET METHOD
  void resetBinding() {
    _isDeviceBound = false;
    print('MockService: Binding has been reset (allowing re-registration).');
  }
}
