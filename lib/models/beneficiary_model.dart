// lib/models/beneficiary_models.dart

class Beneficiary {
  final String beneficiaryId;
  final String name;
  final String accountNumber;
  final String ifsCode;
  final String bankName;
  final String nickname;

  Beneficiary({
    required this.beneficiaryId,
    required this.name,
    required this.accountNumber,
    required this.ifsCode,
    required this.bankName,
    required this.nickname,
  });

  // Helps in creating a copy for editing
  Beneficiary copyWith({
    String? name,
    String? accountNumber,
    String? ifsCode,
    String? bankName,
    String? nickname,
  }) {
    return Beneficiary(
      beneficiaryId: beneficiaryId,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsCode: ifsCode ?? this.ifsCode,
      bankName: bankName ?? this.bankName,
      nickname: nickname ?? this.nickname,
    );
  }
}