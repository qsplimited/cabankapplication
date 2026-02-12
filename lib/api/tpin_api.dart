import 'package:dio/dio.dart';
import 'api_constants.dart';

class TpinApi {
  final Dio _dio = Dio(BaseOptions(
    // 2. USE THE CONSTANT: This ensures if your IP changes to .104 or .105 later,
    // you only change it in ONE file (api_constants.dart).
    baseUrl: ApiConstants.baseUrl,
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