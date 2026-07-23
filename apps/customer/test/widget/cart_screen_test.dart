import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spazalink_core/core.dart';

import 'package:spazalink_customer/features/auth/providers/auth_provider.dart';
import 'package:spazalink_customer/features/cart/providers/cart_provider.dart';
import 'package:spazalink_customer/features/cart/screens/cart_screen.dart';

class MockCartRepository extends Mock implements CartRepository {}

GoRouter _router(Widget screen) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => screen),
      ],
    );

ShopModel _shop() => ShopModel(
      id: 'shop-1',
      ownerId: 'owner-1',
      shopName: 'Test Shop',
      ownerName: 'Test Owner',
      physicalAddress: '1 Main St, Soweto',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

CartItemModel _item({
  String productId = 'prod-1',
  String name = 'Sunflower Oil 2L',
  int priceCents = 3500,
  int quantity = 2,
}) =>
    CartItemModel(
      productId: productId,
      shopId: 'shop-1',
      productName: name,
      priceCents: priceCents,
      quantity: quantity,
      addedAt: DateTime(2026),
    );

Future<void> _pumpCart(
  WidgetTester tester, {
  List<CartItemModel> items = const [],
  bool loading = false,
}) async {
  final mockRepo = MockCartRepository();
  when(() => mockRepo.watchItems(any()))
      .thenAnswer((_) => Stream.value(items));
  when(() => mockRepo.clearCart(any())).thenAnswer((_) async {});

  final shop = _shop();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        cartRepositoryProvider.overrideWithValue(mockRepo),
        // currentShopProvider is FutureProvider<ShopModel?> — override returns the value
        currentShopProvider.overrideWith((ref) async => shop),
        // Override the family provider for 'shop-1'
        cartItemsProvider('shop-1').overrideWith(
          (ref) => loading
              ? const Stream.empty() // stays in loading
              : Stream.value(items),
        ),
        cartNotifierProvider.overrideWith(CartNotifier.new),
      ],
      child: MaterialApp.router(
        routerConfig: _router(const CartScreen()),
      ),
    ),
  );
  // Pump async providers
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('CartScreen — empty state', () {
    testWidgets('shows empty cart message when cart has no items',
        (tester) async {
      await _pumpCart(tester, items: []);
      expect(find.text('Your cart is empty'), findsOneWidget);
    });

    testWidgets('does not show Clear button when cart is empty',
        (tester) async {
      await _pumpCart(tester, items: []);
      expect(find.text('Clear'), findsNothing);
    });
  });

  group('CartScreen — populated state', () {
    testWidgets('shows product names for all cart items', (tester) async {
      await _pumpCart(tester, items: [
        _item(name: 'Sunflower Oil 2L'),
        _item(productId: 'prod-2', name: 'Coca-Cola 24×330ml'),
      ]);
      expect(find.text('Sunflower Oil 2L'), findsOneWidget);
      expect(find.text('Coca-Cola 24×330ml'), findsOneWidget);
    });

    testWidgets('shows Clear button when cart has items', (tester) async {
      await _pumpCart(tester, items: [_item()]);
      expect(find.text('Clear'), findsOneWidget);
    });

    testWidgets('shows My Cart title in AppBar', (tester) async {
      await _pumpCart(tester, items: [_item()]);
      expect(find.text('My Cart'), findsOneWidget);
    });
  });
}
