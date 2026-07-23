import 'package:flutter_test/flutter_test.dart';
import 'package:spazalink_core/core.dart';

void main() {
  group('Validators.phone', () {
    test('accepts standard 10-digit local number', () {
      expect(Validators.phone('0821234567'), isNull);
    });

    test('accepts number with spaces', () {
      expect(Validators.phone('082 123 4567'), isNull);
    });

    test('accepts +27 international format', () {
      expect(Validators.phone('+27821234567'), isNull);
    });

    test('rejects empty', () {
      expect(Validators.phone(''), isNotNull);
    });

    test('rejects too short', () {
      expect(Validators.phone('0821234'), isNotNull);
    });

    test('rejects letters', () {
      expect(Validators.phone('082ABCDEFG'), isNotNull);
    });
  });

  group('Validators.email (optional)', () {
    test('accepts valid email', () {
      expect(Validators.email('shop@example.co.za'), isNull);
    });

    test('rejects missing @', () {
      expect(Validators.email('shopexample.co.za'), isNotNull);
    });

    test('accepts empty (email is optional)', () {
      expect(Validators.email(''), isNull);
    });
  });

  group('Validators.requiredEmail', () {
    test('rejects empty', () {
      expect(Validators.requiredEmail(''), isNotNull);
    });

    test('accepts valid email', () {
      expect(Validators.requiredEmail('shop@example.co.za'), isNull);
    });
  });

  group('Validators.password', () {
    test('accepts 8+ char password', () {
      expect(Validators.password('Passw0rd!'), isNull);
    });

    test('rejects short password', () {
      expect(Validators.password('abc'), isNotNull);
    });

    test('rejects empty', () {
      expect(Validators.password(''), isNotNull);
    });
  });

  group('Validators.minimumOrder', () {
    test('returns null when total meets minimum', () {
      expect(Validators.minimumOrder(AppConstants.minOrderCents), isNull);
    });

    test('returns null when total exceeds minimum', () {
      expect(Validators.minimumOrder(AppConstants.minOrderCents + 1), isNull);
    });

    test('returns error when total is below minimum', () {
      expect(
          Validators.minimumOrder(AppConstants.minOrderCents - 1), isNotNull);
    });

    test('returns error for zero total', () {
      expect(Validators.minimumOrder(0), isNotNull);
    });
  });

  group('Validators.shopName', () {
    test('accepts valid shop name', () {
      expect(Validators.shopName('Mama Thembi Spaza'), isNull);
    });

    test('rejects empty', () {
      expect(Validators.shopName(''), isNotNull);
    });

    test('rejects name too short', () {
      expect(Validators.shopName('AB'), isNotNull);
    });
  });
}
