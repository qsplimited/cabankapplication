class AppValidators {
  static String? validateCustomerId(String? value) {
    if (value == null || value.trim().isEmpty) return 'Customer ID is required';
    final regExp = RegExp(r'^[A-Z][0-9]{4}$');
    if (!regExp.hasMatch(value.trim().replaceAll(' ', ''))) {
      return 'Format: 1 Capital Letter + 4 Digits (e.g. A0001)';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 4) return 'Password too short';
    return null;
  }
}