import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/customer_account_model.dart';
import 'api_constants.dart';


class ProfileApiService {
  // If using a physical device, replace 'localhost' with your machine's IP address
  final String baseUrl = ApiConstants.baseUrl;

  Future<CustomerAccount> getCustomerProfile(String customerId) async {
    final url = Uri.parse('$baseUrl/customer/get/by/cstmrid?customerId=$customerId');

    try {
      final response = await http.get(url, headers: {'accept': '*/*'});

      if (response.statusCode == 200) {
        return CustomerAccount.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load profile for user: $customerId');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
}