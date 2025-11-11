/// Enum for different types of deposit accounts.
enum AccountType {
  savings,
  current,
  fixedDeposit, // Fixed Deposit (can be a destination)
  recurringDeposit, // Recurring Deposit (can be a destination)
}

/// Model representing a user's bank account.
class Account {
  final String accountNumber;
  final String nickname;
  final AccountType accountType;
  double balance;

  Account({
    required this.accountNumber,
    required this.nickname,
    required this.accountType,
    required this.balance,
  });

  String get typeDisplay {
    switch (accountType) {
      case AccountType.savings:
        return 'Savings Account (SA)';
      case AccountType.current:
        return 'Current Account (CA)';
      case AccountType.fixedDeposit:
        return 'Fixed Deposit (FD)';
      case AccountType.recurringDeposit:
        return 'Recurring Deposit (RD)';
    }
  }
}

/// Enum for transfer types (kept simple for this internal transfer screen)
enum TransferType { internal }