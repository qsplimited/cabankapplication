import 'package:dio/dio.dart';

class TpinApi {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.0.102:8088',
    connectTimeout: const Duration(seconds: 10),
  ));

  Future<Map<String, dynamic>> createTransactionMpin({
    required String accountNumber,
    required String tpin, // Renamed for clarity to match backend
  }) async {
    try {
      // Endpoint: /api/transactions/create-transaction-mpin
      // Parameters: accountNumber and tpin (NOT mpin)
      final response = await _dio.post(
        '/api/transactions/create-transaction-mpin',
        queryParameters: {
          'accountNumber': accountNumber,
          'tpin': tpin, // Fixed key to match backend
        },
      );

      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? "Server Error";
    }
  }
}