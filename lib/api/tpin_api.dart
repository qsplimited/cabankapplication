import 'package:dio/dio.dart';

class TpinApi {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.0.102:8088',
    connectTimeout: const Duration(seconds: 10),
  ));

  Future<Map<String, dynamic>> createTransactionMpin({
    required String accountNumber,
    required String mpin,
  }) async {
    try {
      // This matches your curl: POST to URL?accountNumber=X&mpin=Y
      final response = await _dio.post(
        '/api/transactions/create-transaction-mpin',
        queryParameters: {
          'accountNumber': accountNumber,
          'mpin': mpin,
        },
      );

      return response.data;
    } on DioException catch (e) {
      // Handling specific Dio errors
      throw e.response?.data['message'] ?? "Server Error";
    }
  }
}