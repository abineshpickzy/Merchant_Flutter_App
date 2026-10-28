import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayfay_merchant_flutter/features/store/view/tabs/orders/model/order_model.dart';
import 'package:bayfay_merchant_flutter/features/store/view/tabs/orders/repository/orders_repository.dart';
import 'package:bayfay_merchant_flutter/features/store/view/tabs/orders/view/orders_screen.dart';

void main() {
  group('Orders & Invoice Tests', () {
    test('OrderStatus labels and queries match native Android values', () {
      expect(OrderStatus.newOrder.label, 'New Order');
      expect(OrderStatus.processing.label, 'Packaging');
      expect(OrderStatus.ready.label, 'Dispatched');
      expect(OrderStatus.onTheWay.label, 'On the way');
      expect(OrderStatus.delivered.label, 'Delivered');
      expect(OrderStatus.replaceRefund.label, 'Replace/Refund');
      expect(OrderStatus.cancelled.label, 'Cancelled');
    });

    test('InvoiceResult model handles success and failure states', () {
      const success = InvoiceResult(
        isSuccess: true,
        data: '<html>Invoice</html>',
        message: 'Generated',
      );
      expect(success.isSuccess, isTrue);
      expect(success.data, '<html>Invoice</html>');
      expect(success.message, 'Generated');

      const failure = InvoiceResult(
        isSuccess: false,
        message: 'Failed to load invoice',
      );
      expect(failure.isSuccess, isFalse);
      expect(failure.data, isNull);
      expect(failure.message, 'Failed to load invoice');
    });

    test('OrderCountsModel getCountForStatus returns correct values', () {
      const counts = OrderCountsModel(
        newOrders: 5,
        acceptedOrders: 3,
        readyToShipOrders: 2,
        shippingOrders: 4,
        deliveredOrders: 10,
        escalatedOrders: 1,
        cancelledOrders: 0,
      );

      expect(counts.getCountForStatus(OrderStatus.newOrder), 5);
      expect(counts.getCountForStatus(OrderStatus.processing), 3);
      expect(counts.getCountForStatus(OrderStatus.ready), 2);
      expect(counts.getCountForStatus(OrderStatus.onTheWay), 4);
      expect(counts.getCountForStatus(OrderStatus.delivered), 10);
      expect(counts.getCountForStatus(OrderStatus.replaceRefund), 1);
      expect(counts.getCountForStatus(OrderStatus.cancelled), 0);
    });

    testWidgets('MoreSubOrdersScreen renders status title and back button', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MoreSubOrdersScreen(
              status: OrderStatus.delivered,
              shopId: 'shop123',
              categoryId: 'cat456',
            ),
          ),
        ),
      );

      expect(find.text('Delivered'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
