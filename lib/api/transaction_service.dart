import 'package:dio/dio.dart';
import '../models/transaction_response_model.dart';

class TransactionService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:8088'));

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
      throw Exception("Connection Error: $e");
    }
  }


  // Inside your TransactionService class in transaction_service.dart

  Future<String> getRecipientName(String toAccount) async {
    try {
      // Replace with the actual endpoint URL provided by your backend team
      final response = await _dio.get(
        '/api/accounts/get-name',
        queryParameters: {'accountNumber': toAccount},
      );

      if (response.statusCode == 200) {
        // Adjust 'fullName' based on the actual key in their JSON response
        return response.data['fullName'] ?? "Name not found";
      }
      return "Account not found";
    } catch (e) {
      // If the API returns a 404 or error, we show this
      return "Invalid account";
    }
  }


}