import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/mock_device_service.dart';
import '../models/registration_models.dart';

enum RegistrationStatus { initial, loading, success, failure }

class RegistrationState {
  final int currentStep;
  final RegistrationStatus status;
  final String? errorMessage;
  final String? sessionId;
  final bool isResetFlow;

  RegistrationState({
    this.currentStep = 0,
    this.status = RegistrationStatus.initial,
    this.errorMessage,
    this.sessionId,
    this.isResetFlow = false,
  });

  RegistrationState copyWith({
    int? currentStep,
    RegistrationStatus? status,
    String? errorMessage,
    String? sessionId,
    bool? isResetFlow,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionId: sessionId ?? this.sessionId,
      isResetFlow: isResetFlow ?? this.isResetFlow,
    );
  }
}

// Correct Provider Definition
final deviceServiceProvider = Provider<MockDeviceService>((ref) => MockDeviceService());

final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  final service = ref.watch(deviceServiceProvider);
  return RegistrationNotifier(service);
});

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final MockDeviceService _service;
  final _storage = const FlutterSecureStorage();

  RegistrationNotifier(this._service) : super(RegistrationState());

  void reset() => state = RegistrationState();

  // FIX: Added setupMpin so Step 3 screen doesn't error
  void setupMpin(String mpin) => finalizeRegistration(mpin);

  Future<void> login(String mpin) async {
    state = state.copyWith(status: RegistrationStatus.loading);
    final response = await _service.loginWithMpin(mpin: mpin);

    if (response.success) {
      if (response.token != null) {
        await _storage.write(key: 'auth_token', value: response.token);
      }
      state = state.copyWith(status: RegistrationStatus.success);
    } else {
      state = state.copyWith(
        status: RegistrationStatus.failure,
        errorMessage: response.message ?? "Invalid MPIN",
      );
    }
  }

  Future<void> submitIdentity(String custId, String pass) async {
    state = state.copyWith(status: RegistrationStatus.loading, isResetFlow: false);
    final res = await _service.verifyCredentials(AuthRequest(customerId: custId, password: pass));
    if (res.success) {
      state = state.copyWith(status: RegistrationStatus.initial, currentStep: 1, sessionId: res.sessionId);
    } else {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: res.message);
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(status: RegistrationStatus.loading);
    final ok = await _service.verifyOtp(otp: otp, sessionId: state.sessionId);
    if (ok) {
      state = state.copyWith(status: RegistrationStatus.initial, currentStep: 2);
    } else {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: "Invalid OTP");
    }
  }

  Future<void> resendOtp() async {
    try {
      await _service.requestOtp(sessionId: state.sessionId ?? "");
    } catch (e) {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: "Resend failed");
    }
  }

  Future<void> finalizeRegistration(String mpin) async {
    state = state.copyWith(status: RegistrationStatus.loading);
    final res = await _service.finalizeRegistration(
        mpin: mpin,
        deviceId: "DEV_PHONE_001",
        sessionId: state.sessionId
    );

    if (res['success'] == true) {
      await _storage.write(key: 'is_device_bound', value: 'true');
      state = state.copyWith(status: RegistrationStatus.success, currentStep: 4);
    } else {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: "Binding failed");
    }
  }

  Future<void> submitResetIdentity(String custId, String pass) async {
    state = state.copyWith(status: RegistrationStatus.loading, isResetFlow: true);
    final res = await _service.verifyIdentityForReset(AuthRequest(customerId: custId, password: pass));
    if (res.success) {
      state = state.copyWith(status: RegistrationStatus.initial, currentStep: 1, sessionId: res.sessionId);
    } else {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: res.message);
    }
  }
}