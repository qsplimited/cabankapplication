class AccountDetails {
  final String accountNumber;
  final String accountHolderName;
  final String bankName;
  final String branchName;
  final String ifscCode;
  final String accountType;
  final List<TransactionEntry> transactionHistory;

  AccountDetails({
    required this.accountNumber,
    required this.accountHolderName,
    required this.bankName,
    required this.branchName,
    required this.ifscCode,
    required this.accountType,
    required this.transactionHistory,
  });


  double get currentBalance => transactionHistory.isNotEmpty
      ? transactionHistory.first.currentBalance
      : 0.0;

  factory AccountDetails.fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    return AccountDetails(
      accountNumber: value['accountNumber'],
      accountHolderName: value['accountHolderName'],
      bankName: value['bankName'],
      branchName: value['branchName'],
      ifscCode: value['IFSCCode'],
      accountType: value['accountType'],
      transactionHistory: (value['transactionHistory'] as List)
          .map((e) => TransactionEntry.fromJson(e))
          .toList(),
    );
  }
}

class TransactionEntry {
  final double currentBalance;
  final double transactionAmount;
  final String status;
  final String transactionType;

  TransactionEntry({
    required this.currentBalance,
    required this.transactionAmount,
    required this.status,
    required this.transactionType,
  });

  factory TransactionEntry.fromJson(Map<String, dynamic> json) {
    return TransactionEntry(
      currentBalance: (json['currentBalance'] as num).toDouble(),
      transactionAmount: (json['transactionAmount'] as num).toDouble(),
      status: json['status'],
      transactionType: json['transactionType'],
    );
  }
}