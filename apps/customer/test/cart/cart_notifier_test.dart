import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spazalink_core/core.dart';

import 'package:spazalink_customer/features/cart/providers/cart_provider.dart';

class MockCartRepository extends Mock implements CartRepository {}

void main() {
  final _now = DateTime(2026, 1, 1);

  setUpAll(() {
    // Needed by mocktail when using any() / captureAny() with CartItemModel.
    registerFallbackValue(CartItemModel(
      productId: 'fallback',
      shopId: 'fallback',
      productName: 'fallback',
      priceCents: 0,
      quantity: 1,
      addedAt: DateTime(2026),
    ));
  });

  late MockCartRepository mockRepo;
  late ProviderContainer container;

  CartItemModel _item({
    String productId = 'prod-1',
    int priceCents = 2500,
    int quantity = 1,
  }) =>
      CartItemModel(
        productId: productId,
        shopId: 'shop-1',
        productName: 'Coke 2L',
        priceCents: priceCents,
        quantity: quantity,
        addedAt: _now,
      );

  setUp(() {
    mockRepo = MockCartRepository();
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('CartNotifier.addItem', () {
    test('delegates to repository.upsertItem', () async {
      final item = _item();
      when(() => mockRepo.upsertItem(item)).thenAnswer((_) async {});

      await container.read(cartNotifierProvider.notifier).addItem(item);

      verify(() => mockRepo.upsertItem(item)).called(1);
    });
  });

  group('CartNotifier.removeItem', () {
    test('delegates to repository.removeItem', () async {
      when(() => mockRepo.removeItem(
            productId: 'prod-1',
            shopId: 'shop-1',
          )).thenAnswer((_) async {});

      await container.read(cartNotifierProvider.notifier).removeItem(
            productId: 'prod-1',
            shopId: 'shop-1',
          );

      verify(() => mockRepo.removeItem(
            productId: 'prod-1',
            shopId: 'shop-1',
          )).called(1);
    });
  });

  group('CartNotifier.clearCart', () {
    test('delegates to repository.clearCart', () async {
      when(() => mockRepo.clearCart('shop-1')).thenAnswer((_) async {});

      await container
          .read(cartNotifierProvider.notifier)
          .clearCart('shop-1');

      verify(() => mockRepo.clearCart('shop-1')).called(1);
    });
  });

  group('CartNotifier.updateQuantity', () {
    test('calls removeItem when quantity is zero', () async {
      when(() => mockRepo.removeItem(
            productId: 'prod-1',
            shopId: 'shop-1',
          )).thenAnswer((_) async {});

      await container.read(cartNotifierProvider.notifier).updateQuantity(
            productId: 'prod-1',
            shopId: 'shop-1',
            quantity: 0,
          );

      verify(() => mockRepo.removeItem(
            productId: 'prod-1',
            shopId: 'shop-1',
          )).called(1);
      verifyNever(() => mockRepo.upsertItem(any()));
    });

    test('calls removeItem when quantity is negative', () async {
      when(() => mockRepo.removeItem(
            productId: 'prod-1',
            shopId: 'shop-1',
          )).thenAnswer((_) async {});

      await container.read(cartNotifierProvider.notifier).updateQuantity(
            productId: 'prod-1',
            shopId: 'shop-1',
            quantity: -1,
          );

      verify(() => mockRepo.removeItem(
            productId: 'prod-1',
            shopId: 'shop-1',
          )).called(1);
    });

    test('calls upsertItem with new quantity when item exists', () async {
      final existingItem = _item(quantity: 2);
      when(() => mockRepo.getItems('shop-1'))
          .thenAnswer((_) async => [existingItem]);
      when(() => mockRepo.upsertItem(any())).thenAnswer((_) async {});

      await container.read(cartNotifierProvider.notifier).updateQuantity(
            productId: 'prod-1',
            shopId: 'shop-1',
            quantity: 5,
          );

      final captured =
          verify(() => mockRepo.upsertItem(captureAny())).captured;
      final updated = captured.first as CartItemModel;
      expect(updated.quantity, 5);
      expect(updated.productId, 'prod-1');
    });

    test('does nothing when item does not exist in cart', () async {
      when(() => mockRepo.getItems('shop-1'))
          .thenAnswer((_) async => []);

      await container.read(cartNotifierProvider.notifier).updateQuantity(
            productId: 'prod-1',
            shopId: 'shop-1',
            quantity: 3,
          );

      verifyNever(() => mockRepo.upsertItem(any()));
    });
  });
}
