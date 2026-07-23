import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:spazalink_core/core.dart';

import 'package:spazalink_admin/features/orders/providers/order_provider.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late MockOrderRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockOrderRepository();
    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('OrderActionNotifier initial state', () {
    test('starts as OrderActionIdle', () {
      expect(container.read(orderActionProvider), isA<OrderActionIdle>());
    });
  });

  group('OrderActionNotifier.updateStatus', () {
    test('transitions to Loading then Success on success', () async {
      when(() => mockRepo.updateOrderStatus(
            orderId: 'order-1',
            status: OrderStatus.confirmed,
            adminId: null,
          )).thenAnswer((_) async {});

      final states = <OrderActionState>[];
      final sub = container.listen(
          orderActionProvider, (_, next) => states.add(next));

      await container.read(orderActionProvider.notifier).updateStatus(
            orderId: 'order-1',
            status: OrderStatus.confirmed,
          );

      sub.close();

      expect(states.first, isA<OrderActionLoading>());
      expect(states.last, isA<OrderActionSuccess>());
    });

    test('transitions to Loading then Error on failure', () async {
      when(() => mockRepo.updateOrderStatus(
            orderId: 'order-1',
            status: OrderStatus.confirmed,
            adminId: null,
          )).thenThrow(Exception('Firestore error'));

      final states = <OrderActionState>[];
      final sub = container.listen(
          orderActionProvider, (_, next) => states.add(next));

      await container.read(orderActionProvider.notifier).updateStatus(
            orderId: 'order-1',
            status: OrderStatus.confirmed,
          );

      sub.close();

      expect(states.first, isA<OrderActionLoading>());
      expect(states.last, isA<OrderActionError>());
      final err = states.last as OrderActionError;
      expect(err.message, contains('Firestore error'));
    });

    test('passes adminId to repository when provided', () async {
      when(() => mockRepo.updateOrderStatus(
            orderId: 'order-1',
            status: OrderStatus.preparing,
            adminId: 'admin-uid-001',
          )).thenAnswer((_) async {});

      await container.read(orderActionProvider.notifier).updateStatus(
            orderId: 'order-1',
            status: OrderStatus.preparing,
            adminId: 'admin-uid-001',
          );

      verify(() => mockRepo.updateOrderStatus(
            orderId: 'order-1',
            status: OrderStatus.preparing,
            adminId: 'admin-uid-001',
          )).called(1);
    });
  });

  group('OrderActionNotifier.cancel', () {
    test('transitions to Success when cancel succeeds', () async {
      when(() => mockRepo.cancelOrder('order-2')).thenAnswer((_) async {});

      await container
          .read(orderActionProvider.notifier)
          .cancel('order-2');

      expect(container.read(orderActionProvider), isA<OrderActionSuccess>());
      verify(() => mockRepo.cancelOrder('order-2')).called(1);
    });

    test('transitions to Error when cancel fails', () async {
      when(() => mockRepo.cancelOrder('order-2'))
          .thenThrow(Exception('permission denied'));

      await container
          .read(orderActionProvider.notifier)
          .cancel('order-2');

      expect(container.read(orderActionProvider), isA<OrderActionError>());
    });
  });

  group('OrderActionNotifier.reset', () {
    test('returns to Idle from Success', () async {
      when(() => mockRepo.cancelOrder('order-x'))
          .thenAnswer((_) async {});
      await container
          .read(orderActionProvider.notifier)
          .cancel('order-x');
      expect(container.read(orderActionProvider), isA<OrderActionSuccess>());

      container.read(orderActionProvider.notifier).reset();
      expect(container.read(orderActionProvider), isA<OrderActionIdle>());
    });

    test('returns to Idle from Error', () async {
      when(() => mockRepo.cancelOrder('order-x'))
          .thenThrow(Exception('fail'));
      await container
          .read(orderActionProvider.notifier)
          .cancel('order-x');
      expect(container.read(orderActionProvider), isA<OrderActionError>());

      container.read(orderActionProvider.notifier).reset();
      expect(container.read(orderActionProvider), isA<OrderActionIdle>());
    });
  });
}
