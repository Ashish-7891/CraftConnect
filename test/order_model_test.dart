import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:craftconnect/models/order_model.dart';

void main() {
  group('OrderModel Serialization & Security Rule Field Tests', () {
    test('OrderModel.toFirestore contains all required fields and correct data types', () {
      final orderItem = OrderItemModel(
        productId: 'prod_123',
        title: 'Terracotta Clay Jug',
        imageUrl: 'https://cloudinary.com/jug.jpg',
        price: 450.0,
        quantity: 2,
        artisanId: 'artisan_456',
        artisanName: 'Ramesh Potter',
      );

      final orderDate = DateTime(2026, 9, 23, 10, 30);
      final order = OrderModel(
        orderId: 'order_uuid_789',
        customerId: 'customer_uid_111',
        customerName: 'Aarav Sharma',
        items: [orderItem],
        artisanIds: ['artisan_456'],
        totalAmount: 950.0,
        address: '123 Heritage Lane, Jaipur, Rajasthan - 302001',
        phone: '9876543210',
        status: 'PLACED',
        paymentMethod: 'Cash on Delivery',
        createdAt: orderDate,
      );

      final data = order.toFirestore();

      // Check all required fields matching Firestore security rules
      expect(data['orderId'], 'order_uuid_789');
      expect(data['customerId'], 'customer_uid_111');
      expect(data['customerName'], 'Aarav Sharma');
      expect(data['items'], isA<List>());
      expect((data['items'] as List).length, 1);
      expect(data['artisanIds'], ['artisan_456']);
      expect(data['totalAmount'], 950.0);
      expect(data['address'], '123 Heritage Lane, Jaipur, Rajasthan - 302001');
      expect(data['phone'], '9876543210');
      expect(data['status'], 'PLACED');
      expect(data['paymentMethod'], 'Cash on Delivery');
      expect(data['createdAt'], isA<Timestamp>());

      // Check OrderItem map fields
      final itemMap = (data['items'] as List)[0] as Map<String, dynamic>;
      expect(itemMap['productId'], 'prod_123');
      expect(itemMap['price'], 450.0);
      expect(itemMap['quantity'], 2);
      expect(itemMap['artisanId'], 'artisan_456');
    });

    test('OrderModel status transitions work correctly', () {
      expect(OrderModel.canTransition('PLACED', 'CONFIRMED'), isTrue);
      expect(OrderModel.canTransition('CONFIRMED', 'PREPARING'), isTrue);
      expect(OrderModel.canTransition('PREPARING', 'SHIPPED'), isTrue);
      expect(OrderModel.canTransition('SHIPPED', 'DELIVERED'), isTrue);

      // Disallow backwards or invalid transitions
      expect(OrderModel.canTransition('SHIPPED', 'PLACED'), isFalse);
      expect(OrderModel.canTransition('DELIVERED', 'PREPARING'), isFalse);
    });
  });
}
