class DepositScheme {
  final String id;
  final String name;
  final double interestRate;

  DepositScheme({required this.id, required this.name, required this.interestRate});
}

class SourceAccount {
  final String accountNumber;
  final double availableBalance;
  final double dailyLimit;
  final List<String> nomineeNames;

  SourceAccount({
    required this.accountNumber,
    required this.availableBalance,
    required this.dailyLimit,
    required this.nomineeNames,
  });
}

// 🌟 NEW MODEL: Details calculated before final confirmation (Step 2)
class MaturityDetails {
  final double principalAmount;
  final double maturityAmount;
  final double interestEarned;
  final String maturityDate;

  MaturityDetails({
    required this.principalAmount,
    required this.maturityAmount,
    required this.interestEarned,
    required this.maturityDate,
  });
}

// 🌟 NEW MODEL: Input data passed from the form screen to the confirmation screen
class FdInputData {
  final double amount;
  final SourceAccount sourceAccount;
  final DepositScheme selectedScheme;
  final String selectedNominee;
  final int tenureYears;
  final int tenureMonths;
  final int tenureDays;

  FdInputData({
    required this.amount,
    required this.sourceAccount,
    required this.selectedScheme,
    required this.selectedNominee,
    required this.tenureYears,
    required this.tenureMonths,
    required this.tenureDays,
  });
}

// Response structure for the T-PIN confirmation API call
class FdConfirmationResponse {
  final bool success;
  final String message;
  final String? fdReferenceNumber;

  FdConfirmationResponse({
    required this.success,
    required this.message,
    this.fdReferenceNumber,
  });
}