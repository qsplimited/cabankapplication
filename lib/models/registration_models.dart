class AuthRequest {
  final String customerId;
  final String password;
  AuthRequest({required this.customerId, required this.password});
}

class AuthResponse {
  final bool success;
  final String? message;
  final String? otpCode;
  final String? sessionId; // Crucial for Real API to link steps 1 to 4

  AuthResponse({required this.success, this.message, this.otpCode, this.sessionId});

  // This factory will handle the JSON when you switch to Real API
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      otpCode: json['otp_code'],
      sessionId: json['session_id'],
    );

  }
}