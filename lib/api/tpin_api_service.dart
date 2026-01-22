// lib/api/tpin_api_service.dart
import '../api/banking_service.dart'; // Keeping this for the mock data access

class TpinApiService {
  final BankingService _mockService = BankingService();

  Future<bool> verifyMobile(String mobile) async {
    // Logic from your old service
    return _mockService.findAccountByMobileNumber(mobile);
  }

  Future<String> requestOtp() async {
    return await _mockService.requestTpinOtp();
  }

  Future<void> validateOtp(String otp) async {
    await _mockService.validateTpinOtp(otp);
  }

  Future<String> updatePin({required String newPin, String? oldPin}) async {
    return await _mockService.updateTransactionPin(
      newPin: newPin,
      oldPin: oldPin,
    );
  }
}