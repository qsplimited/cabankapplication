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

  if (customerId == null) throw Exception("No User Session Found");

  final apiService = ref.read(dashboardApiServiceProvider);

  // 1. Fetch Profile
  final profile = await apiService.fetchAccountDetails(customerId);

  // 2. Fetch Balance using accountNumber (Matches Swagger: ?accountNumber=...)
  // FIX: Use profile.accountNumber instead of profile.savingAccountNumber
  final latestBalance = await apiService.fetchCurrentBalance(profile.accountNumber);

  return profile.copyWith(balance: latestBalance);
});

// Update this to watch the autoDispose provider
final accountDetailProvider = FutureProvider.family.autoDispose<CustomerAccount, String>((ref, id) async {
  return await ref.watch(dashboardAccountProvider.future);
});