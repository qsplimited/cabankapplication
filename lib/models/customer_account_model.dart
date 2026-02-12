class CustomerAccount {
  final int? id; // Added from API
  final String? approverStaffId; // Added from API
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
  final double balance;

  CustomerAccount({
    this.id,
    this.approverStaffId,
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

  CustomerAccount copyWith({double? balance}) {
    return CustomerAccount(
      id: id,
      approverStaffId: approverStaffId,
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
    final val = json['value'] ?? {};

    return CustomerAccount(
      id: val['id'] as int?,
      approverStaffId: val['approverStaffId']?.toString(),
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
      accountNumber: val['accountNumber']?.toString() ?? val['savingAccountNumber']?.toString() ?? '',
      createdDate: val['createdDate']?.toString() ?? '',
      balance: (json['balance'] as num?)?.toDouble() ??
          (val['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}