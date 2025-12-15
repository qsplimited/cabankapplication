import '../models/fd_models.dart';
import '../models/receipt_models.dart';

abstract class FdApiService {
  // Methods that must be implemented:
  Future<SourceAccount> fetchSourceAccount();
  Future<List<DepositScheme>> fetchDepositSchemes();

  Future<MaturityDetails> calculateMaturity({
    required double amount,
    required String schemeId,
    required int tenureYears,
    required int tenureMonths,
    required int tenureDays,
    required String nomineeName,
    required String sourceAccountId,
  });

  // 🌟 NEW METHOD: Request OTP for confirmation
  Future<void> requestOtp({required String accountId});

  // 🌟 UPDATED: Method for confirming the deposit using OTP
  Future<FdConfirmationResponse> confirmDeposit({
    required String otp, // Parameter name changed from tpin to otp
    required double amount,
    required String accountId,
  });

  // NEW METHOD: Fetch a complete receipt by its transaction ID
  Future<DepositReceipt> fetchDepositReceipt(String transactionId);
}