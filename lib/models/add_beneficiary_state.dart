// File: lib/models/add_beneficiary_state.dart
class AddBeneficiaryState {
  final bool isVerifying;
  final bool isSaving;
  final String? detectedBank; // Nullable
  final String? error;

  AddBeneficiaryState({
    this.isVerifying = false,
    this.isSaving = false,
    this.detectedBank,
    this.error,
  });

  AddBeneficiaryState copyWith({
    bool? isVerifying,
    bool? isSaving,
    String? detectedBank,
    String? error,
  }) {
    return AddBeneficiaryState(
      isVerifying: isVerifying ?? this.isVerifying,
      isSaving: isSaving ?? this.isSaving,
      detectedBank: detectedBank ?? this.detectedBank,
      error: error,
    );
  }
}