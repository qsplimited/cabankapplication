import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/customer_account_model.dart';

class DashboardApiService {
  final String baseUrl = "http://192.168.0.102:8088";

  Future<CustomerAccount> fetchAccountDetails(String customerId) async {
    final url = Uri.parse("$baseUrl/customer/get/by/cstmrid?customerId=$customerId");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return CustomerAccount.fromJson(json.decode(response.body));
      } else {
        throw Exception("API Error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Connection Error: $e");
    }
  }

  // FIXED: Robust balance fetcher
  Future<double> fetchCurrentBalance(String customerId) async {
    final url = Uri.parse("$baseUrl/transactions/balance?customerId=$customerId");

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // This checks all common JSON paths for the balance field
        final dynamic rawValue = data['currentBalance'] ??
            data['value']?['currentBalance'] ??
            data['data']?['currentBalance'];

        if (rawValue == null) return 0.0;

        // Convert anything (String/Int/Double) to a double safely
        return double.tryParse(rawValue.toString()) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      debugPrint("Balance Fetch Error: $e");
      return 0.0;
    }
  }
}