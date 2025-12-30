// lib/models/deposit_account.dart

import 'package:flutter/material.dart';

// 🌟 INDUSTRY STANDARD: Distinguish between active and matured accounts
enum DepositStatus { running, matured, closed }

class Nominee {
  final String name;
  final String relationship;
  final double share;

  Nominee({required this.name, required this.relationship, required this.share});

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
  final String accountType; // "Fixed Deposit" or "Recurring Deposit"
  final double principalAmount;
  final double accruedInterest;
  final double interestRate;
  final DateTime openingDate;
  final DateTime maturityDate;
  final String linkedAccountNumber;
  final List<Nominee> nominees;
  final DepositStatus status; // 🌟 NEW CRITICAL FIELD

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
    required this.status,
  });

  double get totalMaturityAmount => principalAmount + accruedInterest;

  // Logic check: Is this deposit past its maturity date?
  bool get hasMatured => DateTime.now().isAfter(maturityDate);

  DepositAccount copyWith({List<Nominee>? nominees, DepositStatus? status}) {
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
      status: status ?? this.status,
    );
  }
}