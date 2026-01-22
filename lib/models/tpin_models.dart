// lib/models/tpin_models.dart

enum TpinStateStatus { initial, loading, success, error }

class TpinProcessState {
  final TpinStateStatus status;
  final String? message;
  final String? error;
  final bool isOtpSent;

  TpinProcessState({
    this.status = TpinStateStatus.initial,
    this.message,
    this.error,
    this.isOtpSent = false,
  });

  TpinProcessState copyWith({
    TpinStateStatus? status,
    String? message,
    String? error,
    bool? isOtpSent,
  }) {
    return TpinProcessState(
      status: status ?? this.status,
      message: message ?? this.message,
      error: error ?? this.error,
      isOtpSent: isOtpSent ?? this.isOtpSent,
    );
  }
}