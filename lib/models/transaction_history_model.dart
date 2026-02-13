class TransactionHistory {
  final double currentBalance;
  final String? failureReason;
  final int id;
  final String? status;
  final double transactionAmount;
  final DateTime transactionDateTime;
  final String transactionRefNo;
  final String transactionType;

  TransactionHistory({
    required this.currentBalance,
    this.failureReason,
    required this.id,
    this.status,
    required this.transactionAmount,
    required this.transactionDateTime,
    required this.transactionRefNo,
    required this.transactionType,
  });

  factory TransactionHistory.fromJson(Map<String, dynamic> json) {
    return TransactionHistory(
      currentBalance: (json['currentBalance'] as num).toDouble(),
      failureReason: json['failureReason'],
      id: json['id'],
      status: json['status'],
      transactionAmount: (json['transactionAmount'] as num).toDouble(),
      transactionDateTime: DateTime.parse(json['transactionDateTime']),
      transactionRefNo: json['transactionRefNo'] ?? '',
      transactionType: json['transactionType'] ?? 'DEBIT',
    );
  }

  bool get isDebit => transactionType.toUpperCase() == "DEBIT";
}