// File: lib/models/rd_models.dart

import 'fd_models.dart'; // Import to use DepositScheme, SourceAccount

class RdMaturityDetails {
  final double totalPrincipalAmount;
  final double interestEarned;
  final double maturityAmount;
  final String maturityDate; // e.g., "24-Mar-2028"

  RdMaturityDetails({
    required this.totalPrincipalAmount,
    required this.interestEarned,
    required this.maturityAmount,
    required this.maturityDate,
  });
}

class RdInputData {
  final double installmentAmount;
  final SourceAccount sourceAccount;
  final DepositScheme selectedScheme;
  final String selectedNominee;
  final int tenureYears;
  final int tenureMonths;
  final int tenureDays;
  final String frequencyMode; // Monthly, Quarterly, Half-Yearly

  RdInputData({
    required this.installmentAmount,
    required this.sourceAccount,
    required this.selectedScheme,
    required this.selectedNominee,
    required this.tenureYears,
    required this.tenureMonths,
    required this.tenureDays,
    required this.frequencyMode,
  });
}