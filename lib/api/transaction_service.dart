import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_response_model.dart';
import '../models/account_details_model.dart'; // Ensure this exists for mapping

import 'api_constants.dart';

// Global provider for the service
final transServiceProvider = Provider((ref) => TransactionService());

class TransactionService {
  // 2. CHANGE THIS: Use the constant instead of .102
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
  ));

  Future<AccountDetails> getAccountDetails(String accountNumber) async {
    try {
      final response = await _dio.get(
        '/api/transactions/get/accountdtl',
        queryParameters: {'accountNumber': accountNumber},
      );

      if (response.statusCode == 200) {
        // This maps the response where 'currentBalance' is inside the history
        return AccountDetails.fromJson(response.data);
      } else {
        throw Exception("Failed to fetch account details");
      }
    } on DioException catch (e) {
      throw Exception("Network Error: ${e.message}");
    } catch (e) {
      throw Exception("Data Error: $e");
    }
  }

  // --- EXISTING METHODS ---
  Future<String> getRecipientName(String toAccount) async {
    try {
      final response = await _dio.get(
        '/api/transactions/get/accountdtl',
        queryParameters: {'accountNumber': toAccount},
      );

      if (response.statusCode == 200) {
        final data = response.data['value'];
        return data['accountHolderName'] ?? "Unknown Payee";
      }
      return "Account not found";
    } catch (e) {
      return "Invalid account number";
    }
  }

  Future<TransactionResponse> transferFunds({
    required String fromAcc,
    required String toAcc,
    required double amount,
    required String mpin,
  }) async {
    try {
      final response = await _dio.post(
        '/api/transactions/transfer',
        queryParameters: {
          'fromAccountNumber': fromAcc,
          'toAccountNumber': toAcc,
          'amount': amount,
          'transactionMpin': mpin,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransactionResponse.fromJson(response.data);
      } else {
        throw Exception(response.data['message'] ?? "Transfer Failed");
      }
    } catch (e) {
      throw Exception("Connection Error: Please check your network.");
    }
  }
}