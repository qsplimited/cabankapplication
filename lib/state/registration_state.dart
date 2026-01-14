import 'package:equatable/equatable.dart';

enum RegistrationStatus { initial, loading, success, failure }

class RegistrationState extends Equatable {
  final int currentStep;
  final RegistrationStatus status;
  final String? errorMessage;
  final String customerId; // Defined
  final String password;
  final String otp;
  final String mpin;
  final String? sessionId;
  final bool isResetFlow;

  const RegistrationState({
    this.currentStep = 0,
    this.status = RegistrationStatus.initial,
    this.errorMessage,
    this.customerId = '', // Initialized
    this.password = '',
    this.otp = '',
    this.mpin = '',
    this.sessionId,
    this.isResetFlow = false,
  });

  RegistrationState copyWith({
    int? currentStep,
    RegistrationStatus? status,
    String? errorMessage,
    String? customerId, // Parameter added
    String? password,
    String? otp,
    String? mpin,
    String? sessionId,
    bool? isResetFlow,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      customerId: customerId ?? this.customerId, // Logic added
      password: password ?? this.password,
      otp: otp ?? this.otp,
      mpin: mpin ?? this.mpin,
      sessionId: sessionId ?? this.sessionId,
      isResetFlow: isResetFlow ?? this.isResetFlow,
    );
  }

  @override
  List<Object?> get props => [
    currentStep,
    status,
    errorMessage,
    customerId,
    password,
    otp,
    mpin,
    sessionId,
    isResetFlow
  ];
}