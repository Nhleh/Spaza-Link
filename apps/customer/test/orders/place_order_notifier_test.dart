import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spazalink_core/core.dart';

import 'package:spazalink_customer/features/cart/providers/cart_provider.dart';
import 'package:spazalink_customer/features/orders/providers/order_provider.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockCartRepository mockCart;
  late MockOrderRepository mockOrder;
  late ProviderContainer container;

  final _now = DateTime(2026, 1, 1);

  CartItemModel _cartItem({
    String productId = 'prod-1',
    int priceCents = 30000,
    int quantity = 2,
  }) =>
      CartItemModel(
        productId: productId,
        shopId: 'shop-1',
        productName: 'Sunflower Oil 2L',
        priceCents: priceCents,
        quantity: quantity,
        addedAt: _now,
      );

  // A placed order returned by the mock repo
  OrderModel _placedOrder(String uuid) => OrderModel(
        id: 'firestore-id-001',
        localUuid: uuid,
        orderNumber: 'SL-001',
        shopId: 'shop-1',
        customerId: 'cust-1',
        items: [],
        subtotalCents: 60000,
        deliveryFeeCents: 13500,
        totalCents: 73500,
        deliveryAddress: '1 Main St, Soweto',
        syncStatus: SyncStatus.synced,
        placedAt: _now,
        createdAt: _now,
        updatedAt: _now,
      );

  setUp(() {
    mockCart = MockCartRepository();
    mockOrder = MockOrderRepository();
    container = ProviderContainer(
      overrides: [
        cartRepositoryProvider.overrideWithValue(mockCart),
        orderRepositoryProvider.overrideWithValue(mockOrder),
      ],
    );

    // Stub registerFallback for OrderModel (needed by mocktail)
    registerFallbackValue(
      OrderModel(
        localUuid: 'fallback',
        shopId: '',
        customerId: '',
        items: [],
        subtotalCents: 0,
        deliveryFeeCents: 0,
        totalCents: 0,
        deliveryAddress: '',
        placedAt: _now,
        createdAt: _now,
        updatedAt: _now,
      ),
    );
  });

  tearDown(() => container.dispose());

  group('PlaceOrderNotifier initial state', () {
    test('starts as PlaceOrderIdle', () {
      expect(
        container.read(placeOrderProvider),
        isA<PlaceOrderIdle>(),
      );
    });
  });

  group('PlaceOrderNotifier.place — success path', () {
    test('transitions to Loading then Success', () async {
      final item = _cartItem();
      when(() => mockCart.getItems('shop-1'))
          .thenAnswer((_) async => [item]);
      when(() => mockOrder.placeOrder(any()))
          .thenAnswer((inv) async => _placedOrder(
              (inv.positionalArguments[0] as OrderModel).localUuid));
      when(() => mockCart.clearCart('shop-1')).thenAnswer((_) async {});

      final states = <PlaceOrderState>[];
      final sub =
          container.listen(placeOrderProvider, (_, next) => states.add(next));

      await container.read(placeOrderProvider.notifier).place(
            shopId: 'shop-1',
            customerId: 'cust-1',
            deliveryAddress: '1 Main St, Soweto',
            paymentMethod: PaymentMethod.cod,
          );

      sub.close();

      expect(states.first, isA<PlaceOrderLoading>());
      expect(states.last, isA<PlaceOrderSuccess>());
      final success = states.last as PlaceOrderSuccess;
      expect(success.order.id, 'firestore-id-001');
    });

    test('clears cart after successful placement', () async {
      final item = _cartItem();
      when(() => mockCart.getItems('shop-1'))
          .thenAnswer((_) async => [item]);
      when(() => mockOrder.placeOrder(any()))
          .thenAnswer((inv) async => _placedOrder(
              (inv.positionalArguments[0] as OrderModel).localUuid));
      when(() => mockCart.clearCart('shop-1')).thenAnswer((_) async {});

      await container.read(placeOrderProvider.notifier).place(
            shopId: 'shop-1',
            customerId: 'cust-1',
            deliveryAddress: '1 Main St, Soweto',
            paymentMethod: PaymentMethod.cod,
          );

      verify(() => mockCart.clearCart('shop-1')).called(1);
    });

    test('calculates free delivery for subtotal >= R1750', () async {
      // 6 × R30 = R180 subtotal → but we need >= R1750
      // Use 2 × R1000 items = R2000 subtotal → free delivery
      final bigItem = _cartItem(priceCents: 100000, quantity: 2);
      when(() => mockCart.getItems('shop-1'))
          .thenAnswer((_) async => [bigItem]);

      OrderModel? capturedOrder;
      when(() => mockOrder.placeOrder(any())).thenAnswer((inv) async {
        capturedOrder = inv.positionalArguments[0] as OrderModel;
        return capturedOrder!.copyWith(id: 'id-001', syncStatus: SyncStatus.synced);
      });
      when(() => mockCart.clearCart('shop-1')).thenAnswer((_) async {});

      await container.read(placeOrderProvider.notifier).place(
            shopId: 'shop-1',
            customerId: 'cust-1',
            deliveryAddress: 'addr',
            paymentMethod: PaymentMethod.cod,
          );

      expect(capturedOrder?.subtotalCents, 200000);
      expect(capturedOrder?.deliveryFeeCents, 0);
      expect(capturedOrder?.totalCents, 200000);
    });

    test('applies R135 delivery fee for subtotal < R1750', () async {
      // 2 × R300 = R600 subtotal → R135 delivery
      final item = _cartItem(priceCents: 30000, quantity: 2);
      when(() => mockCart.getItems('shop-1'))
          .thenAnswer((_) async => [item]);

      OrderModel? capturedOrder;
      when(() => mockOrder.placeOrder(any())).thenAnswer((inv) async {
        capturedOrder = inv.positionalArguments[0] as OrderModel;
        return capturedOrder!.copyWith(id: 'id-001', syncStatus: SyncStatus.synced);
      });
      when(() => mockCart.clearCart('shop-1')).thenAnswer((_) async {});

      await container.read(placeOrderProvider.notifier).place(
            shopId: 'shop-1',
            customerId: 'cust-1',
            deliveryAddress: 'addr',
            paymentMethod: PaymentMethod.cod,
          );

      expect(capturedOrder?.deliveryFeeCents, AppConstants.deliveryFeeCents);
    });
  });

  group('PlaceOrderNotifier.place — offline fallback', () {
    test('saves pending order and succeeds when Firestore throws', () async {
      final item = _cartItem();
      when(() => mockCart.getItems('shop-1'))
          .thenAnswer((_) async => [item]);
      when(() => mockOrder.placeOrder(any()))
          .thenThrow(Exception('No network'));
      when(() => mockOrder.savePendingOrder(any()))
          .thenAnswer((_) async {});
      when(() => mockCart.clearCart('shop-1')).thenAnswer((_) async {});

      await container.read(placeOrderProvider.notifier).place(
            shopId: 'shop-1',
            customerId: 'cust-1',
            deliveryAddress: '1 Main St',
            paymentMethod: PaymentMethod.cod,
          );

      final state = container.read(placeOrderProvider);
      expect(state, isA<PlaceOrderSuccess>());
      final success = state as PlaceOrderSuccess;
      expect(success.order.syncStatus, SyncStatus.local);

      verify(() => mockOrder.savePendingOrder(any())).called(1);
    });
  });

  group('PlaceOrderNotifier.place — error path', () {
    test('goes to PlaceOrderError when cart is empty', () async {
      when(() => mockCart.getItems('shop-1'))
          .thenAnswer((_) async => []);

      await container.read(placeOrderProvider.notifier).place(
            shopId: 'shop-1',
            customerId: 'cust-1',
            deliveryAddress: 'addr',
            paymentMethod: PaymentMethod.cod,
          );

      expect(container.read(placeOrderProvider), isA<PlaceOrderError>());
      final err = container.read(placeOrderProvider) as PlaceOrderError;
      expect(err.message, contains('empty'));
    });
  });

  group('PlaceOrderNotifier.reset', () {
    test('returns to PlaceOrderIdle', () async {
      // force an error state first
      when(() => mockCart.getItems('shop-1')).thenAnswer((_) async => []);
      await container.read(placeOrderProvider.notifier).place(
            shopId: 'shop-1',
            customerId: 'cust-1',
            deliveryAddress: 'addr',
            paymentMethod: PaymentMethod.cod,
          );
      expect(container.read(placeOrderProvider), isA<PlaceOrderError>());

      container.read(placeOrderProvider.notifier).reset();
      expect(container.read(placeOrderProvider), isA<PlaceOrderIdle>());
    });
  });
}
