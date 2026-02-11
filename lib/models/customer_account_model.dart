class CustomerAccount {
  final String customerId;
  final String savingAccountNumber;
  final String firstName;
  final String lastName;
  final String branchCode;
  final String accountType;
  final String mobileNo;
  final String email;
  final String documentType;
  final String documentNumber;
  final String accountNumber;
  final String createdDate;
  final double balance; // This will hold the value from history

  CustomerAccount({
    required this.customerId,
    required this.savingAccountNumber,
    required this.firstName,
    required this.lastName,
    required this.branchCode,
    required this.accountType,
    required this.mobileNo,
    required this.email,
    required this.documentType,
    required this.documentNumber,
    required this.accountNumber,
    required this.createdDate,
    this.balance = 0.0,
  });

  String get fullName => "$firstName $lastName";

  // ADD THIS METHOD: It allows merging profile + balance
  CustomerAccount copyWith({double? balance}) {
    return CustomerAccount(
      customerId: customerId,
      savingAccountNumber: savingAccountNumber,
      firstName: firstName,
      lastName: lastName,
      branchCode: branchCode,
      accountType: accountType,
      mobileNo: mobileNo,
      email: email,
      documentType: documentType,
      documentNumber: documentNumber,
      accountNumber: accountNumber,
      createdDate: createdDate,
      balance: balance ?? this.balance,
    );
  }

  factory CustomerAccount.fromJson(Map<String, dynamic> json) {
    // Navigation into the 'value' object as per your API response
    final val = json['value'] ?? {};

    return CustomerAccount(
      customerId: val['customerId']?.toString() ?? '',
      savingAccountNumber: val['savingAccountNumber']?.toString() ?? '',
      firstName: val['firstName']?.toString() ?? '',
      lastName: val['lastName']?.toString() ?? '',
      branchCode: val['branchCode']?.toString() ?? '',
      accountType: val['accountType']?.toString() ?? 'Savings',
      mobileNo: val['mobileNo']?.toString() ?? '',
      email: val['email']?.toString() ?? '',
      documentType: val['documentType']?.toString() ?? '',
      documentNumber: val['documentNumber']?.toString() ?? '',
      accountNumber: val['accountNumber']?.toString() ?? '',
      createdDate: val['createdDate']?.toString() ?? '',

      // FIX: Look for 'balance' in the top level or value object
      // to avoid resetting to 0.0 if the data already exists.
      balance: (json['balance'] as num?)?.toDouble() ??
          (val['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}