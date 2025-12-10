// File: lib/api/mock_rd_api_service.dart

import 'rd_api_service.dart';
import '../models/fd_models.dart';
import '../models/rd_models.dart';
import '../models/receipt_models.dart'; // 🌟 REQUIRED IMPORT for DepositReceipt, mock IDs

const Duration _mockLatency = Duration(milliseconds: 700);

class MockRdApiService implements RdApiService {
  @override
  Future<SourceAccount> fetchSourceAccount() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return SourceAccount(
      accountNumber: 'XXX-1234567890',
      availableBalance: 98567.50,
      dailyLimit: 50000.00, // Max single installment amount
      nomineeNames: ['Suresh Kumar', 'Aarti Sharma'],
    );
  }

  @override
  Future<List<DepositScheme>> fetchDepositSchemes() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      DepositScheme(id: 'RD-001', name: 'Standard Recurring Deposit', interestRate: 6.85),
      DepositScheme(id: 'RD-002', name: 'Senior Citizen RD Scheme', interestRate: 7.50),
      DepositScheme(id: 'RD-003', name: 'Flexi RD (High Interest)', interestRate: 7.05),
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
    double frequencyFactor = 1.0;
    if (frequencyMode == 'Quarterly') frequencyFactor = 1.0 / 3.0;
    if (frequencyMode == 'Half-Yearly') frequencyFactor = 1.0 / 6.0;

    final totalInstallments = (totalMonths * frequencyFactor).round();
    final rate = schemeId == 'RD-002' ? 0.075 : 0.0685;

    final totalPrincipal = installmentAmount * totalInstallments;
    // Simple linear projection for mock interest calculation
    final estimatedInterest = totalPrincipal * rate * (totalMonths / 12.0) * 0.55;

    return RdMaturityDetails(
      totalPrincipalAmount: totalPrincipal,
      interestEarned: estimatedInterest,
      maturityAmount: totalPrincipal + estimatedInterest,
      maturityDate: '24-Mar-${DateTime.now().year + tenureYears + (tenureMonths > 0 ? 1 : 0)}',
    );
  }

  @override
  // 🌟 NEW IMPLEMENTATION: submitRdDeposit now returns the transaction ID on success
  Future<String> submitRdDeposit({
    required RdInputData inputData,
    required RdMaturityDetails maturityDetails,
  }) async {
    await Future.delayed(_mockLatency);
    // Simulate API call success
    return mockTransactionIdRd; // Return the mock ID
  }

  @override
  // 🌟 NEW IMPLEMENTATION: Mock fetchDepositReceipt
  Future<DepositReceipt> fetchDepositReceipt(String transactionId) {
    if (transactionId == mockTransactionIdRd) {
      final now = DateTime.now();

      // Mock Payment History for RD
      final paymentHistory = [
        PaymentInstallment(
          paymentDate: now.subtract(const Duration(days: 90)),
          amount: 5000.00,
          status: 'Success',
          transactionId: 'RD-INST-1',
          installmentNumber: 1,
        ),
        PaymentInstallment(
          paymentDate: now.subtract(const Duration(days: 60)),
          amount: 5000.00,
          status: 'Success',
          transactionId: 'RD-INST-2',
          installmentNumber: 2,
        ),
        PaymentInstallment(
          paymentDate: now.subtract(const Duration(days: 30)),
          amount: 5000.00,
          status: 'Success',
          transactionId: 'RD-INST-3',
          installmentNumber: 3,
        ),
        PaymentInstallment(
          paymentDate: now,
          amount: 5000.00,
          status: 'Success',
          transactionId: 'RD-INST-4',
          installmentNumber: 4,
        ),
      ];

      final receipt = DepositReceipt(
        accountType: 'RD',
        amount: 5000.00, // Monthly installment
        newAccountNumber: 'RD001-987654',
        transactionId: mockTransactionIdRd,
        depositDate: now.subtract(const Duration(days: 120)), // Original start date
        tenureDescription: '2 Years, 0 Months, 0 Days',
        interestRate: 6.85,
        nomineeName: 'Suresh Kumar',
        maturityDate: '09-Dec-2027',
        maturityAmount: 128220.00,
        schemeName: 'Standard Recurring Deposit',
        paymentHistory: paymentHistory, // Attach payment history
      );
      return Future.delayed(_mockLatency, () => receipt);
    }
    // Handle error case for unknown ID
    return Future.error('Receipt not found for transaction ID: $transactionId');
  }
}