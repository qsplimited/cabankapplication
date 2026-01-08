// lib/models/deposit_account.dart

import 'package:flutter/material.dart';

/// INDUSTRY STANDARD: Distinguish between active, matured, and settled accounts
enum DepositStatus { running, matured, closed }

class Nominee {
  final String name;
  final String relationship;
  final double share;

  Nominee({
    required this.name,
    required this.relationship,
    required this.share
  });

  /// Preserves existing logic for editing nominee details
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
  final String accountType; // e.g., "Fixed Deposit" or "Recurring Deposit"
  final double principalAmount;
  final double accruedInterest;
  final double interestRate;
  final DateTime openingDate;
  final DateTime maturityDate;
  final String linkedAccountNumber;
  final List<Nominee> nominees;
  final DepositStatus status;

  /// 🌟 MASTER LOCK FIELD: Used to block actions if a loan is active against this deposit
  /// Values: "Nil" (Available), "Marked" (Locked/Pledged)
  final String lienStatus;

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
    this.lienStatus = "Nil", // Default state is no lien
  });

  /// Total value returned to the user (Principal + Interest)
  double get totalMaturityAmount => principalAmount + accruedInterest;

  /// System check to see if the deposit term has ended
  bool get hasMatured => DateTime.now().isAfter(maturityDate);

  /// 🌟 CENTRAL BUSINESS LOGIC:
  /// Returns true if the deposit is currently blocked (e.g., used for a loan)
  bool get isLienMarked => lienStatus.toLowerCase() == "marked";

  /// 🌟 PRESERVED LOGIC:
  /// Allows updating specific fields (like nominees or lien status) while keeping others intact.
  /// This is essential for both the 'Edit Nominee' flow and 'Apply Loan' updates.
  DepositAccount copyWith({
    List<Nominee>? nominees,
    DepositStatus? status,
    String? lienStatus
  }) {
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
      lienStatus: lienStatus ?? this.lienStatus,
    );
  }
}