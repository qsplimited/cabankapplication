import 'dart:async';
import '../models/fd_models.dart';
import '../api/fd_api_service.dart';
import '../models/receipt_models.dart';

class MockFdApiService implements FdApiService {
  @override
  Future<SourceAccount> fetchSourceAccount() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return SourceAccount(
      accountNumber: 'SAV-987654321',
      availableBalance: 150000.0,
      dailyLimit: 50000.0,

      nomineeNames: ['Deepika Padukone', 'Ranveer Singh', 'Prakash Padukone'],
    );
  }

  @override
  Future<List<DepositScheme>> fetchDepositSchemes() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return [
      DepositScheme(id: 'fd-01', name: 'High-Yield FD', interestRate: 7.1),
      DepositScheme(id: 'fd-02', name: 'Standard Fixed Deposit', interestRate: 6.5),
      DepositScheme(id: 'fd-03', name: 'Tax Saver FD', interestRate: 7.5),
    ];
  }

  @override
  Future<MaturityDetails> calculateMaturity({
    required double amount,
    required String schemeId,
    required int tenureYears,
    required int tenureMonths,
    required int tenureDays,
    required String nomineeName,
    required String sourceAccountId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return MaturityDetails(
      principalAmount: amount,
      interestEarned: amount * 0.14,
      maturityAmount: amount * 1.14,
      maturityDate: '23-Dec-2027',
    );
  }

  @override
  Future<void> requestOtp({required String accountId}) async {
    print("OTP Requested for $accountId");
  }

  @override
  Future<FdConfirmationResponse> confirmDeposit({
    required String otp,
    required double amount,
    required String accountId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return FdConfirmationResponse(
      success: true,
      message: "Fixed Deposit Created Successfully",
      transactionId: "FD-TXN-${DateTime.now().millisecondsSinceEpoch}",
    );
  }

  @override
  Future<DepositReceipt> fetchDepositReceipt(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();

    // RENEWAL
    if (transactionId.contains('RENEW')) {
      return DepositReceipt(
        receiptType: ReceiptType.renewal,
        accountType: 'FD',
        transactionId: transactionId,
        date: now,
        nomineeName: 'Deepika Padukone',
        accountNumber: 'FD-NEW-8899',
        oldAccountNumber: 'FD-OLD-1122',
        schemeName: 'Standard Renewal',
        interestRate: 7.25,
        tenure: '1 Year',
        amount: 53625.0,
        maturityDate: '23-Dec-2026',
        maturityAmount: 57512.0,
        maturityInstruction: 'Auto-Renew Principal',
        lienStatus: 'Nil',
      );
    }

    // Default: NEW OPENING
    return DepositReceipt(
      receiptType: ReceiptType.opening,
      accountType: 'FD',
      transactionId: transactionId,
      date: now,
      nomineeName: 'Deepika Padukone',
      accountNumber: 'FD-001-2025',
      schemeName: 'High-Yield FD',
      interestRate: 7.1,
      tenure: '2 Years',
      amount: 100000.0,
      maturityDate: '23-Dec-2027',
      maturityAmount: 114700.0,
      maturityInstruction: 'Credit Principal & Interest',
      lienStatus: 'Nil',
      sourceAccount: 'SAV-987654321',
    );
  }
}