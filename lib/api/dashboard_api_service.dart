import 'package:dio/dio.dart';
import '../models/customer_account_model.dart';

class DashboardApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.0.102:8088',
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
          'accountNumber': accountNumber,
          '_t': DateTime.now().millisecondsSinceEpoch, // FORCES server to give fresh data
        },
      );

      if (res.statusCode == 200 && res.data is List && res.data.isNotEmpty) {
        // res.data[0] is the latest transaction from your Swagger output
        return double.tryParse(res.data[0]['currentBalance'].toString()) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}