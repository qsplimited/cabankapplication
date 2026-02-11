import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'registration_provider.dart';
import '../api/dashboard_api_service.dart';
import '../models/customer_account_model.dart';

// 1. Instance of the Real API Service
final dashboardApiServiceProvider = Provider((ref) => DashboardApiService());

// 2. Main Account Provider
// Updated to chain profile and balance endpoints for a single source of truth
// lib/providers/dashboard_provider.dart

// lib/providers/dashboard_provider.dart

// Use autoDispose so it can be refreshed easily
final dashboardAccountProvider = FutureProvider.autoDispose<CustomerAccount>((ref) async {
  final authState = ref.watch(registrationProvider);
  final customerId = authState.customerId;

  if (customerId == null) throw Exception("No Session");

  final apiService = ref.read(dashboardApiServiceProvider);

  // 1. Get the profile
  final profile = await apiService.fetchAccountDetails(customerId);

  // 2. Get the NEW balance from the history endpoint you showed earlier
  // This is what will pull the 19,000
  final latestBalance = await apiService.fetchCurrentBalance(profile.savingAccountNumber);

  // 3. Return the merged data
  return profile.copyWith(balance: latestBalance);
});

// Update this to watch the autoDispose provider
final accountDetailProvider = FutureProvider.family.autoDispose<CustomerAccount, String>((ref, id) async {
  return await ref.watch(dashboardAccountProvider.future);
});