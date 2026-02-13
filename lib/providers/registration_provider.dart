import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/i_device_service.dart';
import '../api/real_device_service.dart';
import '../models/registration_models.dart';
import '../utils/device_id_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // --- KEY METHOD: Lock the gate after navigation ---
  void resetStatus() {
    state = state.copyWith(status: RegistrationStatus.initial, errorMessage: null);
  }

  void reset() => state = RegistrationState();

  // --- LOGIN VERIFICATION (For Dashboard Use) ---
// registration_provider.dart

  Future<void> login(String mpin) async {
    state = state.copyWith(status: RegistrationStatus.loading, errorMessage: null);
    try {
      final did = await getUniqueDeviceId();
      final response = await _service.loginWithMpin(mpin: mpin, deviceId: did);

      // CRITICAL: Ensure we only set success if response.success is strictly TRUE
      if (response.success == true) {
        state = state.copyWith(status: RegistrationStatus.success);
      } else {
        // If server says false, we MUST set failure to stop navigation
        state = state.copyWith(
            status: RegistrationStatus.failure,
            errorMessage: response.message ?? "Incorrect Login PIN"
        );
      }
    } catch (e) {
      state = state.copyWith(
          status: RegistrationStatus.failure,
          errorMessage: "Connection failed. Please check your internet."
      );
    }
  }
// registration_provider.dart (Relevant Part)


  // --- NEW: FORGOT MPIN TRIGGER ---
  Future<void> forgotMpinTrigger(String customerId) async {
    state = state.copyWith(status: RegistrationStatus.loading, errorMessage: null);
    try {
      final deviceId = await getUniqueDeviceId();

      // This call will now work because we updated i_device_service.dart
      final response = await _service.sendOtpByCustomerId(customerId);

      if (response.success) {
        state = state.copyWith(
          status: RegistrationStatus.success,
          currentStep: 1, // This tells the app we are now at the OTP step
          customerId: customerId,
          deviceId: deviceId,
        );
      } else {
        state = state.copyWith(status: RegistrationStatus.failure, errorMessage: response.message);
      }
    } catch (e) {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: "Connection Error");
    }
  }
  // --- OTHER METHODS ---
  Future<void> loadSavedId() async {
    final savedId = await _storage.read(key: 'last_registered_id');
    if (savedId != null) state = state.copyWith(customerId: savedId);
  }

  Future<void> submitIdentity(String customerId, String password) async {
    state = state.copyWith(status: RegistrationStatus.loading, errorMessage: null);
    try {
      final deviceId = await getUniqueDeviceId(); //

      // Call the existing login endpoint.
      // Sending an empty password here matches your web team's "Forgot" logic.
      final response = await _service.verifyCredentials(
          AuthRequest(customerId: customerId, password: password)
      ); //

      if (response.success) {
        await _storage.write(key: 'last_registered_id', value: customerId); //

        // Update state to success and move to Step 1 (OTP Step)
        state = state.copyWith(
            status: RegistrationStatus.success,
            currentStep: 1,
            customerId: customerId,
            deviceId: deviceId
        );
      } else {
        state = state.copyWith(status: RegistrationStatus.failure, errorMessage: response.message); //
      }
    } catch (e) {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: "Connection Error"); //
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
      final res = await _service.finalizeRegistration(mpin: mpin, customerId: cid, deviceId: state.deviceId ?? await getUniqueDeviceId());
      if (res['success'] == true) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_customer_id', cid);
        await prefs.setBool('is_registered', true);
        state = state.copyWith(status: RegistrationStatus.success, currentStep: 4);
      } else {
        state = state.copyWith(status: RegistrationStatus.failure, errorMessage: res['message'] ?? "Finalization Failed");
      }
    } catch (e) {
      state = state.copyWith(status: RegistrationStatus.failure, errorMessage: "Connection Error");
    }
  }
}



final registrationProvider = StateNotifierProvider<RegistrationNotifier, RegistrationState>((ref) {
  return RegistrationNotifier(RealDeviceService());
});