import 'dart:async';
import 'i_device_service.dart';

class MockDeviceService implements IDeviceService {
  static const Duration _simulatedNetworkDelay = Duration(seconds: 1);

  // --- MOCK STORAGE & TEST DATA ---
  static const String _testAccount = '123456';
  static const String _testMobile = '9999999999';
  static const String _testDob = '01/01/1980';
  static const String _fixedOtp = '123456';

  // FIX: Set a default MPIN for development testing.
  // This value will be available immediately after a restart.
  static bool _isDeviceBound = false;
  static String _storedMpin = '112233'; // <-- Use this MPIN to test login after a full restart!
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
  }) async {
    await Future.delayed(_simulatedNetworkDelay);
    return otp == _fixedOtp;
  }

  @override
  Future<void> setMpin({required String mpin}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // When registration runs, it successfully stores the chosen MPIN.
    _storedMpin = mpin;
    print('MockService: MPIN successfully set to: $_storedMpin');
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

  // DEBUG/RESET METHOD
  void resetBinding() {
    _isDeviceBound = false;
    // We intentionally do NOT reset _storedMpin here.
    // This allows the user to log back in after re-registering the device,
    // simulating MPIN persistence on the server.
    print('MockService: Binding has been reset (allowing re-registration).');
  }
}
