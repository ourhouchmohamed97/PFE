class FieldValidator {
  static String? validateNotEmpty(String? value) {
    if (value == null || value.trim().isEmpty) return 'Field is required';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Invalid email';
    return null;
  }

  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    return null;
  }

  static String? validatePhoneNumber(String? value) {
  if (value == null || value.trim().isEmpty) return 'Phone number is required';
  final phoneRegExp = RegExp(r'^\+?[0-9]{10}$');
  if (!phoneRegExp.hasMatch(value.trim())) {
    return 'Invalid phone number';
  }
  return null;
}

static String? validateSignupPassword(String? value) {
  if (value == null || value.isEmpty) return 'Enter a password';
  if (value.length < 8) return 'Minimum 8 characters';

  final hasUppercase = RegExp(r'[A-Z]');
  final hasLowercase = RegExp(r'[a-z]');
  final hasDigit = RegExp(r'\d');
  final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  if (!hasUppercase.hasMatch(value)) {
    return 'Must include at least one uppercase letter';
  }
  if (!hasLowercase.hasMatch(value)) {
    return 'Must include at least one lowercase letter';
  }
  if (!hasDigit.hasMatch(value)) {
    return 'Must include at least one number';
  }
  if (!hasSpecialChar.hasMatch(value)) {
    return 'Must include at least one special character';
  }

  return null;
}

  static String? confirmPasswordValidator(String? value, String password) {
  if (value == null || value.isEmpty) return 'Please confirm your password';
  if (value != password) return 'Passwords do not match';
  return null;
}
}
