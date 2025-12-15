// File: lib/api/mock_fd_api_service.dart

import 'dart:async';
import 'dart:math';
import '../models/fd_models.dart';
import '../api/fd_api_service.dart';
import '../models/receipt_models.dart';


const Duration _mockLatency = Duration(milliseconds: 700);


const String mockTransactionIdFd = 'FD-TXN-123456789';
const String mockOtp = '654321';


extension StringExtension on String {
  String titleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

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
  Future<void> requestOtp({required String accountId}) {

    print('MOCK: OTP $mockOtp requested and sent to user\'s device associated with $accountId.');
    return Future.delayed(_mockLatency);
  }

  @override
  Future<FdConfirmationResponse> confirmDeposit({
    required String otp, // Changed parameter name
    required double amount,
    required String accountId,
  }) {

    if (otp == mockOtp && amount > 0) {

      return Future.delayed(_mockLatency, () => FdConfirmationResponse(
        success: true,
        message: 'Fixed Deposit of ₹${amount.toStringAsFixed(2)} successfully created!',
        transactionId: mockTransactionIdFd,
      ));
    } else if (otp != mockOtp) {
      // Simulate OTP failure
      return Future.delayed(_mockLatency, () => FdConfirmationResponse(
        success: false,
        message: 'Invalid OTP. Please try again.',
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
        paymentHistory: null,
      );
      return Future.delayed(_mockLatency, () => receipt);
    }


    return Future.error('Receipt not found for transaction ID: $transactionId');
  }
}