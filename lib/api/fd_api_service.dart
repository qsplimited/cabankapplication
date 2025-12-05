// File: lib/services/fd_api_service.dart (Interface)

import '../models/fd_models.dart';

abstract class FdApiService {
  // Methods that must be implemented:
  Future<SourceAccount> fetchSourceAccount();
  Future<List<DepositScheme>> fetchDepositSchemes();

  // 🌟 UPDATED: Calculate maturity based on inputs
  Future<MaturityDetails> calculateMaturity({
    required double amount,
    required String schemeId,
    required int tenureYears,
    required int tenureMonths,
    required int tenureDays,
    required String nomineeName,
    required String sourceAccountId,
  });

  // Method for confirming the deposit using T-PIN
  Future<FdConfirmationResponse> confirmDeposit({
    required String tpin,
    required double amount,
    required String accountId,
  });
}

// NOTE: MaturityDetails moved to fd_models.dart