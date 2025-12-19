import 'package:flutter/material.dart';

class Nominee {
  final String name;
  final String relationship;
  final double share;

  Nominee({required this.name, required this.relationship, required this.share});

  // CRITICAL: This allows updating the object data easily
  Nominee copyWith({String? name, String? relationship, double? share}) {
    return Nominee(
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      share: share ?? this.share,
    );
  }
}

class DepositAccount {
  final String id;
  final String accountNumber;
  final String accountType;
  final double principalAmount;
  final double accruedInterest;
  final double interestRate;
  final DateTime openingDate;
  final DateTime maturityDate;
  final String linkedAccountNumber;
  final List<Nominee> nominees;

  DepositAccount({
    required this.id,
    required this.accountNumber,
    required this.accountType,
    required this.principalAmount,
    required this.accruedInterest,
    required this.interestRate,
    required this.openingDate,
    required this.maturityDate,
    required this.linkedAccountNumber,
    required this.nominees,
  });

  double get totalMaturityAmount => principalAmount + accruedInterest;
  bool get isMatured => DateTime.now().isAfter(maturityDate);

  // CRITICAL: To update the list after T-PIN success
  DepositAccount copyWith({List<Nominee>? nominees}) {
    return DepositAccount(
      id: id,
      accountNumber: accountNumber,
      accountType: accountType,
      principalAmount: principalAmount,
      accruedInterest: accruedInterest,
      interestRate: interestRate,
      openingDate: openingDate,
      maturityDate: maturityDate,
      linkedAccountNumber: linkedAccountNumber,
      nominees: nominees ?? this.nominees,
    );
  }
}