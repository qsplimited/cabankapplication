import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/banking_service.dart';

enum TpinStateStatus { initial, loading, success, error }

class TpinProcessState {
  final TpinStateStatus status;
  final String? message;
  final String? error;
  final bool isOtpSent;
  final bool isTpinSet;
  final String maskedMobile;

  TpinProcessState({
    this.status = TpinStateStatus.initial,
    this.message,
    this.error,
    this.isOtpSent = false,
    this.isTpinSet = false,
    this.maskedMobile = '',
  });

  TpinProcessState copyWith({
    TpinStateStatus? status, String? message, String? error, bool? isOtpSent, bool? isTpinSet, String? maskedMobile,
  }) {
    return TpinProcessState(
      status: status ?? this.status,
      message: message ?? this.message,
      error: error ?? this.error,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      isTpinSet: isTpinSet ?? this.isTpinSet,
      maskedMobile: maskedMobile ?? this.maskedMobile,
    );
  }
}

class TpinNotifier extends StateNotifier<TpinProcessState> {
  final BankingService _service = BankingService();
  TpinNotifier() : super(TpinProcessState(isTpinSet: BankingService().isTpinSet));

  Future<void> processMobileVerification(String mobile) async {
    state = state.copyWith(status: TpinStateStatus.loading); // Start Loading
    try {
      // 1. Check if number is valid (10 digits)
      if (mobile.length != 10) {
        state = state.copyWith(status: TpinStateStatus.error, error: "Please enter a valid 10-digit number.");
        return;
      }

      // 2. Call the service to check if the account exists
      // Based on your banking_service.dart, this checks against '9876541234'
      final exists = _service.findAccountByMobileNumber(mobile);

      if (exists) {
        // 3. Request the OTP
        final otp = await _service.requestTpinOtp();

        // Update state to move to the next screen
        state = state.copyWith(
          status: TpinStateStatus.initial,
          isOtpSent: true,
          message: "OTP sent to your registered mobile.",
          maskedMobile: _service.getMaskedMobileNumber(), // Get ******1234
        );
      } else {
        state = state.copyWith(
            status: TpinStateStatus.error,
            error: "This mobile number is not registered with us."
        );
      }
    } catch (e) {
      state = state.copyWith(status: TpinStateStatus.error, error: e.toString());
    }
  }

  Future<void> processOtpValidation(String otp) async {
    state = state.copyWith(status: TpinStateStatus.loading);
    try {
      await _service.validateTpinOtp(otp);
      state = state.copyWith(status: TpinStateStatus.success, message: "OTP Verified");
    } catch (e) {
      state = state.copyWith(status: TpinStateStatus.error, error: "Invalid OTP");
    }
  }

  Future<void> submitNewPin({required String newPin, String? oldPin}) async {
    state = state.copyWith(status: TpinStateStatus.loading);
    try {
      final res = await _service.updateTransactionPin(newPin: newPin, oldPin: oldPin);
      state = state.copyWith(status: TpinStateStatus.success, isTpinSet: true, message: res);
    } catch (e) {
      state = state.copyWith(status: TpinStateStatus.error, error: e.toString());
    }
  }

  void resetStatus() => state = state.copyWith(status: TpinStateStatus.initial, error: null);
}

final tpinProvider = StateNotifierProvider<TpinNotifier, TpinProcessState>((ref) => TpinNotifier());