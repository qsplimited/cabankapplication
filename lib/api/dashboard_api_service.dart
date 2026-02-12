import 'package:dio/dio.dart';
import '../models/customer_account_model.dart';
import 'api_constants.dart';


class DashboardApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl, // <--- USE CONSTANT
  ));

  Future<CustomerAccount> fetchAccountDetails(String customerId) async {
    try {
      final response = await _dio.get('/customer/get/by/cstmrid', queryParameters: {'customerId': customerId});
      return CustomerAccount.fromJson(response.data);
    } catch (e) {
      throw Exception("Profile fetch failed");
    }
  }

// lib/api/dashboard_api_service.dart

// lib/api/dashboard_api_service.dart

// lib/api/dashboard_api_service.dart

  Future<double> fetchCurrentBalance(String accountNumber) async {
    try {
      final res = await _dio.get(
          '/api/transactions/history',
          queryParameters: {
            'accountNumber': accountNumber, // Matches your Swagger key
            '_t': DateTime.now().millisecondsSinceEpoch,
          }
      );

      if (res.statusCode == 200 && res.data is List && res.data.isNotEmpty) {
        // Many backends append new transactions to the END.
        // We pick the very last transaction to get the most recent balance.
        final latestTransaction = res.data.last;
        return double.tryParse(latestTransaction['currentBalance'].toString()) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}