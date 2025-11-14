import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math';

// Enum to define different types of transfers
enum TransferType { imps, neft, rtgs, internal }
enum TransactionType { debit, credit }
enum AccountType { savings, current, fixedDeposit, recurringDeposit }

/// Custom Exception for banking errors
class TransferException implements Exception {
  final String message;
  final String code;

  TransferException(this.message, {this.code = 'TRANSACTION_FAILED'});

  @override
  String toString() => 'TransferException: $message (Code: $code)';
}

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
  final AccountType accountType;
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

/// Beneficiary (Payee) model.
class Beneficiary {
  final String beneficiaryId; // Unique ID
  final String name;
  final String accountNumber;
  final String ifsCode;
  final String bankName;
  final String nickname;

  Beneficiary({
    required this.beneficiaryId,
    required this.name,
    required this.accountNumber,
    required this.ifsCode,
    required this.bankName,
    required this.nickname,
  });

  // For updating individual fields (e.g., nickname)
  Beneficiary copyWith({
    String? name,
    String? accountNumber,
    String? ifsCode,
    String? bankName,
    String? nickname,
  }) {
    return Beneficiary(
      beneficiaryId: this.beneficiaryId,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsCode: ifsCode ?? this.ifsCode,
      bankName: bankName ?? this.bankName,
      nickname: nickname ?? this.nickname,
    );
  }
}

// --- DATA MODEL: ADD BENEFICIARY PAYLOAD ---
class AddBeneficiaryPayload {
  final String name;
  final String accountNumber;
  final String ifsCode;
  final String bankName;
  final String nickname;

  AddBeneficiaryPayload({
    required this.name,
    required this.accountNumber,
    required this.ifsCode,
    required this.bankName,
    required this.nickname,
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

  // --- MOCK CONSTANTS ---
  static const String _mockBankIfscPrefix = 'CABK'; // CA Bank Mock IFSC prefix
  static const double _impsFeeRate = 0.005;
  static const double _neftFeeFixed = 5.0;
  static const double _rtgsFeeMin = 25.0;
  static const double _dailyTransferLimit = 200000.00;
  double _todayTransferredAmount = 15000.00;
  static const int _tpinLength = 6;
  static const String _registeredMobileNumber = '9876541234';

  // --- STATE MANAGEMENT: T-PIN, OTP, AND ACCOUNT DATA ---
  String? _currentTPIN;
  String? _mockOtp;
  String _targetMobileForReset = '';

  // Private constructor
  BankingService._internal() {
    // Initialize T-PIN and ensure it meets the required length
    _currentTPIN = '456789';
    if (_currentTPIN?.length != _tpinLength) {
      if (kDebugMode) {
        print('WARNING: Mock T-PIN does not meet the required length ($_tpinLength). Setting to null.');
      }
      _currentTPIN = null;
    }
  }

  // Mock Data definitions
  final UserProfile _userProfile = UserProfile(
    fullName: 'Arjun Reddy',
    userId: 'ARJUN12345',
    lastLogin: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
  );

  final List<Account> _mockUserAccounts = [
    Account(accountNumber: '123456789012', accountType: AccountType.savings, balance: 55678.50, nickname: 'My Primary Account'),
    Account(accountNumber: '987654321098', accountType: AccountType.current, balance: 152000.00, nickname: 'Business Current'),
    Account(accountNumber: '555544443333', accountType: AccountType.fixedDeposit, balance: 300000.00, nickname: 'Emergency Fund'),
  ];


  final List<Transaction> _mockTransactions = [
    Transaction(description: 'Groceries at SuperMart', amount: 1250.00, date: DateTime.now().subtract(const Duration(hours: 1)), type: TransactionType.debit),
    Transaction(description: 'Salary Credit - Oct 25', amount: 45000.00, date: DateTime.now().subtract(const Duration(days: 2)), type: TransactionType.credit),
    Transaction(description: 'Electricity Bill Payment', amount: 3500.00, date: DateTime.now().subtract(const Duration(days: 5)), type: TransactionType.debit),
    Transaction(description: 'Online Purchase - Amazon', amount: 780.00, date: DateTime.now().subtract(const Duration(days: 6)), type: TransactionType.debit),
    Transaction(description: 'ATM Withdrawal', amount: 10000.00, date: DateTime.now().subtract(const Duration(days: 10)), type: TransactionType.debit),
  ];

  final List<Beneficiary> _mockBeneficiaries = [
    Beneficiary(
      beneficiaryId: 'BENF1',
      name: 'Jane Doe',
      accountNumber: '987654321098',
      ifsCode: 'HDFC0000053',
      bankName: 'HDFC Bank',
      nickname: 'Jane (Rent)',
    ),
    Beneficiary(
      beneficiaryId: 'BENF2',
      name: 'Utility Company',
      accountNumber: '102938475610',
      ifsCode: 'ICIC0001234',
      bankName: 'ICICI Bank',
      nickname: 'Electricity Bill',
    ),
    Beneficiary(
      beneficiaryId: 'BENF3',
      name: 'Internal Payee',
      accountNumber: '246813579024',
      ifsCode: '${_mockBankIfscPrefix}0000055', // IFSC that matches our mock bank prefix
      bankName: 'CA Bank',
      nickname: 'Internal Transfer Test',
    ),
  ];

  // --- REAL-TIME DATA NOTIFICATION ---
  final _updateController = StreamController<void>.broadcast();
  Stream<void> get onDataUpdate => _updateController.stream;

  void _notifyListeners() {
    if (!_updateController.isClosed) {
      _updateController.sink.add(null);
    }
  }

  /// Closes the internal stream controller. Should be called when the service is no longer needed.
  void dispose() {
    _updateController.close();
  }


  // --- GETTERS ---
  bool get isTpinSet => _currentTPIN != null && _currentTPIN!.length == _tpinLength;
  String? get currentTpin => _currentTPIN;


  // --- ACCOUNT MASKING UTILITY (Crucial for display) ---
  /// Masks the account number, showing only the last 4 digits.
  String maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) {
      return '**** $accountNumber';
    }
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    final maskedPart = '*' * (accountNumber.length - 4);
    return maskedPart + lastFour;
  }

