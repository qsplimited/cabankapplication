class AuthRequest {
  final String customerId;
  final String password;

  AuthRequest({required this.customerId, required this.password});

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'password': password,
  };
}

class AuthResponse {
  final bool success;
  final String? message;
  final String? token;

  AuthResponse({required this.success, this.message, this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] == true ||
          json['status'] == "Success" ||
          json['success']?.toString().toLowerCase() == "true",
      message: json['message'] ?? json['statusMessage'],
      token: json['token'],
    );
  }
}