// File: lib/models/receipt_models.dart

import 'fd_models.dart'; // To use SourceAccount/DepositScheme if needed, or common types

// ----------------------------------------------------------------------------
// Model for a single Recurring Deposit (RD) installment payment
// ----------------------------------------------------------------------------
class PaymentInstallment {
  final DateTime paymentDate;
  final double amount;
  final String status; // e.g., 'Success', 'Failed', 'Scheduled'
  final String transactionId;
  final int installmentNumber;

  PaymentInstallment({
    required this.paymentDate,
    required this.amount,
    required this.status,
    required this.transactionId,
    required this.installmentNumber,
  });
}

// ----------------------------------------------------------------------------
// Model for the final Deposit Receipt (Used by both FD and RD)
// ----------------------------------------------------------------------------
class DepositReceipt {
  final String accountType; // 'FD' or 'RD'
  final double amount; // Initial FD amount OR first RD installment amount
  final String newAccountNumber; // The deposit account number
  final String transactionId; // The master transaction ID for the deposit creation
  final DateTime depositDate;
  final String tenureDescription; // e.g., '5 Years, 0 Months' or '2 Years, 6 Months'
  final double interestRate;
  final String nomineeName;
  final String maturityDate;
  final double maturityAmount;
  final String schemeName;

  // Specific to RD: history of payments (null for FD)
  final List<PaymentInstallment>? paymentHistory;

  // Specific to FD: T-PIN for withdrawal (for mock purposes)
  final String? tpin;

  DepositReceipt({
    required this.accountType,
    required this.amount,
    required this.newAccountNumber,
    required this.transactionId,
    required this.depositDate,
    required this.tenureDescription,
    required this.interestRate,
    required this.nomineeName,
    required this.maturityDate,
    required this.maturityAmount,
    required this.schemeName,
    this.paymentHistory,
    this.tpin,
  });
}

// Mock data needed for the APIs
const String mockTransactionIdFd = 'FD-TXN-167253';
const String mockTransactionIdRd = 'RD-TXN-987654';