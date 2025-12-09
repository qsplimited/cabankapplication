// File: lib/api/mock_otp_service.dart

import 'dart:async';

// Mock phone number and OTP for demonstration
const String mockRegisteredMobile = '9876543210';
const String mockValidOtp = '123456';

abstract class OtpService {
  Future<String> sendOtp(String mobileNumber); // Returns success message or throws error
  Future<bool> verifyOtp(String mobileNumber, String otp);
}

class MockOtpService implements OtpService {
  @override
  Future<String> sendOtp(String mobileNumber) async {
    await Future.delayed(const Duration(milliseconds: 1000)); // Simulate network delay
    if (mobileNumber == mockRegisteredMobile) {
      print('Mock OTP Sent: $mockValidOtp to $mobileNumber');
      return 'OTP successfully sent to $mobileNumber.';
    } else {
      throw Exception('Mobile number not registered for OTP service.');
    }
  }

  @override
  Future<bool> verifyOtp(String mobileNumber, String otp) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate verification delay

    // Check if OTP matches the mock value
    if (mobileNumber == mockRegisteredMobile && otp == mockValidOtp) {
      return true;
    } else {
      return false;
    }
  }
}