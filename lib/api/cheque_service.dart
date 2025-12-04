// Path: lib/api/cheque_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';

// --- Definitions from provided context ---

enum AccountType { savings, current, fixedDeposit, recurringDeposit }

class Account {
  final String accountNo;
  final String accountName;
  final AccountType accountType;
  final double balance;

  Account({required this.accountNo, required this.accountName, required this.accountType, required this.balance});
}

// --- ChequeService Implementation ---

class ChequeService {
  // --- MOCK STATE: Tracks request history for 'First-Time Free' logic ---
  static final Map<String, int> _chequeBookRequestCount = {
    '67401234': 0, // Savings (Primary) - FREE
    '34995678': 1, // Current (Business) - CHARGED
    '90004321': 2, // Savings (Joint) - CHARGED
  };
  // ---------------------------------------------------------------------

  final List<Account> mockAllAccounts = [
    Account(accountNo: '67401234', accountName: 'Savings (Primary)', accountType: AccountType.savings, balance: 50000.50),
    Account(accountNo: '34995678', accountName: 'Current (Business)', accountType: AccountType.current, balance: 125000.00),
    Account(accountNo: '90004321', accountName: 'Savings (Joint)', accountType: AccountType.savings, balance: 10000.00),
    Account(accountNo: '88881111', accountName: 'Fixed Deposit (Retirement)', accountType: AccountType.fixedDeposit, balance: 250000.00),
  ];

  final List<int> mockBookLeaves = [25, 50, 100];
  final List<String> mockDeliveryAddresses = [
    'Registered Address: 123 Corporate Park, Mumbai - 400001',
    'Branch Pickup: Central Branch (MH001)',
  ];
  final List<String> mockReasons = ['New Account Request', 'Current Book Exhausted', 'Book Damaged/Lost', 'Other'];
  static const int maxCurrentAccountBooks = 3;

  // --- MOCK DATA for STOP CHEQUE ---
  final List<String> mockStopReasons = [
    'Cheque Lost/Stolen',
    'Payment Dispute',
    'Incorrect Payee/Amount',
    'Post-Dated Cheque',
    'Other',
  ];

  // Fee calculation for Stop Cheque (simplified mock)
  static const double kStopChequeFee = 50.0; // Flat fee per cheque stopped (mock)
  static const double kStopChequeGST = 0.18; // 18% GST (mock)

  // ---------------------------------------------------------------------
  // I. FEE CALCULATION METHODS
  // ---------------------------------------------------------------------

  /// Checks if this is the account's first request for a cheque book.
  bool isFirstRequest(String accountNo) {
    return (_chequeBookRequestCount[accountNo] ?? 0) == 0;
  }

  /// Calculates the total fee for a Cheque Book Request.
  double getFee({required String accountNo, required int leaves, required int quantity}) {
    if (isFirstRequest(accountNo)) {
      return 0.0; // FREE for the first request
    }

    final double baseFee;
    if (leaves == 25) baseFee = 100.0;
    else if (leaves == 50) baseFee = 150.0;
    else baseFee = 200.0;

    // Fee = Base Fee * Quantity * (1 + GST)
    return (baseFee * quantity) * 1.18; // 18% GST mock
  }

  /// Calculates the total fee for a Stop Cheque Request based on the count of cheques.
  double getStopChequeFee(int count) {
    // Fee = (Base Fee * Count) * (1 + GST)
    return (kStopChequeFee * count) * (1 + kStopChequeGST);
  }

  // ---------------------------------------------------------------------
  // II. DATA FETCH METHODS
  // ---------------------------------------------------------------------

  /// Fetches accounts eligible for cheque services (Savings and Current).
  Future<List<Account>> fetchEligibleAccounts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Only Savings and Current accounts are eligible for cheque services
    return mockAllAccounts.where((acc) =>
    acc.accountType == AccountType.savings ||
        acc.accountType == AccountType.current
    ).toList();
  }

  // ---------------------------------------------------------------------
  // III. AUTHORIZATION & SUBMISSION METHODS
  // ---------------------------------------------------------------------

  /// REUSABLE T-Pin Verification Service Method
  /// This method centralizes the T-Pin API call logic.
  Future<bool> verifyTpin(String tpin) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Mock successful verification only if T-Pin is "123456"
    // In a real app, this would call a secure backend API.
    return tpin == '123456';
  }

  /// Submits a request for a new Cheque Book. (Code omitted for brevity, focusing on Stop Cheque)
  Future<String> submitChequeBookRequest({
    required String accountNo,
    required int leaves,
    required int quantity,
    required String deliveryAddress,
    String? reason,
  }) async {
    // ... existing implementation ...
    await Future.delayed(const Duration(seconds: 2));

    final Account selectedAccount = mockAllAccounts.firstWhere(
          (acc) => acc.accountNo == accountNo,
      orElse: () => throw Exception('Selected account not found.'),
    );

    // Enforce quantity policy
    if (selectedAccount.accountType == AccountType.savings && quantity > 1) {
      throw Exception('Savings accounts are restricted to one cheque book request at a time.');
    }
    if (selectedAccount.accountType == AccountType.current && quantity > maxCurrentAccountBooks) {
      throw Exception('Current accounts are restricted to a maximum of $maxCurrentAccountBooks books per request.');
    }

    // Check for fee and balance
    final double totalFee = getFee(accountNo: accountNo, leaves: leaves, quantity: quantity);

    if (totalFee > 0 && selectedAccount.balance < totalFee) {
      throw Exception('Insufficient funds. Total Fee (Incl. GST): ₹${totalFee.toStringAsFixed(2)}');
    }

    _chequeBookRequestCount[accountNo] = (_chequeBookRequestCount[accountNo] ?? 0) + 1;

    final String referenceId = 'CBREQ${DateTime.now().millisecondsSinceEpoch % 100000}';
    return referenceId;
  }


  /// Submits a request to stop payment on one or more cheques.
  Future<String> submitStopChequeRequest({
    required String accountNo,
    required List<String> chequeNumbers,
    required String reason,
    double? amount, // Optional: for verification
    String? payeeName, // Optional: for verification
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    if (chequeNumbers.isEmpty) {
      throw Exception('At least one cheque number must be provided.');
    }

    final Account selectedAccount = mockAllAccounts.firstWhere(
          (acc) => acc.accountNo == accountNo,
      orElse: () => throw Exception('Selected account not found.'),
    );

    // Calculate fee and check balance (Final check before debit)
    final double totalFee = getStopChequeFee(chequeNumbers.length);

    if (selectedAccount.balance < totalFee) {
      throw Exception('Insufficient funds. Total Fee (Incl. GST): ₹${totalFee.toStringAsFixed(2)}');
    }

    // Mock Business Logic/Validation: Ensure cheque numbers are in a reasonable format
    for (var number in chequeNumbers) {
      if (number.length != 6 || int.tryParse(number) == null) {
        throw Exception('Invalid cheque number format: $number. Please enter a 6-digit number.');
      }
    }

    // Success response
    final String referenceId = 'SCREQ${DateTime.now().millisecondsSinceEpoch % 100000}';
    return referenceId;
  }
}