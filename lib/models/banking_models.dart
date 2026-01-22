import 'package:cabankapplication/api/banking_service.dart' as service;

// Mapping your existing service types to a clean Model
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

enum TransactionType { debit, credit }

class Account {
  final String accountNumber;
  final double balance;
  final String accountType;
  final String nickname;

  Account({
    required this.accountNumber,
    required this.balance,
    required this.accountType,
    required this.nickname,
  });
}