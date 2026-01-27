import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/nominee_model.dart';

class FdOpeningState {
  final NomineeModel? selectedNominee;
  final bool isTermsAccepted;

  FdOpeningState({this.selectedNominee, this.isTermsAccepted = false});

  FdOpeningState copyWith({NomineeModel? selectedNominee, bool? isTermsAccepted}) {
    return FdOpeningState(
      selectedNominee: selectedNominee ?? this.selectedNominee,
      isTermsAccepted: isTermsAccepted ?? this.isTermsAccepted,
    );
  }
}

class FdOpeningNotifier extends StateNotifier<FdOpeningState> {
  FdOpeningNotifier() : super(FdOpeningState());

  void selectNominee(NomineeModel nominee) {
    // FORCE 100% - No editing allowed
    state = state.copyWith(
      selectedNominee: nominee.copyWith(sharePercentage: 100.0),
    );
  }

  void setTerms(bool value) => state = state.copyWith(isTermsAccepted: value);
}

final fdOpeningProvider = StateNotifierProvider<FdOpeningNotifier, FdOpeningState>((ref) => FdOpeningNotifier());