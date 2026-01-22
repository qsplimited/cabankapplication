import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/banking_service.dart' as service;
import '../api/dashboard_repository.dart'; // Ensure correct path

// 1. Repository instance provider
final dashboardRepoProvider = Provider((ref) => DashboardRepository(service.BankingService()));

// 2. Fetches the list for the Dashboard slider
final dashboardAccountsProvider = FutureProvider<List<service.Account>>((ref) {
  return ref.watch(dashboardRepoProvider).getDashboardAccounts();
});

// 3. NEW: Fetches specific details for the Detail Screen
// Pass the accountId to this provider to get one specific account
final accountDetailProvider = FutureProvider.family<service.Account, String>((ref, accountId) async {
  // We reuse the list already loaded in dashboardAccountsProvider
  final allAccounts = await ref.watch(dashboardAccountsProvider.future);

  return allAccounts.firstWhere(
        (acc) => acc.accountId == accountId,
    orElse: () => throw Exception('Account with ID $accountId not found'),
  );
});

// 4. Fetches User Profile (Arjun Reddy)
final userProfileProvider = FutureProvider<service.UserProfile>((ref) {
  return ref.watch(dashboardRepoProvider).getProfile();
});