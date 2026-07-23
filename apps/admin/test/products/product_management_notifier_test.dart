import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spazalink_core/core.dart';

import 'package:spazalink_admin/features/products/providers/product_provider.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository mockRepo;
  late ProviderContainer container;

  final _now = DateTime(2026, 1, 1);

  ProductModel _product({String id = 'prod-1'}) => ProductModel(
        id: id,
        categoryId: 'cat-1',
        name: 'Test Product',
        priceCents: 5000,
        createdAt: _now,
        updatedAt: _now,
      );

  setUp(() {
    mockRepo = MockProductRepository();
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    registerFallbackValue(_product());
  });

  tearDown(() => container.dispose());

  group('ProductManagementNotifier initial state', () {
    test('starts as ProductManagementIdle', () {
      expect(
        container.read(productManagementProvider),
        isA<ProductManagementIdle>(),
      );
    });
  });

  group('ProductManagementNotifier.create', () {
    test('transitions to Loading then Success', () async {
      final product = _product(id: '');
      when(() => mockRepo.createProduct(any()))
          .thenAnswer((_) async => product.copyWith(id: 'server-id-1'));

      final states = <ProductManagementState>[];
      final sub = container.listen(
          productManagementProvider, (_, next) => states.add(next));

      await container
          .read(productManagementProvider.notifier)
          .create(product);

      sub.close();

      expect(states.first, isA<ProductManagementLoading>());
      expect(states.last, isA<ProductManagementSuccess>());
      expect(
        (states.last as ProductManagementSuccess).message,
        contains('created'),
      );
    });

    test('goes to Error when repo throws', () async {
      when(() => mockRepo.createProduct(any()))
          .thenThrow(Exception('quota exceeded'));

      await container
          .read(productManagementProvider.notifier)
          .create(_product(id: ''));

      expect(
        container.read(productManagementProvider),
        isA<ProductManagementError>(),
      );
    });
  });

  group('ProductManagementNotifier.update', () {
    test('transitions to Success when update succeeds', () async {
      when(() => mockRepo.updateProduct(any())).thenAnswer((_) async {});

      await container
          .read(productManagementProvider.notifier)
          .update(_product());

      expect(
        container.read(productManagementProvider),
        isA<ProductManagementSuccess>(),
      );
      verify(() => mockRepo.updateProduct(any())).called(1);
    });

    test('transitions to Error when update fails', () async {
      when(() => mockRepo.updateProduct(any()))
          .thenThrow(Exception('permission denied'));

      await container
          .read(productManagementProvider.notifier)
          .update(_product());

      expect(
        container.read(productManagementProvider),
        isA<ProductManagementError>(),
      );
    });
  });

  group('ProductManagementNotifier.delete', () {
    test('transitions to Success when delete succeeds', () async {
      when(() => mockRepo.deleteProduct('prod-1')).thenAnswer((_) async {});

      await container
          .read(productManagementProvider.notifier)
          .delete('prod-1');

      expect(
        container.read(productManagementProvider),
        isA<ProductManagementSuccess>(),
      );
      verify(() => mockRepo.deleteProduct('prod-1')).called(1);
    });

    test('transitions to Error when delete fails', () async {
      when(() => mockRepo.deleteProduct('prod-1'))
          .thenThrow(Exception('not found'));

      await container
          .read(productManagementProvider.notifier)
          .delete('prod-1');

      expect(
        container.read(productManagementProvider),
        isA<ProductManagementError>(),
      );
    });
  });

  group('ProductManagementNotifier.updateStock', () {
    test('calls repository with correct args', () async {
      when(() => mockRepo.updateStock(
            productId: 'prod-1',
            quantity: 50,
          )).thenAnswer((_) async {});

      await container
          .read(productManagementProvider.notifier)
          .updateStock(productId: 'prod-1', quantity: 50);

      verify(() => mockRepo.updateStock(
            productId: 'prod-1',
            quantity: 50,
          )).called(1);
      expect(
        container.read(productManagementProvider),
        isA<ProductManagementSuccess>(),
      );
    });
  });

  group('ProductManagementNotifier.reset', () {
    test('returns to Idle', () async {
      when(() => mockRepo.deleteProduct('prod-1')).thenAnswer((_) async {});
      await container
          .read(productManagementProvider.notifier)
          .delete('prod-1');
      expect(
        container.read(productManagementProvider),
        isA<ProductManagementSuccess>(),
      );

      container.read(productManagementProvider.notifier).reset();
      expect(
        container.read(productManagementProvider),
        isA<ProductManagementIdle>(),
      );
    });
  });
}
