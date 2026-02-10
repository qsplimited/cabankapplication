import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'registration_provider.dart'; // Ensure this contains your logged-in customerId
import '../api/dashboard_api_service.dart';
import '../models/customer_account_model.dart';

// 1. Instance of the Real API Service
final dashboardApiServiceProvider = Provider((ref) => DashboardApiService());



// 2. Main Account Provider
// This watches the registration state. If customerId changes, it re-fetches.
final dashboardAccountProvider = FutureProvider<CustomerAccount>((ref) async {
  // Pull the real ID (e.g., "A-0046") from your login state
  final authState = ref.watch(registrationProvider);
  final customerId = authState.customerId;

  if (customerId == null) {
    throw Exception("No User Session Found. Please Login.");
  }

  // Fetch from the real API using the ID
  return ref.read(dashboardApiServiceProvider).fetchAccountDetails(customerId);
});

// 3. Detail Provider for the Detailed Screen
// We use a family provider so we can pass the customerId from the UI
final accountDetailProvider = FutureProvider.family<CustomerAccount, String>((ref, id) async {
  // Simply returns the data already fetched in the main provider
  return await ref.watch(dashboardAccountProvider.future);
});