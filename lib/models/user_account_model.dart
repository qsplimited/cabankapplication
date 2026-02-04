class CustomerAccount {
  final String accountId;
  final String accountNumber;
  final String accountType;
  final double balance;
  final String ifscCode;
  final String branchName;
  final String customerName;
  final String currency;

  CustomerAccount({
    required this.accountId,
    required this.accountNumber,
    required this.accountType,
    required this.balance,
    required this.ifscCode,
    required this.branchName,
    required this.customerName,
    this.currency = "INR",
  });

  factory CustomerAccount.fromJson(Map<String, dynamic> json) {
    return CustomerAccount(
      accountId: json['accountId']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      accountType: json['accountType']?.toString() ?? '',
      balance: (json['balance'] ?? 0.0).toDouble(),
      ifscCode: json['ifscCode']?.toString() ?? '',
      branchName: json['branchName']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      currency: json['currency']?.toString() ?? 'INR',
    );
  }
}