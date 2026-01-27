import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/fd_models.dart';
import '../models/rd_models.dart';
import '../models/nominee_model.dart';

class RdOpeningState {
  final NomineeModel? selectedNominee;
  final bool isTermsAccepted;
  final RdMaturityDetails? maturityDetails;

  RdOpeningState({
    this.selectedNominee,
    this.isTermsAccepted = false,
    this.maturityDetails,
  });

  RdOpeningState copyWith({
    NomineeModel? selectedNominee,
    bool? isTermsAccepted,
    RdMaturityDetails? maturityDetails,
  }) {
    return RdOpeningState(
      selectedNominee: selectedNominee ?? this.selectedNominee,
      isTermsAccepted: isTermsAccepted ?? this.isTermsAccepted,
      maturityDetails: maturityDetails ?? this.maturityDetails,
    );
  }
}

class RdOpeningNotifier extends StateNotifier<RdOpeningState> {
  RdOpeningNotifier() : super(RdOpeningState());

  void selectNominee(NomineeModel nominee) {
    state = state.copyWith(selectedNominee: nominee);
  }

  void setTerms(bool accepted) {
    state = state.copyWith(isTermsAccepted: accepted);
  }

  void setMaturity(RdMaturityDetails? details) {
    state = state.copyWith(maturityDetails: details);
  }
}

final rdOpeningProvider = StateNotifierProvider<RdOpeningNotifier, RdOpeningState>((ref) {
  return RdOpeningNotifier();
});