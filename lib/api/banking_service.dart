import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:math';

// import 'i_device_service.dart'; // Assuming this is defined elsewhere
// import 'mock_device_service.dart'; // Assuming this is defined elsewhere

// --- DUMMY IMPORTS FOR STANDALONE CODE ---
abstract class IDeviceService {}
class MockDeviceService implements IDeviceService {}
// ------------------------------------------

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

// --- UPDATED DATA MODEL: Nominee ---
class Nominee {
  final String name;
  final String relationship;
  final DateTime dateOfBirth;

  Nominee({
    required this.name,
    required this.relationship,
    required this.dateOfBirth,
  });
}
// -------------------------------------

/// User details model.
class UserProfile {
  final String fullName;
  final String userId;
  final DateTime lastLogin;
  UserProfile({required this.fullName, required this.userId, required this.lastLogin});
}

/// Account model for balance and type (UPDATED with detailed fields).
class Account {
  final String accountNumber;
  final AccountType accountType;
  final double balance;
  final String nickname;
  final String accountId;

  // --- NEW FIELDS ADDED FOR DETAIL SCREEN ---
  final double availableBalance;
  final String ifscCode;
  final String branchAddress;
  final Nominee nominee;
  // ------------------------------------------

  Account({
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    required this.nickname,
    required this.accountId,
    required this.availableBalance, // NEW
    required this.ifscCode, // NEW
    required this.branchAddress, // NEW
    required this.nominee, // NEW
  });

  // Helper method for creating a new Account instance with a new balance (Immutability)
  Account copyWith({required double newBalance}) {
    return Account(
      accountNumber: accountNumber,
      accountType: accountType,
      balance: newBalance,
      availableBalance: newBalance, // Update available balance too
      nickname: nickname,
      accountId: accountId,
      ifscCode: ifscCode,
      branchAddress: branchAddress,
      nominee: nominee,
    );
  }
}

/// Transaction model for history.
class Transaction {
  final String description;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String transactionId;
  final double runningBalance;
  Transaction({
    required this.description,
    required this.amount,
    required this.date,
    required this.type,
    required this.transactionId,
    required this.runningBalance,
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
    required String ifsCode, // Added required keyword for clarity
    required this.bankName,
    required this.nickname,
  }) : ifsCode = ifsCode.toUpperCase(); // Ensure IFSC is always stored uppercase

  // Helper for creating from Beneficiary model (e.g., for update forms)
  factory AddBeneficiaryPayload.fromBeneficiary(Beneficiary b) {
    return AddBeneficiaryPayload(
      name: b.name,
      accountNumber: b.accountNumber,
      ifsCode: b.ifsCode,
      bankName: b.bankName,
      nickname: b.nickname,
    );
  }
}
// ----------------------------------------------------------------------
// Mock Banking Service Implementation
// ----------------------------------------------------------------------
class BankingService {
  // --- SINGLETON SETUP ---
  static final BankingService _instance = BankingService._internal();
  final IDeviceService _deviceService;

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
  static const int _otpLength = 6;
  static const String _registeredMobileNumber = '9876541234';

  // --- STATE MANAGEMENT: T-PIN, OTP, AND ACCOUNT DATA ---
  String? _currentTPIN;
  String? _mockOtp; // Stores the generated OTP for validation
  String? _mockTransactionReference; // Stores the ref ID returned by /initiate
  DateTime? _otpGenerationTime; // Used to check OTP expiry (e.g., 5 minutes)
  String _targetMobileForReset = ''; // Used for T-PIN reset flow
  final Random _random = Random(); // Random instance for IDs and OTPs

