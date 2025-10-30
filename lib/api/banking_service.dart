import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math';

// Enum to define different types of transfers
enum TransferType { imps, neft, rtgs }
enum TransactionType { debit, credit }

/// User details model.
class UserProfile {
  final String fullName;
  final String userId;
  final DateTime lastLogin;
  UserProfile({required this.fullName, required this.userId, required this.lastLogin});
}

/// Account model for balance and type.
class Account {
  final String accountNumber;
  final String accountType;
  final double balance;
  final String nickname;
  Account({
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    required this.nickname,
  });

  // Helper method for creating a new Account instance with a new balance (Immutability)
  Account copyWith({required double newBalance}) {
    return Account(
      accountNumber: accountNumber,
      accountType: accountType,
      balance: newBalance,
      nickname: nickname,
    );
  }
}

/// Transaction model for history.
class Transaction {
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  Transaction({
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
  });
}

// ----------------------------------------------------------------------
// Mock Banking Service Implementation
// ----------------------------------------------------------------------

/// A mock service to simulate banking operations.
class BankingService {
  // --- SINGLETON SETUP ---
  static final BankingService _instance = BankingService._internal();

  /// Factory constructor to ensure only one instance of BankingService is created.
  factory BankingService() {
    return _instance;
  }

  // Private constructor
  BankingService._internal();

  // --- STATE MANAGEMENT: T-PIN, OTP, AND BALANCE ---
  String? _currentTPIN; // Set to null initially
  String? _mockOtp; // For OTP storage
  static const String _registeredMobileNumber = '9876541234';
  String _targetMobileForReset = '';

  // Mock Data definitions
  final UserProfile _userProfile = UserProfile(
    fullName: 'Arjun Reddy',
    userId: 'ARJUN12345',
    lastLogin: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
  );

  Account _primaryAccount = Account(
    accountNumber: '123456789012',
    accountType: 'Savings Account',
    balance: 55678.50,
    nickname: 'My Primary Account',
  );

  final List<Transaction> _mockTransactions = [
    Transaction(description: 'Groceries at SuperMart', amount: 1250.00, date: DateTime.now().subtract(const Duration(hours: 1)), type: TransactionType.debit),
    Transaction(description: 'Salary Credit - Oct 25', amount: 45000.00, date: DateTime.now().subtract(const Duration(days: 2)), type: TransactionType.credit),
    Transaction(description: 'Electricity Bill Payment', amount: 3500.00, date: DateTime.now().subtract(const Duration(days: 5)), type: TransactionType.debit),
    Transaction(description: 'Online Purchase - Amazon', amount: 780.00, date: DateTime.now().subtract(const Duration(days: 6)), type: TransactionType.debit),
    Transaction(description: 'ATM Withdrawal', amount: 10000.00, date: DateTime.now().subtract(const Duration(days: 10)), type: TransactionType.debit),
  ];

  // --- REAL-TIME DATA NOTIFICATION ---

  // StreamController to broadcast changes to any listener (e.g., dashboard).
  // Emits a signal (void) when critical data changes.
  final _updateController = StreamController<void>.broadcast();

  /// A stream that emits an event whenever the core banking data (balance, transactions, T-PIN status) changes.
  Stream<void> get onDataUpdate => _updateController.stream;

  /// Private helper to notify all listeners that data has been updated.
  void _notifyListeners() {
    if (!_updateController.isClosed) {
      _updateController.sink.add(null);
    }
  }

  /// Disposes of the StreamController to prevent memory leaks.
  void dispose() {
    _updateController.close();
  }


  // --- GETTERS ---
  bool get isTpinSet => _currentTPIN != null;
  String? get currentTpin => _currentTPIN;


  // --- NEW: RECIPIENT LOOKUP METHOD ---

  /// Simulates looking up a recipient's details using account number and IFS code.
  Future<Map<String, String>> lookupRecipient({
    required String recipientAccount,
    required String ifsCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000)); // Simulate API delay

    // --- MOCK LOGIC ---
    const String mockAccount = '987654321098';
    const String mockIfs = 'HDFC0000053';

    if (recipientAccount == mockAccount && ifsCode.toUpperCase() == mockIfs) {
      return {
        'officialName': 'Jane Doe',
        'bankName': 'HDFC Bank',
      };
    }

    if (recipientAccount == '111111111111') {
      throw Exception('Account not found. Please check the account number.');
    }

