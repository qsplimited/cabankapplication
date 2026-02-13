import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/transaction_history_api_service.dart';
import '../models/transaction_history_model.dart';

final historyApiProvider = Provider((ref) => TransactionHistoryApiService());

final transactionHistoryProvider = FutureProvider.family<List<TransactionHistory>, String>((ref, accountNumber) async {
  return ref.watch(historyApiProvider).fetchHistory(accountNumber);
}); //final;