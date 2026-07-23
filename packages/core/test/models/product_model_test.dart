import 'package:flutter_test/flutter_test.dart';
import 'package:spazalink_core/core.dart';

void main() {
  final _now = DateTime(2026, 1, 1);

  ProductModel _make({
    int priceCents = 5000,
    int? salePriceCents,
    List<String> imageUrls = const [],
    bool isAvailable = true,
    bool isFeatured = false,
  }) =>
      ProductModel(
        categoryId: 'cat-1',
        name: 'Test Product',
        priceCents: priceCents,
        salePriceCents: salePriceCents,
        imageUrls: imageUrls,
        isAvailable: isAvailable,
        isFeatured: isFeatured,
        createdAt: _now,
        updatedAt: _now,
      );

  group('ProductModel.effectivePriceCents', () {
    test('returns regular price when no sale', () {
      expect(_make(priceCents: 5000).effectivePriceCents, 5000);
    });

    test('returns sale price when set', () {
      expect(
        _make(priceCents: 5000, salePriceCents: 3500).effectivePriceCents,
        3500,
      );
    });
  });

  group('ProductModel.isOnSale', () {
    test('false when no sale price', () {
      expect(_make(priceCents: 5000).isOnSale, isFalse);
    });

    test('true when sale price is less than regular price', () {
      expect(
        _make(priceCents: 5000, salePriceCents: 3500).isOnSale,
        isTrue,
      );
    });

    test('false when sale price equals regular price', () {
      expect(
        _make(priceCents: 5000, salePriceCents: 5000).isOnSale,
        isFalse,
      );
    });

    test('false when sale price is higher than regular price', () {
      expect(
        _make(priceCents: 5000, salePriceCents: 6000).isOnSale,
        isFalse,
      );
    });
  });

  group('ProductModel.primaryImageUrl', () {
    test('returns null when no images', () {
      expect(_make(imageUrls: []).primaryImageUrl, isNull);
    });

    test('returns first url when images present', () {
      expect(
        _make(imageUrls: ['https://img.example.com/a.jpg',
            'https://img.example.com/b.jpg']).primaryImageUrl,
        'https://img.example.com/a.jpg',
      );
    });
  });

  group('ProductModel.fromJson / toJson', () {
    test('round-trips without data loss', () {
      final original = _make(
        priceCents: 12500,
        salePriceCents: 9999,
        imageUrls: ['https://example.com/img.jpg'],
        isAvailable: false,
        isFeatured: true,
      );
      final json = original.toJson();
      final restored = ProductModel.fromJson(json);
      expect(restored, original);
    });

    test('default values apply on minimal JSON', () {
      final product = ProductModel.fromJson({
        'categoryId': 'cat-1',
        'name': 'Bread',
        'priceCents': 2500,
        'createdAt': _now.millisecondsSinceEpoch,
        'updatedAt': _now.millisecondsSinceEpoch,
      });
      expect(product.id, '');
      expect(product.imageUrls, isEmpty);
      expect(product.isAvailable, isTrue);
      expect(product.isFeatured, isFalse);
      expect(product.stockQuantity, 0);
    });
  });
}