  // Private constructor
  BankingService._internal() : _deviceService = MockDeviceService() {
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

  // --- UPDATED MOCK ACCOUNT DATA WITH DETAILED FIELDS ---
  final List<Account> _mockUserAccounts = [
    Account(
      accountId: 'ACC001',
      accountNumber: '123456789012',
      accountType: AccountType.savings,
      balance: 55678.50,
      availableBalance: 54000.00, // Example: Less than balance due to a hold
      nickname: 'Savings Account',
      ifscCode: '${_mockBankIfscPrefix}0001001', // Mock IFSC for primary branch
      branchAddress: 'CA Bank, Main Branch, HSR Layout, Bangalore',
      nominee: Nominee(
        name: 'Priya A. Reddy',
        relationship: 'Spouse',
        dateOfBirth: DateTime(1985, 10, 20),
      ),
    ),
    Account(
      accountId: 'ACC002',
      accountNumber: '987654321098',
      accountType: AccountType.current,
      balance: 152000.00,
      availableBalance: 152000.00,
      nickname: 'Current Account',
      ifscCode: '${_mockBankIfscPrefix}0001002',
      branchAddress: 'CA Bank, Corporate Branch, MG Road, Bangalore',
      nominee: Nominee(
        name: 'Gaurav Sharma',
        relationship: 'Father',
        dateOfBirth: DateTime(1970, 1, 1),
      ),
    ),
    Account(
      accountId: 'ACC003',
      accountNumber: '555544443333',
      accountType: AccountType.fixedDeposit,
      balance: 300000.00,
      availableBalance: 0.00, // FD accounts usually have 0 available balance
      nickname: 'Emergency Fund',
      ifscCode: '${_mockBankIfscPrefix}0001001',
      branchAddress: 'CA Bank, Main Branch, HSR Layout, Bangalore',
      nominee: Nominee(
        name: 'No Nominee Set',
        relationship: 'N/A',
        dateOfBirth: DateTime(1900, 1, 1),
      ),
    ),
  ];

  final List<Transaction> _mockTransactions = [
    // Running balance is calculated backwards from current balance: 55678.50
    Transaction(transactionId: 'TXN0005', description: 'Groceries at SuperMart', amount: 1250.00, date: DateTime.now().subtract(const Duration(hours: 1)), type: TransactionType.debit, runningBalance: 55678.50), // Balance after this debit
    Transaction(transactionId: 'TXN0004', description: 'Salary Credit - Oct 25', amount: 45000.00, date: DateTime.now().subtract(const Duration(days: 2)), type: TransactionType.credit, runningBalance: 56928.50), // Balance before debit + Credit amount
    Transaction(transactionId: 'TXN0003', description: 'Electricity Bill Payment', amount: 3500.00, date: DateTime.now().subtract(const Duration(days: 5)), type: TransactionType.debit, runningBalance: 11928.50), // 56928.50 - 45000 + 1250 = 13178.50
    Transaction(transactionId: 'TXN0002', description: 'Online Purchase - Amazon', amount: 780.00, date: DateTime.now().subtract(const Duration(days: 6)), type: TransactionType.debit, runningBalance: 15428.50),
    Transaction(transactionId: 'TXN0001', description: 'ATM Withdrawal', amount: 10000.00, date: DateTime.now().subtract(const Duration(days: 10)), type: TransactionType.debit, runningBalance: 16208.50),
    // Additional historical data for the detailed statement
    Transaction(transactionId: 'TXN0000', description: 'Initial Deposit', amount: 50000.00, date: DateTime.now().subtract(const Duration(days: 30)), type: TransactionType.credit, runningBalance: 26208.50),
    // ... more transactions to simulate a longer history
  ];

  // Recalculate running balance correctly for accurate display
  List<Transaction> _recalculateRunningBalance(List<Transaction> transactions, double initialBalance) {
    // Sort transactions by date descending (most recent first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    // Start with the latest balance and iterate backwards
    double currentBalance = initialBalance;
    List<Transaction> updatedTransactions = [];

    for (var tx in transactions) {

      double effectiveBalance = tx.type == TransactionType.credit
          ? currentBalance - tx.amount
          : currentBalance + tx.amount;

      updatedTransactions.add(Transaction(
        transactionId: tx.transactionId,
        description: tx.description,
        amount: tx.amount,
        date: tx.date,
        type: tx.type,
        runningBalance: currentBalance,
      ));

      currentBalance = effectiveBalance; // Balance *before* the transaction being processed
    }

    // Since we iterated backwards in time, the list is still sorted by date descending.
    return updatedTransactions;
  }
  final List<Beneficiary> _mockBeneficiaries = [
    Beneficiary(
      beneficiaryId: 'BENF1',
      name: 'Jane Doe',
      accountNumber: '987654321098', // This is the 12-digit mock success account
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

  String maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) {
      return '**** $accountNumber';
    }
    final lastFour = accountNumber.substring(accountNumber.length - 4);
    final maskedPart = '*' * (accountNumber.length - 4);
    return maskedPart + lastFour;
  }

  // --- IFSC HELPER ---
  /// Checks if the given IFSC code belongs to this bank.
  bool isInternalIfsc(String ifsCode) {
    return ifsCode.toUpperCase().startsWith(_mockBankIfscPrefix);
  }
  // Method to fetch all accounts (needed by the fund transfer menu)
  Future<List<Account>> fetchUserAccounts() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockUserAccounts);
  }

  // --- UPDATED: COMBINED SUMMARY AND DETAIL FETCH ---
  /// Fetches the user's primary account with full details (now returns the rich Account object).
  Future<Account> fetchAccountSummary() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_mockUserAccounts.isEmpty) {
      throw Exception('No accounts found for the user.');
    }
    // Assume the first account is the primary account and return its detailed structure
    return _mockUserAccounts.first;
  }

  /// Fetches the user's primary account, typically the first one in the list.
  Future<Account> fetchPrimaryAccount() async {
    // Re-using the detailed summary function, as it returns the rich Account object now
    return fetchAccountSummary();
  }
  // ----------------------------------------------------

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
  // --- Transfer Rules Data (REQUIRED FOR UI) ---
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

    // Use the Random instance defined globally
    final newBeneficiary = Beneficiary(
      beneficiaryId: 'BENF${_random.nextInt(10000)}',
      name: name,
      accountNumber: accountNumber,
      ifsCode: ifsCode.toUpperCase(), // Ensure IFSC is stored uppercase
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

    _mockBeneficiaries[index] = updatedBeneficiary.copyWith(
      ifsCode: updatedBeneficiary.ifsCode.toUpperCase(), // Ensure IFSC is updated uppercase
    );
    _notifyListeners();
    return _mockBeneficiaries[index];
  }

  /// Simulates looking up a recipient's details (external verification).
  Future<Map<String, String>> lookupRecipient({
    required String recipientAccount,
    required String ifsCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final normalizedIfsCode = ifsCode.toUpperCase();

    // MOCK LOGIC: These are the dummy inputs that guarantee a success response
    if (recipientAccount == '123456789012' && normalizedIfsCode == 'HDFC0000053') {
      return {
        'officialName': 'Test Payee Success', // Changed name for clarity
        'bankName': 'HDFC Bank',
      };
    }
    if (recipientAccount == '555544443333' && normalizedIfsCode == 'SBIN0000001') {
      return {
        'officialName': 'New Test Payee',
        'bankName': 'State Bank of India',
      };
    }

    // Success case for internal IFSC match
    if (isInternalIfsc(normalizedIfsCode) && recipientAccount.startsWith('24681357')) {
      return {
        'officialName': 'Internal Payee',
        'bankName': 'CA Bank',
      };
    }

    // General failure for everything else
    throw TransferException('Verification failed. Check account number and IFS code.');
  }


  // --- T-PIN SECURITY METHODS (Unchanged) ---
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
    final otp = (100000 + _random.nextInt(900000)).toString(); // Use _random
    _mockOtp = otp;
    if (kDebugMode) {
      print('MOCK T-PIN RESET OTP GENERATED: $_mockOtp for $_targetMobileForReset');
    }
    return otp;
  }

  Future<void> validateTpinOtp(String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp == _mockOtp && otp.length == _otpLength) {
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
    return isTpinSet && tpin == _currentTPIN;
  }

  Future<void> setTransactionPin({required String oldPin, required String newPin}) async {
    await updateTransactionPin(newPin: newPin, oldPin: oldPin);
  }

  Future<UserProfile> fetchUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _userProfile;
  }

  Future<List<Transaction>> fetchMiniStatement() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockTransactions.take(5).toList();
  }

  Future<List<Transaction>> fetchAllTransactions() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockTransactions;
  }

  /// Fetches the detailed transaction history for a given account ID and date range.
  Future<List<Transaction>> fetchTransactionHistory(
      String accountId, {
        required DateTime startDate,
        required DateTime endDate,
      }) async {
    await Future.delayed(const Duration(milliseconds: 1000)); // Simulate network latency

    // 1. Find the account's latest balance (needed to calculate running balance)
    final account = _mockUserAccounts.firstWhere(
          (acc) => acc.accountId == accountId,
      orElse: () => throw TransferException('Account not found.', code: 'ACCOUNT_NF'),
    );

    // 2. Simulate API fetching the full ledger for the period
    final allTransactions = _mockTransactions;

    // 3. Filter by date range (inclusive)
    final filteredTransactions = allTransactions.where((tx) {
      // Normalize dates for filtering (e.g., set time to midnight for simple comparison)
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59); // End of day

      return tx.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    // 4. Recalculate and add the 'runningBalance' field for the filtered list
    // (In a real system, the CBS would typically provide this, but we mock it here)
    return _recalculateRunningBalance(
      filteredTransactions,
      account.balance, // Use the current mock balance as the latest state
    );
  }

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

  /// Calculates fees, checks limits, and funds *without* changing the state.
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

    // Ensure the return map values are explicitly doubles, not nullable types.
    return {
      'fee': fee,
      'totalDebit': totalDebit,
      'availableDailyLimit': availableDailyLimit,
    };
  }

  // -------------------------------------------------------------------------
  // --- OTP FUND TRANSFER FLOW (Two-Step API) ---
  // -------------------------------------------------------------------------

  /// Step 1 (API /initiate): Performs soft validation, generates an OTP, and returns a reference ID.
  Future<Map<String, dynamic>> requestFundTransferOtp({
    required String recipientAccount,
    required double amount,
    required String sourceAccountNumber,
    required TransferType transferType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // --- SOFT VALIDATION (Uses existing detailed calculation logic) ---
    try {
      // This call checks limits, funds, and RTGS minimums
      await calculateTransferDetails(
        transferType: transferType,
        amount: amount,
        sourceAccountNumber: sourceAccountNumber,
      );
    } on TransferException {
      rethrow;
    } catch (e) {
      // Catches generic errors during calculation
      throw TransferException(e.toString().replaceAll('Exception: ', ''));
    }

    // --- OTP GENERATION ---
    final otp = (100000 + _random.nextInt(900000)).toString();
    final transactionReference = 'TX${_random.nextInt(99999999)}';

    // Store state for Step 2 (Verification)
    _mockOtp = otp;
    _mockTransactionReference = transactionReference;
    _otpGenerationTime = DateTime.now();

    if (kDebugMode) {
      print('MOCK TRANSFER OTP GENERATED: $_mockOtp (Ref: $_mockTransactionReference)');
    }

    // Return the reference ID and message. The 'mockOtp' is for debug/testing only.
    return {
      'transactionReference': transactionReference,
      'message': 'OTP sent to mobile number: ******${_registeredMobileNumber.substring(_registeredMobileNumber.length - 4)}',
      'mockOtp': otp,
    };
  }

  /// Step 2 (API /verify): Validates OTP and executes the ledger update.
  Future<String> submitFundTransfer({
    required String recipientAccount,
    required String recipientName,
    String? ifsCode,
    required TransferType transferType,
    required double amount,
    String? narration,
    required String transactionReference, // Reference ID
    required String transactionOtp, // OTP
    required String sourceAccountNumber,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    // --- HARD VALIDATION (OTP & Reference Check) ---
    // Use null checks and safe comparisons for the state variables
    if (transactionReference != _mockTransactionReference || _mockTransactionReference == null) {
      throw TransferException('Transaction failed: Invalid or expired transaction reference ID.');
    }

    if (transactionOtp != _mockOtp || _mockOtp == null || transactionOtp.length != _otpLength) {
      throw TransferException('Transaction failed: Invalid OTP.');
    }

    if (_otpGenerationTime == null || DateTime.now().difference(_otpGenerationTime!).inMinutes > 5) {
      // Clear expired OTP state
      _mockOtp = null;
      _mockTransactionReference = null;
      throw TransferException('Transaction failed: OTP expired. Please initiate the transfer again.');
    }
    // --- MOCK SYSTEM FAILURE POINT (NEW ADDITION) ---
    // If the reference ID contains 'TX999', simulate a system error after OTP validation
    if (transactionReference.contains('TX999')) {
      // Clear OTP/Reference state to prevent reuse
      _mockOtp = null;
      _mockTransactionReference = null;
      _otpGenerationTime = null;
      throw TransferException('Transaction failed: Internal System Error (Mock 999). Please try again later.', code: 'SYSTEM_999');
    }

    // Clear OTP/Reference after successful verification to prevent reuse
    _mockOtp = null;
    _mockTransactionReference = null;
    _otpGenerationTime = null;

    // --- EXECUTION SETUP ---
    final sourceIndex = _mockUserAccounts.indexWhere((acc) => acc.accountNumber == sourceAccountNumber);
    final sourceAccount = sourceIndex != -1 ? _mockUserAccounts[sourceIndex] : null;

    if (sourceAccount == null) {
      throw TransferException('Transaction failed: Source account not found during final execution.');
    }

    double fee = 0.0;
    double totalDebitAmount = amount;

    // Re-run the fee/total calculation for external transfers right before execution
    final isTransferToOwnAccount = _mockUserAccounts.any((a) => a.accountNumber == recipientAccount);

    if (transferType != TransferType.internal && !isTransferToOwnAccount) {
      if (kDebugMode) {
        print('External transfer detected. Re-validating fees and limits...');
      }
      try {
        final details = await calculateTransferDetails(
          transferType: transferType,
          amount: amount,
          sourceAccountNumber: sourceAccountNumber,
        );
        // Explicitly cast the returned doubles
        fee = details['fee'] as double;
        totalDebitAmount = details['totalDebit'] as double;
      } on TransferException {
        rethrow;
      } catch (e) {
        throw TransferException('Execution failed during fee check: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }

    final finalNarration = narration?.trim() ?? '';

    if (isTransferToOwnAccount || isInternalIfsc(ifsCode ?? '')) {
      // Case 1: Internal Bank Transfer (Own Account or Beneficiary in Same Bank)
      return _performInternalTransfer(
        amount: amount,
        narration: finalNarration,
        sourceAccount: sourceAccount,
        recipientAccount: recipientAccount,
        sourceIndex: sourceIndex,
      );
    } else {
      // Case 2: External Transfer (IMPS/NEFT/RTGS to different bank)
      if (ifsCode == null || ifsCode.isEmpty) {
        throw TransferException('Transaction failed: IFS Code is required for external transfers (IMPS/NEFT/RTGS).');
      }

      return _performExternalTransfer(
        transferType: transferType,
        amount: amount,
        fee: fee,
        totalDebitAmount: totalDebitAmount,
        recipientName: recipientName,
        narration: finalNarration,
        sourceAccount: sourceAccount,
        sourceIndex: sourceIndex,
      );
    }
  }

  // --- FUND TRANSFER HELPERS (Continuation) ---
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
      throw TransferException('Transaction failed: Destination account not found in system.');
    }

    // 3. FINAL CHECK: Insufficient Funds
    if (amount > sourceAccount.balance) {
      throw TransferException('Transaction failed: Insufficient funds for transfer.');
    }

    // --- LEDGER UPDATE (Simulated Atomic Commit) ---
    final newSourceBalance = sourceAccount.balance - amount;
    _mockUserAccounts[sourceIndex] = sourceAccount.copyWith(newBalance: newSourceBalance);

    final newDestinationBalance = destinationAccount.balance + amount;
    _mockUserAccounts[destinationIndex] = destinationAccount.copyWith(newBalance: newDestinationBalance);

    _todayTransferredAmount += amount;

    // Generate Transaction ID and log the transaction
    final transactionId = 'INT${DateTime.now().millisecondsSinceEpoch}';
    final debitTx = Transaction(
      transactionId: transactionId,
      description: 'Internal Transfer to ${destinationAccount.nickname} (${maskAccountNumber(destinationAccount.accountNumber)}) - $narration',
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.debit,
      runningBalance: newSourceBalance,
    );
    _mockTransactions.insert(0, debitTx);

    // Note: A credit transaction would also be logged in a real system. We skip it here
    // for simplicity on the source account's transaction list.

    _notifyListeners();

    return transactionId;
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
    // 1. BANKING RULE: Prevent debit from deposit accounts (FD/RD)
    if (sourceAccount.accountType == AccountType.fixedDeposit ||
        sourceAccount.accountType == AccountType.recurringDeposit) {
      throw TransferException(
        'Transaction failed: Cannot directly debit funds from a ${sourceAccount.accountType.name}.',
        code: 'DEPOSIT_DEBIT_BLOCKED',
      );
    }

    // 2. FINAL CHECK: Insufficient Funds (Checked again here for safety)
    if (totalDebitAmount > sourceAccount.balance) {
      throw TransferException('Transaction failed: Insufficient funds for transfer.');
    }

    // --- LEDGER UPDATE (Simulated Debit) ---
    final newSourceBalance = sourceAccount.balance - totalDebitAmount;
    _mockUserAccounts[sourceIndex] = sourceAccount.copyWith(newBalance: newSourceBalance);

    _todayTransferredAmount += amount; // Only the principal amount counts towards the limit

    // Generate Transaction ID and log the transaction
    final transactionId = '${transferType.name.toUpperCase()}${DateTime.now().millisecondsSinceEpoch}';
    final description = 'Transfer to $recipientName ($transferType) - $narration. Fee: ₹${fee.toStringAsFixed(2)}';
    final debitTx = Transaction(
      transactionId: transactionId,
      description: description,
      amount: totalDebitAmount, // Total debited amount (principal + fee)
      date: DateTime.now(),
      type: TransactionType.debit,
      runningBalance: newSourceBalance,
    );
    _mockTransactions.insert(0, debitTx);

    _notifyListeners();

    return transactionId;
  }
}