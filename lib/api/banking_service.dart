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
/// This model is essential if your real API will accept a single JSON payload instead of individual arguments.
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

  // Private constructor
  BankingService._internal();

  // --- STATE MANAGEMENT: T-PIN, OTP, AND BALANCE ---
  // Set a mock 4-digit T-PIN for testing, as the UI uses a 4-digit standard.
  String? _currentTPIN = '1234';
  static const int _tpinLength = 4; // Used for consistency
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

  // --- BENEFICIARY MOCK DATA (The list of existing payees) ---
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
      name: 'Car Loan EMI',
      accountNumber: '246813579024',
      ifsCode: 'PNB0000055',
      bankName: 'Punjab National Bank',
      nickname: 'Car Loan',
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
    AddBeneficiaryPayload? payload, // Kept for API signature consistency
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    final newId = 'BENF${Random().nextInt(10000)}';

    // *** IMPORTANT: This is the duplication check (simulating a real bank rejecting a duplicate). ***
    if (_mockBeneficiaries.any((b) => b.accountNumber == accountNumber)) {
      throw Exception('Beneficiary with this account number already exists.');
    }

    final newBeneficiary = Beneficiary(
      beneficiaryId: newId,
      name: name,
      accountNumber: accountNumber,
      ifsCode: ifsCode,
      bankName: bankName,
      nickname: nickname,
    );

    // *** This is where the new payee is saved in our mock database. ***
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
      throw Exception('Beneficiary not found for deletion.');
    }
    _notifyListeners();
  }

  /// UPDATED: Updates a beneficiary using a full Beneficiary object.
  Future<Beneficiary> updateBeneficiary(Beneficiary updatedBeneficiary) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _mockBeneficiaries.indexWhere((b) => b.beneficiaryId == updatedBeneficiary.beneficiaryId);

    if (index == -1) {
      throw Exception('Beneficiary not found for update.');
    }

    // *** This is where the update happens in our mock database. ***
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
    // Scenario 1: Existing (Jane Doe - Fails in Add step due to duplicate check)
    if (recipientAccount == '987654321098' && ifsCode.toUpperCase() == 'HDFC0000053') {
      return {
        'officialName': 'Jane Doe',
        'bankName': 'HDFC Bank',
      };
    }
    // Scenario 2: Brand New Payee (Success in both Lookup and Add steps)
    if (recipientAccount == '555544443333' && ifsCode.toUpperCase() == 'SBIN0000001') {
      return {
        'officialName': 'New Test Payee',
        'bankName': 'State Bank of India',
      };
    }
    // Scenario 3: Account Not Found
    if (recipientAccount == '111111111111') {
      throw Exception('Account not found. Please check the account number.');
    }

    // General failure
    throw Exception('Verification failed. Check account number and IFS code.');
  }


  // --- T-PIN SECURITY METHODS (UPDATED) ---

  /// Finds the account by mobile number and sets it as the target for T-PIN reset.
  bool findAccountByMobileNumber(String mobileNumber) {
    final exists = mobileNumber == _registeredMobileNumber;

    if (exists) {
      _targetMobileForReset = mobileNumber;
    } else {
      _targetMobileForReset = '';
    }
    return exists;
  }

  /// Returns the masked mobile number for display during OTP flow.
  String getMaskedMobileNumber() {
    if (_targetMobileForReset.isEmpty) return '******0000';
    final String fullNumber = _targetMobileForReset;
    return '******' + fullNumber.substring(fullNumber.length - 4);
  }

  /// Generates and stores a mock OTP.
  Future<String> requestTpinOtp() async {
    if (_targetMobileForReset.isEmpty) {
      throw 'Mobile number not verified. Cannot send OTP.';
    }

    await Future.delayed(const Duration(seconds: 2));
    final otp = (100000 + Random().nextInt(900000)).toString();
    _mockOtp = otp;
    debugPrint('MOCK OTP GENERATED: $_mockOtp for $_targetMobileForReset');
    return otp;
  }

  /// Validates the provided OTP against the stored mock OTP.
  Future<void> validateTpinOtp(String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp == _mockOtp && otp.length == 6) {
      _mockOtp = null;
      return;
    } else {
      throw 'Invalid or expired OTP. Please request a new one.';
    }
  }

  /// Sets or updates the 6-digit Transaction PIN. Requires old pin if already set,
  /// or a successful OTP flow if resetting.
  Future<String> updateTransactionPin({
    required String newPin,
    String? oldPin,
  }) async {
    await Future.delayed(const Duration(milliseconds: 700));

    // Case 1: T-PIN is already set and user provided an oldPin (standard change)
    if (isTpinSet && oldPin != null) {
      if (oldPin != _currentTPIN) {
        throw 'Current T-PIN is incorrect. Authorization failed.';
      }
      // Case 2: T-PIN is set but no oldPin (means a reset flow via mobile number/OTP)
    } else if (isTpinSet && oldPin == null) {
      if (_targetMobileForReset.isEmpty) {
        throw 'Current T-PIN must be provided to change the PIN unless a reset flow is initiated.';
      }
      // Case 3: T-PIN is NOT set (initial setup)
    }

    // Global validation - Assuming 4 digits is the UI standard, adjusted logic for 4-digit T-PIN
    if (newPin.length != _tpinLength || !RegExp(r'^\d+$').hasMatch(newPin)) {
      throw 'Invalid PIN format. New T-PIN must be exactly $_tpinLength numeric digits.';
    }

    _currentTPIN = newPin;
    _targetMobileForReset = '';
    debugPrint('T-PIN updated to: $_currentTPIN');

    _notifyListeners();

    return 'T-PIN set successfully!';
  }

  /// ADDED: Implements T-PIN validation logic for high-risk transactions.
  Future<bool> validateTpin(String tpin) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Check if T-PIN is set and if the provided T-PIN matches the stored PIN.
    return isTpinSet && tpin == _currentTPIN;
  }

  /// Fetches the current user profile data.
  Future<UserProfile> fetchUserProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _userProfile;
  }

  /// Fetches the primary account summary.
  Future<Account> fetchAccountSummary() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _primaryAccount;
  }

  /// Fetches the top 5 transactions.
  Future<List<Transaction>> fetchMiniStatement() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockTransactions.take(5).toList();
  }

  /// Fetches all available transaction history.
  Future<List<Transaction>> fetchAllTransactions() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return _mockTransactions;
  }

  /// Simulates submitting a fund transfer request.
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

    // 1. PIN Validation
    if (_currentTPIN == null) {
      throw 'Transaction failed: T-PIN is not set. Please set your T-PIN first.';
    }
    if (transactionPin != _currentTPIN) {
      throw 'Transaction failed: Invalid Transaction PIN.';
    }

    // 2. Fund Validation
    if (amount <= 0) {
      throw 'Transaction failed: Amount must be greater than zero.';
    }
    if (amount > _primaryAccount.balance) {
      throw 'Insufficient funds. Current balance: ₹${_primaryAccount.balance.toStringAsFixed(2)}';
    }

    // 3. Perform Transaction
    double newBalance = _primaryAccount.balance - amount;
    _primaryAccount = _primaryAccount.copyWith(newBalance: newBalance);

    // 4. Record Transaction
    final newTransaction = Transaction(
      description: narration ?? 'Fund Transfer to $recipientName',
      amount: amount,
      date: DateTime.now(),
      type: TransactionType.debit,
    );
    _mockTransactions.insert(0, newTransaction);


    _notifyListeners();

    // 5. Return success message
    return 'Success! ₹${amount.toStringAsFixed(2)} transferred via ${transferType.name.toUpperCase()}. Transaction ID: ${Random().nextInt(99999999)}';
  }

  Future<void> setTransactionPin({required String oldPin, required String newPin}) async {}


// NOTE: setTransactionPin was removed to keep the API clean, as updateTransactionPin handles both set and reset.
}