import 'dart:async';
import 'package:flutter/foundation.dart';

// Enum to define different types of transfers
enum TransferType { imps, neft, rtgs }

// Enum to define different types of transactions
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
