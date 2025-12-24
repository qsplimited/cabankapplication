// File: lib/api/mock_fd_api_service.dart
import 'dart:async';
import '../models/fd_models.dart';
import '../api/fd_api_service.dart';
import '../models/receipt_models.dart';

class MockFdApiService implements FdApiService {
  @override
  Future<DepositReceipt> fetchDepositReceipt(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();

    // 1. RENEWAL ADVICE DATA
    if (transactionId.contains('RENEW')) {
      return DepositReceipt(
        receiptType: ReceiptType.renewal,
        accountType: 'FD',
        transactionId: transactionId,
        date: now,
        valueDate: now, // Renewal starts today
        nomineeName: 'Deepika Padukone',
        accountNumber: 'FD-NEW-8899',
        oldAccountNumber: 'FD-OLD-1122',
        schemeName: 'Standard Renewal',
        interestRate: 7.25,
        tenure: '1 Year',
        amount: 53625.0, // Amount from matured FD
        maturityDate: '23-Dec-2026',
        maturityAmount: 57512.0,
        maturityInstruction: 'Auto-Renew Principal',
        lienStatus: 'Nil',
      );
    }

    // 2. CLOSURE ADVICE DATA
    if (transactionId.contains('CLOSE')) {
      return DepositReceipt(
        receiptType: ReceiptType.closure,
        accountType: 'FD',
        transactionId: transactionId,
        date: now.subtract(const Duration(days: 365)), // Opened 1 year ago
        valueDate: now.subtract(const Duration(days: 365)),
        nomineeName: 'Deepika Padukone',
        accountNumber: 'FD-776655',
        schemeName: 'Fixed Deposit Closure',
        interestRate: 6.5,
        tenure: '1 Year',
        amount: 50000.0, // Original Principal
        accruedInterest: 3250.0,
        penaltyAmount: 0.0,
        taxDeducted: 325.0,
        netPayout: 52925.0,
        destinationAccount: 'SAV-12345678',
        closureStatus: 'Matured',
        lienStatus: 'Released',
      );
    }

    // 3. NEW OPENING DATA (Default)
    return DepositReceipt(
      receiptType: ReceiptType.opening,
      accountType: 'FD',
      transactionId: transactionId,
      date: now,
      valueDate: now.add(const Duration(days: 1)), // Interest starts tomorrow
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

  // Basic mock implementations for other required methods
  @override Future<SourceAccount> fetchSourceAccount() async => SourceAccount(accountNumber: 'SAV-987654321', availableBalance: 150000, dailyLimit: 50000, nomineeNames: []);
  @override Future<List<DepositScheme>> fetchDepositSchemes() async => [];
  @override Future<MaturityDetails> calculateMaturity({required double amount, required String schemeId, required int tenureYears, required int tenureMonths, required int tenureDays, required String nomineeName, required String sourceAccountId}) async => throw UnimplementedError();
  @override Future<void> requestOtp({required String accountId}) async {}
  @override Future<FdConfirmationResponse> confirmDeposit({required String otp, required double amount, required String accountId}) async => throw UnimplementedError();
}