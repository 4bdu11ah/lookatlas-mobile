import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/features/auth/domain/validators/auth_validators.dart';

void main() {
  group('AuthValidators.isValidEmail', () {
    const valid = [
      'jane@example.com',
      'jane.doe+tag@sub.example.co.uk',
      '  padded@example.com  ', // trimmed before matching
    ];
    const invalid = [
      '',
      'not-an-email',
      'missing-domain@',
      '@missing-local.com',
      'no-tld@example',
      'two@@example.com',
      'spaces in@example.com',
    ];

    for (final email in valid) {
      test('accepts "$email"', () {
        expect(AuthValidators.isValidEmail(email), isTrue);
        expect(AuthValidators.validateEmail(email), isNull);
      });
    }

    for (final email in invalid) {
      test('rejects "$email"', () {
        expect(AuthValidators.isValidEmail(email), isFalse);
        expect(
          AuthValidators.validateEmail(email),
          'Please enter a valid email address.',
        );
      });
    }

    test('rejects null form input', () {
      expect(
        AuthValidators.validateEmail(null),
        'Please enter a valid email address.',
      );
    });
  });

  group('AuthValidators.isValidPassword', () {
    test('minimum length is 8', () {
      expect(AuthValidators.minPasswordLength, 8);
    });

    const cases = {
      '': false,
      '1234567': false, // 7 chars, one short
      '12345678': true, // exactly at the minimum
      'a much longer passphrase': true,
    };

    for (final MapEntry(key: password, value: expected) in cases.entries) {
      test('"$password" -> $expected', () {
        expect(AuthValidators.isValidPassword(password), expected);
        expect(
          AuthValidators.validatePassword(password),
          expected ? isNull : 'Password must be at least 8 characters.',
        );
      });
    }

    test('rejects null form input', () {
      expect(
        AuthValidators.validatePassword(null),
        'Password must be at least 8 characters.',
      );
    });
  });
}
