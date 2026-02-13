import 'package:dio/dio.dart';
import '../models/transaction_history_model.dart';
import '../api/api_constants.dart';

class TransactionHistoryApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
  ));

  Future<List<TransactionHistory>> fetchHistory(String accountNumber) async {
    try {
      final response = await _dio.get(
        '/api/transactions/history',
        queryParameters: {'accountNumber': accountNumber},
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => TransactionHistory.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load history");
      }
    } catch (e) {
      throw Exception("API Error: $e");
    }
  }
}