import 'package:digital_vault/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.required', () {
    test('rejects null and empty/whitespace values', () {
      expect(Validators.required(null), isNotNull);
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('   '), isNotNull);
    });

    test('accepts a non-empty value', () {
      expect(Validators.required('hello'), isNull);
    });

    test('includes the custom field name in the message', () {
      expect(Validators.required('', fieldName: 'Full Name'), contains('Full Name'));
    });
  });

  group('Validators.email', () {
    test('rejects empty value', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejects malformed addresses', () {
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('missing@domain'), isNotNull);
      expect(Validators.email('@nolocal.com'), isNotNull);
    });

    test('accepts a well-formed address', () {
      expect(Validators.email('user@example.com'), isNull);
    });
  });

  group('Validators.minLength', () {
    test('rejects empty and too-short values', () {
      expect(Validators.minLength('', 8), isNotNull);
      expect(Validators.minLength('short', 8), isNotNull);
    });

    test('accepts a value meeting the minimum', () {
      expect(Validators.minLength('longenough', 8), isNull);
    });
  });

  group('Validators.match', () {
    test('rejects differing values with the default message', () {
      expect(Validators.match('abc', 'xyz'), 'Values do not match');
    });

    test('accepts identical values', () {
      expect(Validators.match('abc', 'abc'), isNull);
    });

    test('uses a custom message when provided', () {
      expect(Validators.match('abc', 'xyz', message: 'Passwords do not match'),
          'Passwords do not match');
    });
  });
}
