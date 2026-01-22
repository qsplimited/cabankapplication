// File: lib/features/tpin/bloc/tpin_event.dart

import 'package:equatable/equatable.dart';

abstract class TpinEvent extends Equatable {
  const TpinEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check T-PIN status
class CheckTpinStatusEvent extends TpinEvent {}

/// Event to update T-PIN (set or change)
class UpdateTpinEvent extends TpinEvent {
  final String newPin;
  final String? oldPin;

  const UpdateTpinEvent({
    required this.newPin,
    this.oldPin,
  });

  @override
  List<Object?> get props => [newPin, oldPin];
}

/// Event to verify mobile number
class VerifyMobileEvent extends TpinEvent {
  final String mobileNumber;

  const VerifyMobileEvent({required this.mobileNumber});

  @override
  List<Object> get props => [mobileNumber];
}

/// Event to request OTP
class RequestOtpEvent extends TpinEvent {}

/// Event to validate OTP
class ValidateOtpEvent extends TpinEvent {
  final String otp;

  const ValidateOtpEvent({required this.otp});

  @override
  List<Object> get props => [otp];
}

/// Event to validate T-PIN
class ValidateTpinEvent extends TpinEvent {
  final String tpin;

  const ValidateTpinEvent({required this.tpin});

  @override
  List<Object> get props => [tpin];
}

/// Event to reset the BLoC state
class ResetTpinStateEvent extends TpinEvent {}

// ============================================================
// File: lib/features/tpin/bloc/tpin_state.dart

abstract class TpinState extends Equatable {
  const TpinState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class TpinInitial extends TpinState {}

/// Loading state
class TpinLoading extends TpinState {}

/// T-PIN status loaded
class TpinStatusLoaded extends TpinState {
  final bool isTpinSet;

  const TpinStatusLoaded({required this.isTpinSet});

  @override
  List<Object> get props => [isTpinSet];
}

/// T-PIN updated successfully
class TpinUpdateSuccess extends TpinState {
  final String message;

  const TpinUpdateSuccess({required this.message});

  @override
  List<Object> get props => [message];
}

/// Mobile verification success
class MobileVerificationSuccess extends TpinState {}

/// OTP requested successfully
class OtpRequestSuccess extends TpinState {
  final String otp;
  final String maskedMobile;

  const OtpRequestSuccess({
    required this.otp,
    required this.maskedMobile,
  });

  @override
  List<Object> get props => [otp, maskedMobile];
}

/// OTP validated successfully
class OtpValidationSuccess extends TpinState {}

/// T-PIN validation result
class TpinValidationResult extends TpinState {
  final bool isValid;

  const TpinValidationResult({required this.isValid});

  @override
  List<Object> get props => [isValid];
}

/// Error state
class TpinError extends TpinState {
  final String message;

  const TpinError({required this.message});

  @override
  List<Object> get props => [message];
}