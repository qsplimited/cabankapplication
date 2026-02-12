import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/profile_api_service.dart';
import '../models/customer_account_model.dart';

final profileApiProvider = Provider((ref) => ProfileApiService());

// This provider is now dynamic and fetches data based on the provided customerId
final profileProvider = FutureProvider.family<CustomerAccount, String>((ref, customerId) async {
  return ref.watch(profileApiProvider).getCustomerProfile(customerId);
});