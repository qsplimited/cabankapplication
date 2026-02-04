/*
import '../api/banking_service.dart';
import '../models/customer_account_model.dart';

class DashboardRepository {
  final BankingService _service;
  DashboardRepository(this._service);

  // Requirement: Fetch accounts only for the specific logged-in customer
  Future<List<CustomerAccount>> getDashboardAccounts(String customerId) async {
    // In your Real API, this will be:
    // final response = await _dio.get('/customer/accounts/$customerId');
    final List<dynamic> data = await _service.fetchRawAccounts(customerId);

    return data.map((json) => CustomerAccount.fromJson(json)).toList();
  }
}*/
