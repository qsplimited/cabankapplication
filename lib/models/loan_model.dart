import 'package:flutter/material.dart';

class LoanProduct {
  final String id;
  final String title;
  final String interestRate;
  final double rawRate;
  final double minAmount;
  final double maxAmount;
  final int maxTenureMonths;
  final IconData icon;
  final String tag;
  final List<String> requiredDocs;

  LoanProduct({
    required this.id,
    required this.title,
    required this.interestRate,
    required this.rawRate,
    required this.minAmount,
    required this.maxAmount,
    required this.maxTenureMonths,
    required this.icon,
    this.tag = "",
    required this.requiredDocs,
  });
}

class ActiveLoan {
  final String loanId;
  final String type;
  final double balance;
  final double totalLoan;
  final String nextEmiDate;
  final double progress;

  ActiveLoan({
    required this.loanId,
    required this.type,
    required this.balance,
    required this.totalLoan,
    required this.nextEmiDate,
    required this.progress,
  });
}