  // --- IFSC HELPER (NEWLY ADDED) ---
  /// Checks if the given IFSC code belongs to this bank.
  bool isInternalIfsc(String ifsCode) {
    return ifsCode.toUpperCase().startsWith(_mockBankIfscPrefix);
  }

  // Method to fetch all accounts (needed by the fund transfer menu)
  Future<List<Account>> fetchUserAccounts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockUserAccounts);
  }

  /// Fetches the user's primary account, typically the first one in the list.
  Future<Account> fetchPrimaryAccount() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_mockUserAccounts.isEmpty) {
      throw Exception('No accounts found for the user.');
    }
    // Assume the first account is the primary account
    return _mockUserAccounts.first;
  }

  // --- ACCOUNT FILTERING HELPERS FOR UI (NEWLY ADDED) ---

  /// Filters accounts that are eligible to be debited (used for the Source account selection
  /// for BOTH internal and external transfers). Excludes FD/RD.
  Future<List<Account>> fetchDebitAccounts() async {
    // Simulates a quick API call to get the list of debitable accounts
    await Future.delayed(const Duration(milliseconds: 300));

    // Logic: Ensure only Savings and Current accounts are available to debit from.
    return _mockUserAccounts.where((acc) =>
    acc.accountType != AccountType.fixedDeposit &&
        acc.accountType != AccountType.recurringDeposit
    ).toList();
  }

  /// Filters accounts eligible to be credited, specifically for OWN ACCOUNT TRANSFERS,
  /// excluding the current source account number.
  List<Account> filterDestinationAccounts(String sourceAccountNumber) {
    // Logic: All linked accounts are creditable, but we must exclude the source account.
    return _mockUserAccounts.where((acc) =>
    acc.accountNumber != sourceAccountNumber
    ).toList();
  }

  // --------------------------------------------------------


  // --- NEW: Transfer Rules Data (REQUIRED FOR UI) ---
  Map<TransferType, String> getTransferTypeRules() {
    return {
      TransferType.imps: "Immediate payment service. Available 24/7/365. Instant transfer (usually within seconds). Limit per transaction: ₹2,00,000.",
      TransferType.neft: "National Electronic Fund Transfer. Available 24/7/365. Transactions are processed in batches (hourly/half-hourly). No minimum/maximum limit.",
      TransferType.rtgs: "Real-Time Gross Settlement. Used for high-value transfers. Minimum transfer is ₹2,00,000. Available 24/7/365.",
      TransferType.internal: "Instantaneous transfer between accounts within the same bank. No fees and no cooling period.",
    };
  }

  // --- BENEFICIARY MANAGEMENT METHODS (UPDATED) ---

  /// Simulates the initial GET call to fetch existing payees.
  Future<List<Beneficiary>> fetchBeneficiaries() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return List.from(_mockBeneficiaries);
  }

  /// Simulates the POST call to save a new payee to the list.
  Future<Beneficiary> addBeneficiary({
    required String name,
    required String accountNumber,
    required String ifsCode,
    required String bankName,
    required String nickname,
    AddBeneficiaryPayload? payload,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // Check if the beneficiary already exists (case-insensitive)
    if (_mockBeneficiaries.any((b) => b.accountNumber == accountNumber)) {
      throw TransferException('Beneficiary with this account number already exists.');
    }

    final newBeneficiary = Beneficiary(
      beneficiaryId: 'BENF${Random().nextInt(10000)}',
      name: name,
      accountNumber: accountNumber,
      ifsCode: ifsCode,
      bankName: bankName,
      nickname: nickname,
    );

    _mockBeneficiaries.add(newBeneficiary);
    _notifyListeners();
    return newBeneficiary;
  }

  /// Deletes a beneficiary by their unique ID.
  Future<void> deleteBeneficiary(String beneficiaryId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final initialLength = _mockBeneficiaries.length;
    _mockBeneficiaries.removeWhere((b) => b.beneficiaryId == beneficiaryId);

    if (_mockBeneficiaries.length == initialLength) {
      throw TransferException('Beneficiary not found for deletion.');
    }
    _notifyListeners();
  }

  /// Updates a beneficiary using a full Beneficiary object.
  Future<Beneficiary> updateBeneficiary(Beneficiary updatedBeneficiary) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockBeneficiaries.indexWhere((b) => b.beneficiaryId == updatedBeneficiary.beneficiaryId);

    if (index == -1) {
      throw TransferException('Beneficiary not found for update.');
    }

    _mockBeneficiaries[index] = updatedBeneficiary;
    _notifyListeners();
    return updatedBeneficiary;
  }

  // --- OTHER BANKING METHODS ---

  /// Simulates looking up a recipient's details (external verification).
  Future<Map<String, String>> lookupRecipient({
    required String recipientAccount,
    required String ifsCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // MOCK LOGIC: These are the dummy inputs that guarantee a success response
    if (recipientAccount == '987654321098' && ifsCode.toUpperCase() == 'HDFC0000053') {
      return {
        'officialName': 'Jane Doe',
        'bankName': 'HDFC Bank',
      };
    }
    if (recipientAccount == '555544443333' && ifsCode.toUpperCase() == 'SBIN0000001') {
      return {
        'officialName': 'New Test Payee',
        'bankName': 'State Bank of India',
      };
    }
    if (recipientAccount.startsWith('11111111')) {
      throw TransferException('Account not found. Please check the account number.');
    }

    // Success case for internal IFSC match
    if (isInternalIfsc(ifsCode) && recipientAccount.startsWith('24681357')) {
      return {
        'officialName': 'Internal Payee',
        'bankName': 'CA Bank',
      };
    }

    // General failure
    throw TransferException('Verification failed. Check account number and IFS code.');
  }


  // --- T-PIN SECURITY METHODS (Updated for 6 digits) ---
  bool findAccountByMobileNumber(String mobileNumber) {
    final exists = mobileNumber == _registeredMobileNumber;

    if (exists) {
      _targetMobileForReset = mobileNumber;
    } else {
      _targetMobileForReset = '';
    }
    return exists;
  }

  String getMaskedMobileNumber() {
    if (_targetMobileForReset.isEmpty) return '******0000';
    final String fullNumber = _targetMobileForReset;
    return '******' + fullNumber.substring(fullNumber.length - 4);
  }

  Future<String> requestTpinOtp() async {
    if (_targetMobileForReset.isEmpty) {
      throw TransferException('Mobile number not verified. Cannot send OTP.');
    }

    await Future.delayed(const Duration(seconds: 2));
    final otp = (100000 + Random().nextInt(900000)).toString();
    _mockOtp = otp;
    if (kDebugMode) {
      print('MOCK OTP GENERATED: $_mockOtp for $_targetMobileForReset');
    }
    return otp;
  }

  Future<void> validateTpinOtp(String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp == _mockOtp && otp.length == 6) {
      _mockOtp = null;
      return;
    } else {
      throw TransferException('Invalid or expired OTP. Please request a new one.');
    }
  }

  Future<String> updateTransactionPin({
    required String newPin,
    String? oldPin,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (isTpinSet && oldPin != null) {
      if (oldPin != _currentTPIN) {
        throw TransferException('Current T-PIN is incorrect. Authorization failed.');
      }
    } else if (isTpinSet && oldPin == null) {
      if (_targetMobileForReset.isEmpty) {
        throw TransferException('Current T-PIN must be provided to change the PIN unless a reset flow is initiated.');
      }
    }

    // Validation now uses _tpinLength = 6
    if (newPin.length != _tpinLength || !RegExp(r'^\d+$').hasMatch(newPin)) {
      throw TransferException('Invalid PIN format. New T-PIN must be exactly $_tpinLength numeric digits.');
    }

    _currentTPIN = newPin;
    _targetMobileForReset = '';
    if (kDebugMode) {
      print('T-PIN updated to: $_currentTPIN');
    }

    _notifyListeners();

    return 'T-PIN set successfully!';
  }

  Future<bool> validateTpin(String tpin) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Validation now uses _tpinLength = 6 implicitly via _currentTPIN length
    return isTpinSet && tpin == _currentTPIN;
  }

  Future<void> setTransactionPin({required String oldPin, required String newPin}) async {
    await updateTransactionPin(newPin: newPin, oldPin: oldPin);
  }

  Future<UserProfile> fetchUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _userProfile;
  }

  Future<Account> fetchAccountSummary() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockUserAccounts.first;
  }

  Future<List<Transaction>> fetchMiniStatement() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockTransactions.take(5).toList();
  }

  Future<List<Transaction>> fetchAllTransactions() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockTransactions;
  }

  // --- FEE CALCULATION AND DETAILS (Unchanged) ---
  double _calculateFee(TransferType type, double amount) {
    if (type == TransferType.internal) return 0.0;

    switch (type) {
      case TransferType.imps:
        return min(amount * _impsFeeRate, 50.0);
      case TransferType.neft:
        return _neftFeeFixed;
      case TransferType.rtgs:
        if (amount < 200000.0) {
          throw TransferException('RTGS minimum transfer amount is ₹2,00,000.00.');
        }
        return _rtgsFeeMin;
      case TransferType.internal:
        return 0.0;
    }
  }

  Future<Map<String, double>> calculateTransferDetails({
    required TransferType transferType,
    required double amount,
    required String sourceAccountNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final sourceIndex = _mockUserAccounts.indexWhere((acc) => acc.accountNumber == sourceAccountNumber);
    if (sourceIndex == -1) {
      throw TransferException('Source account not found.');
    }
    final sourceAccount = _mockUserAccounts[sourceIndex];

    double fee = 0.0;
    try {
      fee = _calculateFee(transferType, amount);
    } catch (e) {
      rethrow;
    }

    final totalDebit = amount + fee;
    final availableDailyLimit = _dailyTransferLimit - _todayTransferredAmount;

    if (amount > availableDailyLimit) {
      throw TransferException('Transaction exceeds daily transfer limit. Available: ₹${availableDailyLimit.toStringAsFixed(2)}');
    }

    if (totalDebit > sourceAccount.balance) {
      throw TransferException('Insufficient funds. Required: ₹${totalDebit.toStringAsFixed(2)}');
    }

    return {
      'fee': fee,
      'totalDebit': totalDebit,
      'availableDailyLimit': availableDailyLimit,
    };
  }

  // --- FUND TRANSFER IMPLEMENTATION (UPDATED FOR OWN ACCOUNT CHECKS) ---
  Future<String> _performInternalTransfer({
    required double amount,
    required String narration,
    required Account sourceAccount,
    required String recipientAccount,
    required int sourceIndex,
  }) async {
    // 1. BANKING RULE: Check for self-transfer
    if (sourceAccount.accountNumber == recipientAccount) {
      throw TransferException('Transaction failed: Cannot transfer funds to the same source account.');
    }

    // 2. BANKING RULE: Prevent debit from deposit accounts (FD/RD)
    if (sourceAccount.accountType == AccountType.fixedDeposit ||
        sourceAccount.accountType == AccountType.recurringDeposit) {
      throw TransferException(
        'Transaction failed: Cannot directly debit funds from a ${sourceAccount.accountType.name}. Please use the "Close/Break Deposit" option.',
        code: 'DEPOSIT_DEBIT_BLOCKED',
      );
    }

    final destinationIndex = _mockUserAccounts.indexWhere((acc) => acc.accountNumber == recipientAccount);
    final destinationAccount = destinationIndex != -1 ? _mockUserAccounts[destinationIndex] : null;

    if (destinationAccount == null) {
      throw TransferException('Transaction failed: Destination own account not found in system.');
    }

    // 3. FINAL CHECK: Insufficient Funds (Redundant with submitFundTransfer but safer here)
    if (amount > sourceAccount.balance) {
      throw TransferException('Transaction failed: Insufficient funds for transfer.');
    }

    // --- LEDGER UPDATE (Simulated Atomic Commit) ---
    final newSourceBalance = sourceAccount.balance - amount;
    _mockUserAccounts[sourceIndex] = sourceAccount.copyWith(newBalance: newSourceBalance);

    final newDestinationBalance = destinationAccount.balance + amount;
    _mockUserAccounts[destinationIndex] = destinationAccount.copyWith(newBalance: newDestinationBalance);

    final newTransaction = Transaction(
      description: narration.isNotEmpty ? narration : 'Internal Transfer to ${destinationAccount.nickname}',
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.debit,
    );
    _mockTransactions.insert(0, newTransaction);

    _notifyListeners();

    return 'Success! Own Account Transfer of ₹${amount.toStringAsFixed(2)} completed instantly. Transaction ID: ${Random().nextInt(99999999)}';
  }

  Future<String> _performExternalTransfer({
    required TransferType transferType,
    required double amount,
    required double fee,
    required double totalDebitAmount,
    required String recipientName,
    required String narration,
    required Account sourceAccount,
    required int sourceIndex,
  }) async {
    final newBalance = sourceAccount.balance - totalDebitAmount;
    _mockUserAccounts[sourceIndex] = sourceAccount.copyWith(newBalance: newBalance);

    _todayTransferredAmount += amount;

    final transactionDescription = 'Fund Transfer (${transferType.name.toUpperCase()}) to $recipientName (+ Fee ₹${fee.toStringAsFixed(2)})';
    final newTransaction = Transaction(
      description: narration.isNotEmpty ? narration : transactionDescription,
      amount: totalDebitAmount,
      date: DateTime.now(),
      type: TransactionType.debit,
    );
    _mockTransactions.insert(0, newTransaction);

    _notifyListeners();

    return 'Success! ₹${amount.toStringAsFixed(2)} transferred via ${transferType.name.toUpperCase()} (Fee: ₹${fee.toStringAsFixed(2)}). Transaction ID: ${Random().nextInt(99999999)}';
  }

  Future<String> submitFundTransfer({
    required String recipientAccount,
    required String recipientName,
    String? ifsCode,
    required TransferType transferType,
    required double amount,
    String? narration,
    required String transactionPin,
    required String sourceAccountNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final sourceIndex = _mockUserAccounts.indexWhere((acc) => acc.accountNumber == sourceAccountNumber);
    final sourceAccount = sourceIndex != -1 ? _mockUserAccounts[sourceIndex] : null;

    // --- PRE-VALIDATION ---
    if (sourceAccount == null) {
      throw TransferException('Transaction failed: Source account not found.');
    }

    if (_currentTPIN == null) {
      throw TransferException('Transaction failed: T-PIN is not set. Please set your T-PIN first.');
    }
    // This comparison now expects 6 digits
    if (transactionPin != _currentTPIN) {
      throw TransferException('Transaction failed: Invalid Transaction PIN.');
    }

    if (amount <= 0) {
      throw TransferException('Transaction failed: Amount must be greater than zero.');
    }

    double fee = 0.0;
    double totalDebitAmount = amount;

    // Only run fee/limit calculations for non-Own Account transfers
    // For Own Account transfers, we use a dedicated method that bypasses the fee/limit check
    if (transferType != TransferType.internal || !_mockUserAccounts.any((a) => a.accountNumber == recipientAccount)) {
      try {
        final details = await calculateTransferDetails(
          transferType: transferType,
          amount: amount,
          sourceAccountNumber: sourceAccountNumber,
        );
        fee = details['fee']!;
        totalDebitAmount = details['totalDebit']!;
      } on TransferException {
        rethrow;
      } catch (e) {
        // Catch generic exceptions and re-throw as TransferException
        throw TransferException(e.toString().replaceAll('Exception: ', ''));
      }
    }


    // --- EXECUTION ---
    final finalNarration = narration?.trim() ?? '';

    if (transferType == TransferType.internal || _mockUserAccounts.any((a) => a.accountNumber == recipientAccount)) {
      // NOTE: Even if the transfer is initiated from the main menu, if the destination is an on-us account, it's an internal transfer (which is why we check for both the enum and the account list)
      return _performInternalTransfer(
        amount: amount,
        narration: finalNarration,
        sourceAccount: sourceAccount,
        recipientAccount: recipientAccount,
        sourceIndex: sourceIndex,
      );
    } else {
      // For external transfers
      if (ifsCode == null || ifsCode.isEmpty) {
        throw TransferException('Transaction failed: IFS Code is required for external transfers (IMPS/NEFT/RTGS).');
      }

      return _performExternalTransfer(
        transferType: transferType,
        amount: amount,
        fee: fee,
        totalDebitAmount: totalDebitAmount,
        recipientName: recipientName, // Using the passed recipientName
        narration: finalNarration,
        sourceAccount: sourceAccount,
        sourceIndex: sourceIndex,
      );
    }
  }
}