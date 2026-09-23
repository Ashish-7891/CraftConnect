import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String productId;
  final String title;
  final String imageUrl;
  final double price;
  final int quantity;
  final String artisanId;
  final String artisanName;

  OrderItemModel({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.artisanId,
    required this.artisanName,
  });

  double get subtotal => price * quantity;

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : 0.0,
      quantity: (map['quantity'] is int) ? map['quantity'] as int : int.tryParse(map['quantity']?.toString() ?? '1') ?? 1,
      artisanId: map['artisanId'] ?? '',
      artisanName: map['artisanName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'price': price,
      'quantity': quantity,
      'artisanId': artisanId,
      'artisanName': artisanName,
    };
  }
}

class OrderModel {
  final String orderId;
  final String customerId;
  final String customerName;
  final List<OrderItemModel> items;
  final List<String> artisanIds;
  final double totalAmount;
  final String address;
  final String phone;
  final String status; // 'PLACED', 'CONFIRMED', 'PREPARING', 'SHIPPED', 'DELIVERED'
  final String paymentMethod;
  final DateTime createdAt;

  OrderModel({
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.items,
    required this.artisanIds,
    required this.totalAmount,
    required this.address,
    required this.phone,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  // Valid forward status transition check
  static const List<String> statusFlow = [
    'PLACED',
    'CONFIRMED',
    'PREPARING',
    'SHIPPED',
    'DELIVERED',
  ];

  static bool canTransition(String current, String next) {
    final curIdx = statusFlow.indexOf(current.toUpperCase());
    final nextIdx = statusFlow.indexOf(next.toUpperCase());
    if (curIdx == -1 || nextIdx == -1) return false;
    return nextIdx > curIdx;
  }

  String? get nextStatus {
    final curIdx = statusFlow.indexOf(status.toUpperCase());
    if (curIdx >= 0 && curIdx < statusFlow.length - 1) {
      return statusFlow[curIdx + 1];
    }
    return null;
  }

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawItems = (data['items'] as List<dynamic>?) ?? [];
    final items = rawItems
        .map((e) => OrderItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawArtisans = (data['artisanIds'] as List<dynamic>?) ?? [];
    final artisanIds = rawArtisans.map((e) => e.toString()).toList();

    return OrderModel(
      orderId: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? 'Customer',
      items: items,
      artisanIds: artisanIds,
      totalAmount: (data['totalAmount'] is num) ? (data['totalAmount'] as num).toDouble() : 0.0,
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      status: (data['status'] ?? 'PLACED').toString().toUpperCase(),
      paymentMethod: data['paymentMethod'] ?? 'Cash on Delivery',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(data['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((e) => e.toMap()).toList(),
      'artisanIds': artisanIds,
      'totalAmount': totalAmount,
      'address': address,
      'phone': phone,
      'status': status,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  OrderModel copyWith({
    String? status,
  }) {
    return OrderModel(
      orderId: orderId,
      customerId: customerId,
      customerName: customerName,
      items: items,
      artisanIds: artisanIds,
      totalAmount: totalAmount,
      address: address,
      phone: phone,
      status: status ?? this.status,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
    );
  }
}
