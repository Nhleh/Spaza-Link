import 'package:flutter_test/flutter_test.dart';
import 'package:spazalink_core/core.dart';

void main() {
  final _now = DateTime(2026, 1, 1);

  CartItemModel _make({
    int priceCents = 1000,
    int? salePriceCents,
    int quantity = 1,
  }) =>
      CartItemModel(
        productId: 'prod-1',
        shopId: 'shop-1',
        productName: 'Test Product',
        priceCents: priceCents,
        salePriceCents: salePriceCents,
        quantity: quantity,
        addedAt: _now,
      );

  group('CartItemModel.effectivePriceCents', () {
    test('returns regular price when no sale price', () {
      expect(_make(priceCents: 5000).effectivePriceCents, 5000);
    });

    test('returns sale price when set', () {
      expect(
        _make(priceCents: 5000, salePriceCents: 3999).effectivePriceCents,
        3999,
      );
    });
  });

  group('CartItemModel.lineTotalCents', () {
    test('single unit uses effective price', () {
      expect(_make(priceCents: 2500, quantity: 1).lineTotalCents, 2500);
    });

    test('multiplies effective price by quantity', () {
      expect(_make(priceCents: 2500, quantity: 4).lineTotalCents, 10000);
    });

    test('uses sale price when computing line total', () {
      expect(
        _make(priceCents: 5000, salePriceCents: 3000, quantity: 3)
            .lineTotalCents,
        9000,
      );
    });
  });

  group('CartItemModel.fromJson / toJson', () {
    test('round-trips without data loss', () {
      final original = _make(
        priceCents: 3500,
        salePriceCents: 2999,
        quantity: 2,
      );
      final json = original.toJson();
      final restored = CartItemModel.fromJson(json);
      expect(restored, original);
    });

    test('fromJson parses int timestamp', () {
      final ts = _now.millisecondsSinceEpoch;
      final item = CartItemModel.fromJson({
        'productId': 'p1',
        'shopId': 's1',
        'productName': 'Coke',
        'priceCents': 1500,
        'quantity': 1,
        'addedAt': ts,
      });
      expect(item.addedAt, _now);
    });

    test('fromJson parses ISO string timestamp', () {
      final item = CartItemModel.fromJson({
        'productId': 'p1',
        'shopId': 's1',
        'productName': 'Coke',
        'priceCents': 1500,
        'quantity': 1,
        'addedAt': '2026-01-01T00:00:00.000',
      });
      expect(item.addedAt.year, 2026);
    });
  });
}
