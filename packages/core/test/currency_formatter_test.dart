import 'package:flutter_test/flutter_test.dart';
import 'package:spazalink_core/core.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats zero cents', () {
      expect(CurrencyFormatter.format(0), 'R0.00');
    });

    test('formats whole rands', () {
      expect(CurrencyFormatter.format(10000), 'R100.00');
    });

    test('formats rands and cents', () {
      expect(CurrencyFormatter.format(2450), 'R24.50');
    });

    test('formats large amounts', () {
      expect(CurrencyFormatter.format(1750000), 'R17,500.00');
    });

    test('formatDeliveryFee returns FREE for zero', () {
      expect(CurrencyFormatter.formatDeliveryFee(0), 'FREE');
    });

    test('formatDeliveryFee returns formatted amount for non-zero', () {
      expect(CurrencyFormatter.formatDeliveryFee(13500), 'R135.00');
    });

    test('randsToCents converts correctly', () {
      expect(CurrencyFormatter.randsToCents(135.0), 13500);
    });

    test('randsToCents rounds half-cent correctly', () {
      expect(CurrencyFormatter.randsToCents(0.995), 100);
    });
  });

  group('CentsExtension', () {
    test('deliveryFee is R135 below free threshold', () {
      expect(174999.deliveryFee, AppConstants.deliveryFeeCents);
    });

    test('deliveryFee is FREE at exact threshold', () {
      expect(AppConstants.freeDeliveryThresholdCents.deliveryFee, 0);
    });

    test('deliveryFee is FREE above threshold', () {
      expect(200000.deliveryFee, 0);
    });

    test('isFreeDelivery true at threshold', () {
      expect(AppConstants.freeDeliveryThresholdCents.isFreeDelivery, isTrue);
    });

    test('isFreeDelivery false below threshold', () {
      expect(174999.isFreeDelivery, isFalse);
    });

    test('meetsMinimumOrder true at minimum', () {
      expect(AppConstants.minOrderCents.meetsMinimumOrder, isTrue);
    });

    test('meetsMinimumOrder false below minimum', () {
      expect(49999.meetsMinimumOrder, isFalse);
    });
  });
}
