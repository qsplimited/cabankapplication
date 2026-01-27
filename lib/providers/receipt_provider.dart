import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt_models.dart';
import '../api/mock_fd_api_service.dart';

// Provider for the API Service
final fdApiServiceProvider = Provider((ref) => MockFdApiService());

// StateNotifier to handle fetching and storing the current receipt
class ReceiptNotifier extends StateNotifier<AsyncValue<DepositReceipt?>> {
  final MockFdApiService _apiService;

  ReceiptNotifier(this._apiService) : super(const AsyncValue.data(null));

  Future<void> fetchReceipt(String type) async {
    state = const AsyncValue.loading();
    try {
      final String mockId = 'TXN-$type-${DateTime.now().millisecondsSinceEpoch}';
      final receipt = await _apiService.fetchDepositReceipt(mockId);
      state = AsyncValue.data(receipt);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Global provider to be used by the UI
final receiptProvider = StateNotifierProvider<ReceiptNotifier, AsyncValue<DepositReceipt?>>((ref) {
  return ReceiptNotifier(ref.watch(fdApiServiceProvider));
});