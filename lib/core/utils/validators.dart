/// Generic, reusable form-field validators.
///
/// Each method returns an error message when invalid, or `null` when valid,
/// matching the signature expected by [FormField.validator].
class Validators {
  const Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, fieldName: 'Email');
    if (requiredError != null) return requiredError;
    if (!_emailPattern.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? minLength(String? value, int length, {String fieldName = 'This field'}) {
    final requiredError = required(value, fieldName: fieldName);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < length) {
      return '$fieldName must be at least $length characters';
    }
    return null;
  }

  static String? match(String? value, String? target, {String message = 'Values do not match'}) {
    if (value != target) return message;
    return null;
  }
}
