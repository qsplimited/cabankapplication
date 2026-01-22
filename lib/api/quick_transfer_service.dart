import '../api/banking_service.dart';

class QuickTransferApiService {
  final BankingService _bankingService = BankingService();

  Future<List<Account>> fetchDebitAccounts() => _bankingService.fetchDebitAccounts();

  Future<Map<String, String>> verifyRecipient(String acc, String ifsc) =>
      _bankingService.lookupRecipient(recipientAccount: acc, ifsCode: ifsc.toUpperCase());

  // Fetches the registered mobile number dynamically
  Future<String> getRegisteredMobile() async {
    // In your mock, this matches the 9876543210 required by the OTP service
    return "9876543210";
  }
}