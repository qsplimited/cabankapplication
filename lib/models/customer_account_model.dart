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
  final String createdDate;

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
    required this.createdDate,
  });

  String get fullName => "$firstName $lastName";

  factory CustomerAccount.fromJson(Map<String, dynamic> json) {
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
      createdDate: val['createdDate']?.toString() ?? '',
    );
  }
}