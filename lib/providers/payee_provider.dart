import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/banking_service.dart';

// Provides the singleton instance of your existing BankingService
final bankingServiceProvider = Provider((ref) => BankingService());

class PayeeNotifier extends StateNotifier<AsyncValue<List<Beneficiary>>> {
  final BankingService _service;

  PayeeNotifier(this._service) : super(const AsyncValue.loading()) {
    _init();
  }

  // Listen to the stream in BankingService to auto-refresh UI on changes
  void _init() {
    refresh();
    _service.onDataUpdate.listen((_) => refresh());
  }

  Future<void> refresh() async {
    try {
      final list = await _service.fetchBeneficiaries();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> delete(String id) async {
    await _service.deleteBeneficiary(id);
    // refresh() is called automatically via the listener above
  }

  Future<void> save(AddBeneficiaryPayload payload, {String? existingId}) async {
    if (existingId != null) {
      await _service.updateBeneficiary(existingId, payload);
    } else {
      await _service.addBeneficiary(payload);
    }
  }
}

final payeeProvider = StateNotifierProvider<PayeeNotifier, AsyncValue<List<Beneficiary>>>((ref) {
  return PayeeNotifier(ref.watch(bankingServiceProvider));
});