// File: lib/api/rd_api_service.dart (Abstract)

import '../models/fd_models.dart';
import '../models/rd_models.dart';

import '../models/receipt_models.dart';

abstract class RdApiService {
  Future<SourceAccount> fetchSourceAccount();
  Future<List<DepositScheme>> fetchDepositSchemes();
  Future<RdMaturityDetails> calculateMaturity({
    required double installmentAmount,
    required String schemeId,
    required int tenureYears,
    required int tenureMonths,
    required int tenureDays,
    required String nomineeName,
    required String sourceAccountId,
    required String frequencyMode,
  });

  Future<String> submitRdDeposit({
    required RdInputData inputData,
    required RdMaturityDetails maturityDetails,
  });

  // 🌟 NEW METHOD: Fetch a complete receipt by its transaction ID
  Future<DepositReceipt> fetchDepositReceipt(String transactionId);
}