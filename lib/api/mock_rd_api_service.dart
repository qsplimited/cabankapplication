// File: lib/api/mock_rd_api_service.dart
import 'dart:async';
import '../models/rd_models.dart';
import '../api/rd_api_service.dart';
import '../models/fd_models.dart';
import '../models/receipt_models.dart';

class MockRdApiService implements RdApiService {
  // Use a consistent mock transaction ID for flow testing
  static const String mockTransactionIdRd = 'RD-TXN-998877';

  @override
  Future<SourceAccount> fetchSourceAccount() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return SourceAccount(
      accountNumber: 'SAV-RD-12345678',
      availableBalance: 98567.50,
      dailyLimit: 50000.0,
      nomineeNames: ['Suresh Kumar', 'Aarti Sharma', 'Self'],
    );
  }

  @override
  Future<List<DepositScheme>> fetchDepositSchemes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      DepositScheme(id: 'RD-001', name: 'Standard RD', interestRate: 6.85),
      DepositScheme(id: 'RD-002', name: 'Senior Citizen RD', interestRate: 7.50),
      DepositScheme(id: 'RD-003', name: 'Flexi RD', interestRate: 7.05),
    ];
  }

  @override
  Future<RdMaturityDetails> calculateMaturity({
    required double installmentAmount,
    required String schemeId,
    required int tenureYears,
    required int tenureMonths,
    required int tenureDays,
    required String nomineeName,
    required String sourceAccountId,
    required String frequencyMode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final totalMonths = (tenureYears * 12) + tenureMonths;
    final totalPrincipal = installmentAmount * totalMonths;
    final interest = totalPrincipal * 0.07; // 7% mock interest

    return RdMaturityDetails(
      totalPrincipalAmount: totalPrincipal,
      interestEarned: interest,
      maturityAmount: totalPrincipal + interest,
      maturityDate: '24-Mar-${DateTime.now().year + tenureYears}',
    );
  }

  @override
  Future<String> submitRdDeposit({
    required RdInputData inputData,
    required RdMaturityDetails maturityDetails,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return mockTransactionIdRd;
  }

  @override
  Future<DepositReceipt> fetchDepositReceipt(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final now = DateTime.now();

    // FIXED: Mapped your mock fields to the correct DepositReceipt model fields
    // 1. RD RENEWAL
    if (transactionId.contains('RENEW')) {
      return DepositReceipt(
        receiptType: ReceiptType.renewal,
        accountType: 'RD',
        transactionId: transactionId,
        date: now,
        nomineeName: 'Suresh Kumar',
        accountNumber: 'RD-NEW-4455',
        oldAccountNumber: 'RD-OLD-1122',
        schemeName: 'Recurring Renewal',
        interestRate: 6.9,
        tenure: '1 Year',
        amount: 5000.0,
        maturityDate: '23-Dec-2026',
        maturityAmount: 62500.0,
        maturityInstruction: 'Close on Maturity',
        lienStatus: 'Nil',
      );
    }

    // 2. RD CLOSURE
    if (transactionId.contains('CLOSE')) {
      return DepositReceipt(
        receiptType: ReceiptType.closure,
        accountType: 'RD',
        transactionId: transactionId,
        date: now.subtract(const Duration(days: 730)),
        nomineeName: 'Suresh Kumar',
        accountNumber: 'RD-MATURED-01',
        schemeName: 'Standard RD Settlement',
        interestRate: 6.8,
        tenure: '2 Years',
        amount: 120000.0,
        accruedInterest: 8400.0,
        penaltyAmount: 0.0,
        taxDeducted: 840.0,
        netPayout: 127560.0,
        destinationAccount: 'SAV-XXX-1234',
        closureStatus: 'Matured',
        lienStatus: 'Nil',
      );
    }

    // 3. NEW RD OPENING (Matches your new mock ID)
    return DepositReceipt(
      receiptType: ReceiptType.opening,
      accountType: 'RD',
      transactionId: transactionId,
      date: now,
      valueDate: now,
      nomineeName: 'Suresh Kumar',
      accountNumber: 'RD-998877',
      schemeName: 'Standard Recurring Deposit',
      interestRate: 6.85,
      tenure: '2 Years',
      amount: 5000.0,
      maturityDate: '09-Dec-2027',
      maturityAmount: 128220.0,
      maturityInstruction: 'Credit to Account',
      lienStatus: 'Nil',
      sourceAccount: 'SAV-XXX-1234',
    );
  }
}