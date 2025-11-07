import 'dart:math';

// Helper function to generate a unique ID for mock data (for Beneficiaries)
String generateUniqueId() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  Random rnd = Random();
  String result = String.fromCharCodes(Iterable.generate(
      10, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  return 'b-$result';
}

// --- ENUMS ---

/// Enum to define different types of transfers
enum TransferType { imps, neft, rtgs }

/// Enum to define different types of transactions
enum TransactionType { debit, credit }

/// Security status of the payee account.
enum BeneficiaryStatus {
  active, // Fully approved and available for transactions
  pending, // Currently in the security cooling-off period
  blocked, // Account is temporarily blocked or invalid
}

// --- DOMAIN MODELS ---

/// User details model.
class UserProfile {
  final String fullName;
  final String userId;
  final DateTime lastLogin;
  UserProfile({required this.fullName, required this.userId, required this.lastLogin});
}

/// Account model for the USER's primary balance and type.
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

/// Specific model for a Payee's account details (number and IFSC).
class PayeeAccount {
  final String accountNumber;
  final String ifscCode;

  PayeeAccount({
    required this.accountNumber,
    required this.ifscCode,
  });
}

/// Beneficiary (Payee) details model.
class Beneficiary {
  final String id; // Unique identifier for the beneficiary
  final String name;
  final PayeeAccount account; // Uses the specific PayeeAccount model
  final String bankName; // Bank name derived from IFSC code or user input
  final BeneficiaryStatus status;
  final DateTime addedDate; // Time when the beneficiary was added

  Beneficiary({
    required this.id,
    required this.name,
    required this.account,
    required this.bankName,
    required this.status,
    required this.addedDate,
  });

  // Helper method for updating status (e.g., changing from 'pending' to 'active')
  Beneficiary copyWith({BeneficiaryStatus? status}) {
    return Beneficiary(
      id: id,
      name: name,
      account: account,
      bankName: bankName,
      status: status ?? this.status,
      addedDate: addedDate,
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

// --- DATA TRANSFER OBJECTS (DTOs) & UTILITIES ---

/// Result from a successful account lookup API call (used in Add Beneficiary).
class AccountLookupResult {
  final String name;
  final String bankName;

  AccountLookupResult({
    required this.name,
    required this.bankName,
  });
}

/// Payload used when calling the addBeneficiary API endpoint.
class AddBeneficiaryPayload {
  final String name; // Verified name from lookup
  final String bankName; // Verified bank name from lookup
  final String accountNumber;
  final String ifscCode;
  final String nickname; // User-defined name for display

  AddBeneficiaryPayload({
    required this.name,
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.nickname,
  });
}

/// NEW: Payload used when confirming a funds transfer transaction.
class FundsTransferPayload {
  final String beneficiaryId;
  final double amount;
  final String remarks;
  final String tPin; // Transaction PIN for authorization
  final TransferType transferType; // IMPS, NEFT, RTGS

  FundsTransferPayload({
    required this.beneficiaryId,
    required this.amount,
    required this.remarks,
    required this.tPin,
    required this.transferType,
  });
}