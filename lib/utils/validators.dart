class AppValidators {
  /// Validates Customer ID (Strict Format: 1 Letter, 1 Dash, 4 Digits e.g., B-0026)
  static String? validateCustomerId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Customer ID is required';
    }

    // UPDATED REGEX:
    // ^[A-Za-z] : Exactly one letter at the start
    // -        : Exactly one dash
    // [0-9]{4}$ : Exactly four digits at the end
    final regExp = RegExp(r'^[A-Za-z]-[0-9]{4}$');

    if (!regExp.hasMatch(value.trim())) {
      return 'Required Format: Letter-4Digits (e.g. B-0026)';
    }
    return null;
  }

  /// Validates Password (Usha@123 style)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';

    final hasUppercase = value.contains(RegExp(r'[A-Z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));
    final hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    if (!hasUppercase || !hasDigits || !hasSpecial) {
      return 'Use Uppercase, Numbers, and a Symbol (e.g. @)';
    }
    return null;
  }
}