abstract class RegistrationEvent {}

class IdentitySubmitted extends RegistrationEvent {
  final String customerId;
  final String password;
  IdentitySubmitted(this.customerId, this.password);
}

class OtpVerified extends RegistrationEvent {
  final String otp;
  OtpVerified(this.otp);
}

class MpinSetupTriggered extends RegistrationEvent {
  final String mpin;
  MpinSetupTriggered(this.mpin);
}

class ResetIdentitySubmitted extends RegistrationEvent {
  final String customerId;
  final String password;
  ResetIdentitySubmitted(this.customerId, this.password);
}