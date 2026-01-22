import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/banking_repository.dart';
import 'package:cabankapplication/api/banking_service.dart' as service;

final bankingRepositoryProvider = Provider((ref) => BankingRepository());

final transactionFutureProvider = FutureProvider<List<service.Transaction>>((ref) async {
  return ref.watch(bankingRepositoryProvider).fetchAllTransactions();
});

final accountFutureProvider = FutureProvider<service.Account?>((ref) async {
  return ref.watch(bankingRepositoryProvider).fetchAccountSummary();
});