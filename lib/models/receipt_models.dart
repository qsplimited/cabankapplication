enum ReceiptType { opening, renewal, closure }

class DepositReceipt {
  final ReceiptType receiptType;
  final String accountType;
  final String transactionId;
  final DateTime date; // Entry/System Date
  final DateTime? valueDate; // Interest Start Date
  final String nomineeName;
  final String accountNumber;
  final String schemeName;
  final double interestRate;
  final String tenure;
  final double amount;

  // Dates & Instructions
  final String? maturityDate;
  final String? maturityInstruction; // e.g., Auto-Renew Principal & Interest
  final String? lienStatus; // e.g., Nil

  // Specific for Opening/Renewal
  final double? maturityAmount;
  final String? sourceAccount;
  final String? oldAccountNumber;

  // Specific for Closure
  final double? accruedInterest;
  final double? penaltyAmount;
  final double? taxDeducted;
  final double? netPayout;
  final String? destinationAccount;
  final String? closureStatus;

  DepositReceipt({
    required this.receiptType, required this.accountType, required this.transactionId,
    required this.date, this.valueDate, required this.nomineeName,
    required this.accountNumber, required this.schemeName, required this.interestRate,
    required this.tenure, required this.amount, this.maturityDate,
    this.maturityInstruction, this.lienStatus, this.maturityAmount,
    this.sourceAccount, this.oldAccountNumber, this.accruedInterest,
    this.penaltyAmount, this.taxDeducted, this.netPayout,
    this.destinationAccount, this.closureStatus,
  });
}