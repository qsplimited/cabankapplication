// lib/providers/deposit_opening_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deposit_account.dart';
import '../models/fd_models.dart';

// 1. Define the State for the Opening Flow
class DepositOpeningState {
  final SourceAccount? sourceAccount;
  final Nominee? selectedNominee;
  final bool isTermsAccepted;
  final bool isLoading;

  DepositOpeningState({
    this.sourceAccount,
    this.selectedNominee,
    this.isTermsAccepted = false,
    this.isLoading = false,
  });

  DepositOpeningState copyWith({
    SourceAccount? sourceAccount,
    Nominee? selectedNominee,
    bool? isTermsAccepted,
    bool? isLoading,
  }) {
    return DepositOpeningState(
      sourceAccount: sourceAccount ?? this.sourceAccount,
      selectedNominee: selectedNominee ?? this.selectedNominee,
      isTermsAccepted: isTermsAccepted ?? this.isTermsAccepted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 2. The Notifier
class DepositOpeningNotifier extends StateNotifier<DepositOpeningState> {
  DepositOpeningNotifier() : super(DepositOpeningState());

  void setSourceAccount(SourceAccount account) {
    state = state.copyWith(sourceAccount: account);
  }

  void updateNominee(Nominee nominee) {
    state = state.copyWith(selectedNominee: nominee);
  }

  void toggleTerms(bool value) {
    state = state.copyWith(isTermsAccepted: value);
  }

  void reset() {
    state = DepositOpeningState();
  }
}

// 3. The Global Provider
final depositOpeningProvider = StateNotifierProvider<DepositOpeningNotifier, DepositOpeningState>((ref) {
  return DepositOpeningNotifier();
});