// File: lib/api/mock_fd_api_service.dart

import 'dart:async';
import 'dart:math';
import '../models/fd_models.dart'; // Imports the updated FdConfirmationResponse
import '../api/fd_api_service.dart'; // Import the abstract class
import '../models/receipt_models.dart'; // 🌟 REQUIRED IMPORT for DepositReceipt, mock IDs

// Simulates network latency
const Duration _mockLatency = Duration(milliseconds: 700);

// Mock ID constants (assuming they are defined in a mock_constants file or globally)
const String mockTransactionIdFd = 'FD-TXN-123456789';


// Utility extension for title casing scheme names
extension StringExtension on String {
  String titleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

// NOTE: FdConfirmationResponse is now imported from fd_models.dart

class MockFdApiService implements FdApiService {
  @override
  Future<SourceAccount> fetchSourceAccount() {
    final account = SourceAccount(
      accountNumber: '1234 5678 9012',
      availableBalance: 987654.32,
      dailyLimit: 1000000.00,
      nomineeNames: ['Deepika P. Padukone', 'Ranveer S. Singh'],
    );
    return Future.delayed(_mockLatency, () => account);
  }

  @override
  Future<List<DepositScheme>> fetchDepositSchemes() {
    final schemes = [
      DepositScheme(id: 's1', name: 'premium plus fd scheme', interestRate: 7.5),
      DepositScheme(id: 's2', name: 'standard fixed deposit', interestRate: 6.8),
      DepositScheme(id: 's3', name: 'tax saver long term', interestRate: 7.0),
    ];
    return Future.delayed(_mockLatency, () => schemes);
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
  }) {
    const double rate = 7.5;
    final double totalDays = (tenureYears * 365) + (tenureMonths * 30) + tenureDays.toDouble();

    final double timeInYears = totalDays / 365.0;
    final double interest = (amount * rate * timeInYears) / 100.0;
    final double maturityAmount = amount + interest;

    final now = DateTime.now();
    final maturityDate = DateTime(
      now.year + tenureYears,
      now.month + tenureMonths,
      now.day + tenureDays,
    );
    final formattedDate = '${maturityDate.day.toString().padLeft(2, '0')}/${maturityDate.month.toString().padLeft(2, '0')}/${maturityDate.year}';

    final details = MaturityDetails(
      principalAmount: amount,
      maturityAmount: double.parse(maturityAmount.toStringAsFixed(2)),
      interestEarned: double.parse(interest.toStringAsFixed(2)),
      maturityDate: formattedDate,
    );

    return Future.delayed(_mockLatency, () => details);
  }

  @override
  Future<FdConfirmationResponse> confirmDeposit({
    required String tpin,
    required double amount,
    required String accountId,
  }) {
    // 🌟 Mock T-PIN validation logic: Success if TPIN is '123456'
    if (tpin == '123456' && amount > 0) {
      // Simulate successful deduction and FD creation
      return Future.delayed(_mockLatency, () => FdConfirmationResponse(
        success: true,
        message: 'Fixed Deposit of ₹${amount.toStringAsFixed(2)} successfully created!',
        transactionId: mockTransactionIdFd, // Uses the corrected field name
      ));
    } else if (tpin != '123456') {
      // Simulate T-PIN failure
      return Future.delayed(_mockLatency, () => FdConfirmationResponse(
        success: false,
        message: 'Invalid T-PIN. Please try again.',
      ));
    } else {
      // General failure case
      return Future.delayed(_mockLatency, () => FdConfirmationResponse(
        success: false,
        message: 'Transaction failed due to insufficient funds or daily limit exceeded.',
      ));
    }
  }

  @override
  // 🌟 NEW IMPLEMENTATION: Mock fetchDepositReceipt
  Future<DepositReceipt> fetchDepositReceipt(String transactionId) {
    if (transactionId == mockTransactionIdFd) {
      final receipt = DepositReceipt(
        accountType: 'FD',
        amount: 50000.00,
        newAccountNumber: 'FD001-2025001',
        transactionId: mockTransactionIdFd,
        depositDate: DateTime.now().subtract(const Duration(hours: 1)),
        tenureDescription: '5 Years, 0 Months, 0 Days',
        interestRate: 6.85,
        nomineeName: 'Deepika P. Padukone',
        maturityDate: '09-Dec-2030',
        maturityAmount: 75000.00,
        schemeName: 'Standard Fixed Deposit Scheme',
        paymentHistory: null, // Null for FD
      );
      return Future.delayed(_mockLatency, () => receipt);
    }
    // Handle error case for unknown ID
    return Future.error('Receipt not found for transaction ID: $transactionId');
  }
}