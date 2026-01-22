import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/mock_otp_service.dart';

// 1. The State Model (Internal to this file or separate)
class OtpState {
  final int resendSeconds;
  final bool isVerifying;
  final String? errorMessage;

  OtpState({this.resendSeconds = 30, this.isVerifying = false, this.errorMessage});

  OtpState copyWith({int? resendSeconds, bool? isVerifying, String? errorMessage}) {
    return OtpState(
      resendSeconds: resendSeconds ?? this.resendSeconds,
      isVerifying: isVerifying ?? this.isVerifying,
      errorMessage: errorMessage,
    );
  }
}

// 2. The Provider with a String key to separate screen states
final otpProvider = StateNotifierProvider.family<OtpNotifier, OtpState, String>((ref, screenId) {
  return OtpNotifier();
});

class OtpNotifier extends StateNotifier<OtpState> {
  OtpNotifier() : super(OtpState());
  Timer? _timer;
  final OtpService _service = MockOtpService();

  void startTimer() {
    state = state.copyWith(resendSeconds: 30, errorMessage: null);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.resendSeconds > 0) {
        state = state.copyWith(resendSeconds: state.resendSeconds - 1);
      } else {
        t.cancel();
      }
    });
  }

  Future<bool> verify(String mobile, String otp) async {
    state = state.copyWith(isVerifying: true, errorMessage: null);
    try {
      final success = await _service.verifyOtp(mobile, otp);
      state = state.copyWith(isVerifying: false);
      return success;
    } catch (e) {
      state = state.copyWith(isVerifying: false, errorMessage: "Verification failed.");
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}