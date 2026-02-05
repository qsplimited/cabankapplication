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

  Future<double> fetchCurrentBalance(String accountNumber) async {
    try {
      final res = await _dio.get('/api/transactions/history', queryParameters: {'accountNumber': accountNumber});
      if (res.statusCode == 200 && res.data is List && res.data.isNotEmpty) {
        // Pulls the latest currentBalance from the first transaction object
        return double.tryParse(res.data[0]['currentBalance'].toString()) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }
}