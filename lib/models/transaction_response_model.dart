class TransactionResponse {
  final double amount;
  final String fromAccount;
  final String toAccount;
  final String message;
  final String status;
  final String transactionDateTime;
  final String transactionRefNo;

  TransactionResponse({
    required this.amount,
    required this.fromAccount,
    required this.toAccount,
    required this.message,
    required this.status,
    required this.transactionDateTime,
    required this.transactionRefNo,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    final val = json['value'];
    return TransactionResponse(
      amount: (val['amount'] as num).toDouble(),
      fromAccount: val['fromAccount'],
      toAccount: val['toAccount'],
      message: val['message'],
      status: val['status'],
      transactionDateTime: val['transactionDateTime'],
      transactionRefNo: val['transactionRefNo'],
    );
  }
}