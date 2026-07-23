import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spazalink_core/core.dart';

import 'package:spazalink_customer/features/orders/widgets/order_status_badge.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('OrderStatusMeta.label', () {
    test('returns human-readable labels for all known statuses', () {
      expect(OrderStatusMeta.label(OrderStatus.pending), 'Pending');
      expect(OrderStatusMeta.label(OrderStatus.confirmed), 'Confirmed');
      expect(OrderStatusMeta.label(OrderStatus.preparing), 'Preparing');
      expect(OrderStatusMeta.label(OrderStatus.outForDelivery), 'On the Way');
      expect(OrderStatusMeta.label(OrderStatus.delivered), 'Delivered');
      expect(OrderStatusMeta.label(OrderStatus.cancelled), 'Cancelled');
    });

    test('falls back to raw status string for unknown value', () {
      expect(OrderStatusMeta.label('unknown_status'), 'unknown_status');
    });
  });

  group('OrderStatusMeta.isFinal', () {
    test('delivered is final', () {
      expect(OrderStatusMeta.isFinal(OrderStatus.delivered), isTrue);
    });

    test('cancelled is final', () {
      expect(OrderStatusMeta.isFinal(OrderStatus.cancelled), isTrue);
    });

    test('pending is not final', () {
      expect(OrderStatusMeta.isFinal(OrderStatus.pending), isFalse);
    });

    test('preparing is not final', () {
      expect(OrderStatusMeta.isFinal(OrderStatus.preparing), isFalse);
    });
  });

  group('OrderStatusMeta.canCancel', () {
    test('pending can be cancelled', () {
      expect(OrderStatusMeta.canCancel(OrderStatus.pending), isTrue);
    });

    test('confirmed can be cancelled', () {
      expect(OrderStatusMeta.canCancel(OrderStatus.confirmed), isTrue);
    });

    test('preparing cannot be cancelled', () {
      expect(OrderStatusMeta.canCancel(OrderStatus.preparing), isFalse);
    });

    test('delivered cannot be cancelled', () {
      expect(OrderStatusMeta.canCancel(OrderStatus.delivered), isFalse);
    });
  });

  group('OrderStatusBadge widget', () {
    testWidgets('renders label text for pending status', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusBadge(status: OrderStatus.pending)),
      );
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('renders label text for delivered status', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusBadge(status: OrderStatus.delivered)),
      );
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('compact mode renders without error', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusBadge(
          status: OrderStatus.outForDelivery,
          compact: true,
        )),
      );
      expect(find.text('On the Way'), findsOneWidget);
    });

    testWidgets('renders an icon alongside the label', (tester) async {
      await tester.pumpWidget(
        _wrap(const OrderStatusBadge(status: OrderStatus.confirmed)),
      );
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
