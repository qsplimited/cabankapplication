import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quick_transfer_state.dart';
import '../api/quick_transfer_service.dart';
import '../api/banking_service.dart';

final quickTransferProvider = StateNotifierProvider<QuickTransferNotifier, QuickTransferState>((ref) {
  return QuickTransferNotifier(QuickTransferApiService());
});

class QuickTransferNotifier extends StateNotifier<QuickTransferState> {
  final QuickTransferApiService _api;
  QuickTransferNotifier(this._api) : super(QuickTransferState()) {
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final list = await _api.fetchDebitAccounts();
    state = state.copyWith(accounts: list, selectedAccount: list.isNotEmpty ? list.first : null);
  }

  void selectAccount(Account? acc) {
    state = state.copyWith(selectedAccount: acc, verifiedRecipient: null, errorMessage: null);
  }

  Future<void> verifyRecipient(String acc, String confirmAcc, String ifsc) async {
    if (acc.isEmpty || confirmAcc.isEmpty || ifsc.isEmpty) {
      state = state.copyWith(errorMessage: "Please fill all recipient fields.");
      return;
    }
    if (acc != confirmAcc) {
      state = state.copyWith(errorMessage: "Account numbers do not match.");
      return;
    }
    state = state.copyWith(isVerifyingRecipient: true, errorMessage: null);
    try {
      final details = await _api.verifyRecipient(acc, ifsc);
      state = state.copyWith(isVerifyingRecipient: false, verifiedRecipient: details);
    } catch (e) {
      state = state.copyWith(isVerifyingRecipient: false, errorMessage: "Verification failed. Check A/C or IFSC.");
    }
  }

  Future<String?> validateTransfer(String amountStr) async {
    final amount = double.tryParse(amountStr) ?? 0;
    final balance = state.selectedAccount?.balance ?? 0;

    // YOUR CONDITION: Fail if balance is insufficient
    if (amount > balance) {
      state = state.copyWith(errorMessage: "Transfer amount exceeds available balance (₹${balance.toStringAsFixed(2)})");
      return null;
    }
    return await _api.getRegisteredMobile();
  }
}