// File: lib/api/mock_rd_api_service.dart
import 'dart:async';
import '../models/rd_models.dart';
import '../api/rd_api_service.dart';
import '../models/fd_models.dart';
import '../models/receipt_models.dart';

class MockRdApiService implements RdApiService {
  @override
  Future<DepositReceipt> fetchDepositReceipt(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    final now = DateTime.now();

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
        amount: 5000.0, // Monthly installment
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
        date: now.subtract(const Duration(days: 730)), // 2 years ago
        nomineeName: 'Suresh Kumar',
        accountNumber: 'RD-MATURED-01',
        schemeName: 'Standard RD Settlement',
        interestRate: 6.8,
        tenure: '2 Years',
        amount: 120000.0, // Total principal paid
        accruedInterest: 8400.0,
        penaltyAmount: 0.0,
        taxDeducted: 840.0,
        netPayout: 127560.0,
        destinationAccount: 'SAV-XXX-1234',
        closureStatus: 'Matured',
        lienStatus: 'Nil',
      );
    }

    // 3. NEW RD OPENING
    return DepositReceipt(
      receiptType: ReceiptType.opening,
      accountType: 'RD',
      transactionId: transactionId,
      date: now,
      valueDate: now,
      nomineeName: 'Suresh Kumar',
      accountNumber: 'RD-998877',
      schemeName: 'Regular RD',
      interestRate: 6.85,
      tenure: '2 Years',
      amount: 5000.0, // Installment
      maturityDate: '23-Dec-2027',
      maturityAmount: 128500.0,
      maturityInstruction: 'Credit to Account',
      lienStatus: 'Nil',
      sourceAccount: 'SAV-XXX-1234',
    );
  }

  // Mock implementations for RD workflows
  @override Future<SourceAccount> fetchSourceAccount() async => throw UnimplementedError();
  @override Future<List<DepositScheme>> fetchDepositSchemes() async => [];
  @override Future<RdMaturityDetails> calculateMaturity({required double installmentAmount, required String schemeId, required int tenureYears, required int tenureMonths, required int tenureDays, required String nomineeName, required String sourceAccountId, required String frequencyMode}) async => throw UnimplementedError();
  @override Future<String> submitRdDeposit({required RdInputData inputData, required RdMaturityDetails maturityDetails}) async => 'RD-TXN-123';
}