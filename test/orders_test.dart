import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayfay_merchant_flutter/core/constants/app_strings.dart';
import 'package:bayfay_merchant_flutter/features/orders/model/order_model.dart';
import 'package:bayfay_merchant_flutter/features/orders/view/widgets/cancel_order_dialog.dart';
import 'package:bayfay_merchant_flutter/features/orders/view/widgets/order_card.dart';

void main() {
  group('OrderModel Tests', () {
    test('OrderModel parses legacy Android Order json correctly', () {
      final json = {
        '_id': 'ord_1001',
        'order_id': '#ORD-1001',
        'amount': 450.50,
        'customer': {
          'name': 'Ramesh Kumar',
          'mobile': {'number': 9876543210},
        },
        'address': {
          'post_address': 'Flat 402, Sunshine Apts, Bengaluru',
        },
        'delivery_type': 'Home Delivery',
        'payment_type': 'COD',
        'ordered': '2026-09-08 14:30:00',
        'is_wholesale': false,
        'notes': 'Please deliver before 5 PM',
      };

      final order = OrderModel.fromJson(json, OrderStatus.newOrder);

      expect(order.id, 'ord_1001');
      expect(order.orderId, '#ORD-1001');
      expect(order.amount, 450.50);
      expect(order.customerName, 'Ramesh Kumar');
      expect(order.customerMobile, '9876543210');
      expect(order.customerAddress, 'Flat 402, Sunshine Apts, Bengaluru');
      expect(order.deliveryType, 'Home Delivery');
      expect(order.paymentType, 'COD');
      expect(order.status, OrderStatus.newOrder);
      expect(order.isWholesale, false);
      expect(order.notes, 'Please deliver before 5 PM');
    });

    test('OrderModel gracefully falls back when optional fields are missing', () {
      final json = {
        '_id': 'ord_9999',
        'total_amount': '199',
      };

      final order = OrderModel.fromJson(json);

      expect(order.id, 'ord_9999');
      expect(order.amount, 199.0);
      expect(order.customerName, 'Customer');
      expect(order.customerMobile, '');
      expect(order.deliveryType, 'Home Delivery');
      expect(order.paymentType, 'COD');
      expect(order.status, OrderStatus.newOrder);
    });
  });

  group('OrderCountsModel Tests', () {
    test('OrderCountsModel parses legacy Android order counts correctly', () {
      final json = {
        'newOrders': 12,
        'acceptedOrders': 8,
        'dispatchedOrders': 4,
        'shippingOrders': 6,
        'deliveredOrders': 45,
        'cancelledOrders': 2,
      };

      final counts = OrderCountsModel.fromJson(json);

      expect(counts.newOrders, 12);
      expect(counts.acceptedOrders, 8);
      expect(counts.dispatchedOrders, 4);
      expect(counts.shippingOrders, 6);
      expect(counts.deliveredOrders, 45);
      expect(counts.cancelledOrders, 2);
      expect(counts.totalPending, 30);
    });

    test('OrderCountsModel handles empty/null json gracefully', () {
      final counts = OrderCountsModel.fromJson({});

      expect(counts.newOrders, 0);
      expect(counts.acceptedOrders, 0);
      expect(counts.dispatchedOrders, 0);
      expect(counts.totalPending, 0);
    });
  });

  group('OrderProductItem Tests', () {
    test('OrderProductItem parses line-item json correctly', () {
      final json = {
        '_id': 'item_1',
        'product_name': 'Fresh Organic Milk 1L',
        'qty': 2,
        'net_price': 65.0,
        'unit': '1 L',
        'image': 'https://example.com/milk.png',
        'status': 'active',
      };

      final item = OrderProductItem.fromJson(json);

      expect(item.id, 'item_1');
      expect(item.name, 'Fresh Organic Milk 1L');
      expect(item.quantity, 2);
      expect(item.netPrice, 65.0);
      expect(item.totalPrice, 130.0);
      expect(item.unit, '1 L');
      expect(item.imageUrl, 'https://example.com/milk.png');
    });
  });

  group('OrderStatus Enum Tests', () {
    test('OrderStatus labels match expected strings', () {
      expect(OrderStatus.newOrder.label, 'New');
      expect(OrderStatus.processing.label, 'Processing');
      expect(OrderStatus.ready.label, 'Ready');
      expect(OrderStatus.onTheWay.label, 'On The Way');
      expect(OrderStatus.delivered.label, 'Delivered');
      expect(OrderStatus.cancelled.label, 'Cancelled');
    });
  });

  group('Order Widgets Tests', () {
    testWidgets('OrderCard renders Order details and Accept/Cancel actions for New orders',
        (tester) async {
      const testOrder = OrderModel(
        id: 'ord_123',
        orderId: '#ORD-123',
        amount: 250.0,
        customerName: 'Priya Sharma',
        customerMobile: '9988776655',
        customerAddress: 'MG Road, Indiranagar',
        deliveryType: 'Home Delivery',
        paymentType: 'COD',
        orderedAt: '10 mins ago',
        status: OrderStatus.newOrder,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OrderCard(
                order: testOrder,
                shopId: 'shop_1',
                
              ),
            ),
          ),
        ),
      );

      expect(find.text('#ORD-123'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('9988776655'), findsOneWidget);
      expect(find.text('₹250.00'), findsOneWidget);
      expect(find.text(AppStrings.acceptOrderAction), findsOneWidget);
      expect(find.text(AppStrings.cancelOrderAction), findsOneWidget);
    });

    testWidgets('OrderCard renders Mark Ready action for Processing orders',
        (tester) async {
      const testOrder = OrderModel(
        id: 'ord_456',
        orderId: '#ORD-456',
        amount: 500.0,
        customerName: 'Anil Gupta',
        customerMobile: '9123456780',
        customerAddress: 'Whitefield Main Road',
        deliveryType: 'Store Pickup',
        paymentType: 'Online',
        orderedAt: '1 hour ago',
        status: OrderStatus.processing,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: OrderCard(
                order: testOrder,
                shopId: 'shop_1',
              ),
            ),
          ),
        ),
      );

      expect(find.text('#ORD-456'), findsOneWidget);
      expect(find.text(AppStrings.markReadyAction), findsOneWidget);
      expect(find.text(AppStrings.cancelOrderAction), findsOneWidget);
    });

    testWidgets('CancelOrderDialog displays reasons and allows cancellation',
        (tester) async {
      String? selectedReason;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedReason = await CancelOrderDialog.show(
                    context,
                    orderId: '#ORD-789',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel #ORD-789'), findsOneWidget);
      expect(find.text(AppStrings.cancelReasonOutOfStock), findsOneWidget);
      expect(find.text(AppStrings.cancelReasonStoreBusy), findsOneWidget);

      // Tap Confirm Cancel
      await tester.tap(find.text('Confirm Cancel'));
      await tester.pumpAndSettle();

      expect(selectedReason, AppStrings.cancelReasonOutOfStock);
    });
  });
}
