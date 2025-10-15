

abstract class IDeviceService {

  Future<bool> checkDeviceBinding(String deviceId);

  Future<Map<String, dynamic>> verifyIdentity({
    required String accountNumber,
    required String mobileNumber,
    required String dateOfBirth,
  });


  Future<bool> verifyOtp({
    required String mobileNumber,
    required String otp,
  });

  Future<Map<String, dynamic>> finalizeRegistration({
    required String mobileNumber,
    required String mpin,
    required String deviceId
  });

  Future<bool> loginWithMpin({required String mpin});


}