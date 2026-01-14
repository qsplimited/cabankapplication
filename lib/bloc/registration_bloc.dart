import 'package:flutter_bloc/flutter_bloc.dart';
import '../event/registration_event.dart';
import '../state/registration_state.dart';
import '../main.dart';
import '../models/registration_models.dart';
import '../utils/device_id_util.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc() : super(const RegistrationState()) {

    // 1. IDENTITY STEP
    on<IdentitySubmitted>((event, emit) async {
      emit(state.copyWith(status: RegistrationStatus.loading, isResetFlow: false));
      final res = await globalDeviceService.verifyCredentials(
          AuthRequest(customerId: event.customerId, password: event.password)
      );

      if (res.success) {
        emit(state.copyWith(
          status: RegistrationStatus.initial,
          currentStep: 1,
          sessionId: res.sessionId,
          customerId: event.customerId, // Works now
          password: event.password,
        ));
      } else {
        emit(state.copyWith(status: RegistrationStatus.failure, errorMessage: "Invalid Credentials"));
      }
    });

    on<ResetIdentitySubmitted>((event, emit) async {
      emit(state.copyWith(status: RegistrationStatus.loading, isResetFlow: true));
      final res = await globalDeviceService.verifyIdentityForReset(
          AuthRequest(customerId: event.customerId, password: event.password)
      );

      if (res.success) {
        emit(state.copyWith(
          status: RegistrationStatus.initial,
          currentStep: 1,
          sessionId: res.sessionId,
          customerId: event.customerId, // Works now
        ));
      } else {
        emit(state.copyWith(status: RegistrationStatus.failure, errorMessage: "Reset Verification Failed"));
      }
    });

    // 2. OTP STEP
    on<OtpVerified>((event, emit) async {
      emit(state.copyWith(status: RegistrationStatus.loading));
      final bool success = await globalDeviceService.verifyOtp(
        otp: event.otp,
        sessionId: state.sessionId,
      );

      if (success) {
        emit(state.copyWith(
          status: RegistrationStatus.initial,
          currentStep: 2,
          otp: event.otp, // Works now
        ));
      } else {
        emit(state.copyWith(status: RegistrationStatus.failure, errorMessage: "Invalid OTP"));
      }
    });

    // 3. MPIN STEP
// Inside RegistrationBloc constructor
    on<MpinSetupTriggered>((event, emit) async {
      emit(state.copyWith(status: RegistrationStatus.loading));

      final deviceId = await getUniqueDeviceId();

      // 1. Call your service
      final result = await globalDeviceService.finalizeRegistration(
        mpin: event.mpin,
        deviceId: deviceId,
        sessionId: state.sessionId,
      );

      if (result['success']) {
        // 2. MODIFICATION: This is where you would eventually save a 'Success Token'
        // if your real API returns one.
        // await yourSecureStorage.write(key: 'registration_complete', value: 'true');

        emit(state.copyWith(
          status: RegistrationStatus.success,
          currentStep: 3, // This tells Step 4 to show the success checkmark
          mpin: event.mpin,
        ));
      } else {
        emit(state.copyWith(
            status: RegistrationStatus.failure,
            errorMessage: result['message'] ?? "Binding Failed"
        ));
      }
    });
  }
}