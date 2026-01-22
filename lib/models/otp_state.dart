// lib/models/otp_state.dart

class OtpState {
  final int resendSeconds;
  final bool isVerifying;
  final String? errorMessage;
  final bool isSuccess;

  OtpState({
    this.resendSeconds = 30,
    this.isVerifying = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  OtpState copyWith({
    int? resendSeconds,
    bool? isVerifying,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return OtpState(
      resendSeconds: resendSeconds ?? this.resendSeconds,
      isVerifying: isVerifying ?? this.isVerifying,
      errorMessage: errorMessage, // We allow this to be null to clear errors
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}