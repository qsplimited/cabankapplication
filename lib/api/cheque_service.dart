import 'dart:async';
import 'package:flutter/foundation.dart';
// Note: Assuming AccountType is defined/imported from banking_service.dart

enum AccountType { savings, current, fixedDeposit, recurringDeposit }

class Account {
  final String accountNo;
  final String accountName;
  final AccountType accountType;
  final double balance;

  Account({required this.accountNo, required this.accountName, required this.accountType, required this.balance});
}

class ChequeService {
  // --- MOCK STATE: Tracks request history for 'First-Time Free' logic ---
  // 0 = First request (FREE). 1+ = Subsequent requests (CHARGED).
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

  // Checks if this is the account's first request
  bool isFirstRequest(String accountNo) {
    return (_chequeBookRequestCount[accountNo] ?? 0) == 0;
  }

  // --- CORE CHANGE: Dynamic Fee Calculation (First Time Free) ---
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
  // -------------------------------------------------------------

  Future<List<Account>> fetchEligibleAccounts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return mockAllAccounts.where((acc) =>
    acc.accountType == AccountType.savings ||
        acc.accountType == AccountType.current
    ).toList();
  }

  Future<String> submitChequeBookRequest({
    required String accountNo,
    required int leaves,
    required int quantity,
    required String deliveryAddress,
    String? reason,
  }) async {
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

    // --- CRITICAL: Update mock state on successful submission ---
    _chequeBookRequestCount[accountNo] = (_chequeBookRequestCount[accountNo] ?? 0) + 1;
    // -----------------------------------------------------------

    final String referenceId = 'CBREQ${DateTime.now().millisecondsSinceEpoch % 100000}';
    return referenceId;
  }
}