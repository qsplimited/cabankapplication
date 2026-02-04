import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/i_device_service.dart';
import '../api/real_device_service.dart';
import '../models/registration_models.dart';
import '../utils/device_id_util.dart';

enum RegistrationStatus { initial, loading, success, failure }

class RegistrationState {
  final int currentStep;
  final RegistrationStatus status;
  final String? errorMessage;
  final String? customerId;
  final String? deviceId;
  final String? tempPassword;

  RegistrationState({
    this.currentStep = 0,
    this.status = RegistrationStatus.initial,
    this.errorMessage,
    this.customerId,
    this.deviceId,
    this.tempPassword,
  });

  RegistrationState copyWith({
    int? currentStep,
    RegistrationStatus? status,
    String? errorMessage,
    String? customerId,
    String? deviceId,
    String? tempPassword,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      customerId: customerId ?? this.customerId,
      deviceId: deviceId ?? this.deviceId,
      tempPassword: tempPassword ?? this.tempPassword,
    );
  }
}

class RegistrationNotifier extends StateNotifier<RegistrationState> {
  final IDeviceService _service;
  final _storage = const FlutterSecureStorage();

  RegistrationNotifier(this._service) : super(RegistrationState());

  void reset() => state = RegistrationState();

  Future<void> loadSavedId() async {
    final savedId = await _storage.read(key: 'last_registered_id');
    if (savedId != null) {
      state = state.copyWith(customerId: savedId);
    }
  }

  // NEW METHOD: Added to resolve 'login is not defined' error
  Future<void> login(String mpin) async {
    state = state.copyWith(status: RegistrationStatus.loading, errorMessage: null);
    try {
      final did = await getUniqueDeviceId();
      // Calls your endpoint: GET /customer/login/bympin
      final response = await _service.loginWithMpin(mpin: mpin, deviceId: did);

      if (response.success) {
        state = state.copyWith(status: RegistrationStatus.success);
      } else {
        state = state.copyWith(
            status: RegistrationStatus.failure,
            errorMessage: response.message
        );
      }
    } catch (e) {
      state = state.copyWith(
          status: RegistrationStatus.failure,
          errorMessage: "Login failed. Please check connection."
      );
    }
  }

  // Unified Identity Check (Step 1)
  Future<void> submitIdentity(String customerId, String password) async {
    state = state.copyWith(status: RegistrationStatus.loading, errorMessage: null);
    try {
      final deviceId = await getUniqueDeviceId();
      final response = await _service.verifyCredentials(
          AuthRequest(customerId: customerId, password: password)
      );

      if (response.success) {
        await _storage.write(key: 'last_registered_id', value: customerId);

        state = state.copyWith(
          status: RegistrationStatus.success,
          currentStep: 1,
          customerId: customerId,
          tempPassword: password,
          deviceId: deviceId,
        );
        await Future.delayed(const Duration(milliseconds: 100));
        state = state.copyWith(status: RegistrationStatus.initial);
      } else {
        state = state.copyWith(status: RegistrationStatus.failure, errorMessage: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: "Connection Error");
    }
  }

  Future<void> verifyOtp(String otp) async {
    final cid = state.customerId;
    if (cid == null) return;

    state = state.copyWith(status: RegistrationStatus.loading);
    try {
      final success = await _service.verifyOtp(otp: otp, customerId: cid, deviceId: state.deviceId ?? "");
      if (success) {
        state = state.copyWith(status: RegistrationStatus.success, currentStep: 2);
      } else {
        state = state.copyWith(status: RegistrationStatus.failure, errorMessage: "Invalid OTP");
      }
    } catch (e) {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: "OTP Verification Failed");
    }
  }

  Future<void> finalizeRegistration(String mpin) async {
    final cid = state.customerId;
    if (cid == null) return;

    state = state.copyWith(status: RegistrationStatus.loading);
    try {
      final res = await _service.finalizeRegistration(
        mpin: mpin,
        customerId: cid,
        deviceId: state.deviceId ?? await getUniqueDeviceId(),
      );

      if (res['success'] == true) {
        state = state.copyWith(status: RegistrationStatus.success, currentStep: 4);
      } else {
        state = state.copyWith(status: RegistrationStatus.failure, errorMessage: res['message']);
      }
    } catch (e) {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: "Failed to set MPIN");
    }
  }
}

final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier(RealDeviceService());
});