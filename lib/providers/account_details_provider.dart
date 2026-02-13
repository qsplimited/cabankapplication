// lib/providers/account_details_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/transaction_service.dart';
import '../models/account_details_model.dart';
import '../providers/dashboard_provider.dart';

// Create a provider for the service itself if you haven't already
final transServiceProvider = Provider((ref) => TransactionService());

final accountDetailsRefreshProvider = FutureProvider.autoDispose<AccountDetails>((ref) async {
  // 1. Get account number from the dashboard state
  final accountData = await ref.watch(dashboardAccountProvider.future);
  final accountNumber = accountData.accountNumber;


  final transactionService = ref.read(transServiceProvider);
  return await transactionService.getAccountDetails(accountNumber);
});