    // General failure
    throw Exception('Verification failed. Check account number and IFS code.');
  }


  // --- T-PIN SECURITY METHODS ---

  /// Simulates checking if a mobile number is linked to an account for T-PIN reset.
  bool findAccountByMobileNumber(String mobileNumber) {
    final exists = mobileNumber == _registeredMobileNumber;

    if (exists) {
      _targetMobileForReset = mobileNumber;
    } else {
      _targetMobileForReset = '';
    }
    return exists;
  }

  /// Returns the masked mobile number for display during the reset process.
  String getMaskedMobileNumber() {
    if (_targetMobileForReset.isEmpty) return '******0000';
    final String fullNumber = _targetMobileForReset;
    return '******' + fullNumber.substring(fullNumber.length - 4);
  }

  /// Simulates sending an OTP to the verified mobile number.
  Future<String> requestTpinOtp() async {
    if (_targetMobileForReset.isEmpty) {
      throw 'Mobile number not verified. Cannot send OTP.';
    }

    await Future.delayed(const Duration(seconds: 2));
    // Generates a mock 6-digit OTP
    final otp = (100000 + Random().nextInt(900000)).toString();
    _mockOtp = otp;
    debugPrint('MOCK OTP GENERATED: $_mockOtp for $_targetMobileForReset');
    return otp;
  }

  /// Simulates validating the received OTP.
  Future<void> validateTpinOtp(String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp == _mockOtp && otp.length == 6) {
      _mockOtp = null;
      return;
    } else {
      throw 'Invalid or expired OTP. Please request a new one.';
    }
  }

  /// Sets or resets the transaction pin.
  /// If T-PIN is already set, the oldPin must be provided for security.
  /// If T-PIN is being set for the first time or is part of a post-OTP reset flow, oldPin can be null.
  Future<String> updateTransactionPin({
    required String newPin,
    String? oldPin,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // Validation for existing T-PIN change
    if (isTpinSet && oldPin != null) {
      if (oldPin != _currentTPIN) {
        throw 'Current T-PIN is incorrect. Authorization failed.';
      }
    } else if (isTpinSet && oldPin == null) {
      // Allow this only if we are in the OTP reset flow (i.e., _targetMobileForReset is set)
      if (_targetMobileForReset.isEmpty) {
        throw 'Current T-PIN must be provided to change the PIN.';
      }
    }

    // New PIN format validation
    if (newPin.length != 6 || !RegExp(r'^\d+$').hasMatch(newPin)) {
      throw 'Invalid PIN format. New T-PIN must be exactly 6 numeric digits.';
    }

    _currentTPIN = newPin;
    _targetMobileForReset = ''; // Clear reset flow state
    debugPrint('T-PIN updated to: $_currentTPIN');

    // Notify listeners when T-PIN status changes (crucial for dashboard updates)
    _notifyListeners();

    return 'T-PIN set successfully!';
  }

  Future<UserProfile> fetchUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _userProfile;
  }

  Future<Account> fetchAccountSummary() async {
    // Returns the current internal state after mock delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _primaryAccount;
  }

  /// Fetches the last 5 transactions (Mini Statement).
  Future<List<Transaction>> fetchMiniStatement() async {
    // Returns the first 5 transactions, sorted by date (most recent first, implicitly by insert order)
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockTransactions.take(5).toList();
  }

  /// Fetches all transactions for the full history screen.
  Future<List<Transaction>> fetchAllTransactions() async {
    await Future.delayed(const Duration(milliseconds: 800));
    // In a real app, this would call a paginated API endpoint.
    return _mockTransactions;
  }

  /// Simulates a fund transfer and updates the account balance and transaction history.
  Future<String> submitFundTransfer({
    required String recipientAccount,
    required String recipientName,
    required String ifsCode,
    required TransferType transferType,
    required double amount,
    String? narration,
    required String transactionPin,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // 1. T-PIN VALIDATION
    if (_currentTPIN == null) {
      throw 'Transaction failed: T-PIN is not set. Please set your T-PIN first.';
    }
    if (transactionPin != _currentTPIN) {
      throw 'Transaction failed: Invalid Transaction PIN.';
    }

    // 2. Mock Security and Logic Checks
    if (amount <= 0) {
      throw 'Transaction failed: Amount must be greater than zero.';
    }
    if (amount > _primaryAccount.balance) {
      throw 'Insufficient funds. Current balance: ₹${_primaryAccount.balance.toStringAsFixed(2)}';
    }

    // 3. Mock Transaction Processing (Debit and New Balance)
    double newBalance = _primaryAccount.balance - amount;

    // Use the copyWith helper to create a new immutable Account object
    _primaryAccount = _primaryAccount.copyWith(newBalance: newBalance);

    // 4. Mock Transaction Logging (Add to Mini Statement)
    final newTransaction = Transaction(
      description: narration ?? 'Fund Transfer to $recipientName',
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.debit,
    );
    // Add to the start of the list so it appears first in the mini statement
    _mockTransactions.insert(0, newTransaction);


    // Notify listeners when account balance or transaction history changes
    _notifyListeners();

    return 'Success! ₹${amount.toStringAsFixed(2)} transferred via ${transferType.name.toUpperCase()}. Transaction ID: ${Random().nextInt(99999999)}';
  }

  Future<void> setTransactionPin({required String oldPin, required String newPin}) async {}
}
