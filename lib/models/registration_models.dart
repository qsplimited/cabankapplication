class AuthRequest {
  final String customerId;
  final String password;
  AuthRequest({required this.customerId, required this.password});
}

class AuthResponse {
  final bool success;
  final String? message;
  final String? otpCode;
  final String? sessionId;
  final String? token; // This must exist

  AuthResponse({
    required this.success,
    this.message,
    this.otpCode,
    this.sessionId,
    this.token,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      otpCode: json['otp_code'],
      sessionId: json['session_id'],
      token: json['token'],
    );
  }
}